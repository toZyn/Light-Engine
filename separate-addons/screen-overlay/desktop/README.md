# PNG overlay companion for Windows and Linux X11

This separate companion displays the addon’s original PNG above normal desktop
applications. It is a native frameless, transparent Qt window with a draggable
image and close **×**. It requests always-on-top placement and does not take
keyboard focus. The image’s alpha remains intact; transparent areas show the
desktop or applications underneath. The companion never reads the wallpaper.

Install this folder outside the engine and keep it at a stable path. It requires
Python 3.10 or newer and the pinned PySide6 runtime:

```sh
python3 -m pip install -r requirements.txt
```

On Windows use `py -3 -m pip install -r requirements.txt`. The Python interpreter
used for installation must have PySide6 installed. Linux also needs an X11
desktop, the Qt XCB runtime libraries (including `libxcb-cursor0`), and
`xdg-mime` for protocol registration. A virtual environment can be used; run
the Python commands with that environment’s interpreter.

## Register and start

Protocol registration is an explicit per-user operation. Importing or starting
the companion does not register a handler, install dependencies, or grant a
pairing token.

```sh
python3 install_protocol.py --install
python3 companion.py
```

Windows: run `install-windows.cmd` or `py -3 install_protocol.py --install`, then
`launch-windows.cmd`. Linux: `./install-linux.sh` and `./launch-linux.sh` use
`python3` from your active environment. The installer uses HKCU on Windows or
an XDG desktop entry on Linux; it does not require administrator access.

After registration, the addon opens a pairing URI such as
`lightengine-overlay://connect?token=<64-hex-token>&label=<urlencoded-name>`.
Only the connect action and bounded token/label fields are accepted. The
companion asks whether that named addon may show an image. **No** is the default.
Labels are descriptive, not verified publisher identities; the dialog also
shows the pairing fingerprint. No image is accepted before **Yes**.

A second URI invocation forwards its bounded pairing request to the running
local companion. One consent dialog may be pending, with requests rate limited
to prevent a prompt flood. Up to eight tokens may be granted for the current
companion session. Closing the companion revokes all grants.
Denied or explicitly stopped tokens are remembered in a bounded 32-entry
history. Polling such a token does not reopen consent; start a fresh addon
pairing with a new token instead.

Use the tray’s **Stop overlay** or the image’s **×** to hide the image and revoke
pairing. The addon must obtain fresh consent before redisplaying it. If the
desktop has no tray host, a small control window remains available with Stop
and Quit buttons; its close action stops the overlay while keeping those
controls reachable. An authenticated normal hide request releases the displayed
image while keeping that token’s grant for later use.
An addon session’s close request releases its token as well as its own image;
it also cancels a consent dialog still waiting for that session. Repeated
closed sessions therefore do not occupy the eight live pairing slots.

To remove this installation’s handler:

```sh
python3 install_protocol.py --uninstall
```

Linux removes its owned desktop entry; desktop MIME caches may retain a stale
association until refreshed. Windows removes the HKCU scheme only if this
companion still owns its command. No other desktop entry or handler is removed.
After moving the folder or Python environment, explicitly reinstall the handler.

## Local transport

The companion binds only `127.0.0.1:51874`. There is one network worker, a
three-second absolute input deadline, a 16 KiB header limit, and a small connection
backlog. Browser-origin requests are rejected. It never accepts file paths or
remote image URLs.

- `POST /connect`: JSON `{ "token": "<64hex>", "label": "name" }`, at most
  1 KiB. This unauthenticated endpoint queues a consent prompt, not a grant.
- `POST /image`: `Authorization: Bearer <64hex>` and the original raw PNG body.
  Optional integer query fields are `x`, `y`, `width`, and `height`.
- `DELETE /image`: the same authorization, no query fields; queues hiding and
  releases the image.
- `DELETE /connect`: Bearer token matching a pending or granted session,
  no query fields; revokes that session, cancels its pending consent dialog,
  and hides its image if it owns the overlay. It leaves another session’s
  image untouched. Unknown tokens are rejected. Addon `close()` uses this
  endpoint; normal `hide()` uses `/image`.

PNG bodies are limited to 8 MiB, 4096 pixels on each axis, and 16 million
pixels total. Header fields, chunk bounds/checksums, and bounded scanline
decompression are validated before Qt decoding. Qt remains the final decoder.
Requests must include `Content-Length`; chunked transfer is rejected.
The original bytes, including PNG metadata, remain unchanged in memory. No
re-encoding, file copy, cache, or image upload is performed. The decoded image
is drawn from a QPixmap; the original SHA-256 is retained for verification.

Geometry uses Qt desktop coordinates, including negative monitor origins;
HiDPI displays use Qt’s device-independent logical units.
The image fits the requested width/height uniformly while preserving its
aspect ratio, then fits the selected monitor’s available bounds. Position is
clamped so the close control remains reachable. Tiny images retain their
original size inside a minimum 24-pixel transparent control window. Width and
height describe the image’s bounding box, not a request to stretch its pixels.
Dragging allows movement onto another monitor and fits the drawn image/control
window to smaller target bounds without changing the original QPixmap or PNG
bytes. Physical dragging across multiple monitors remains a platform test.

Success responses are **202 accepted/queued**, with `accepted: true` and
`displayed: false`. A network acknowledgment does not prove compositor
visibility. Invalid or unconsented requests fail; `403` includes `pending:true`
only while that exact token awaits consent. Clients may retry that state with
a bounded timeout, but must stop on denial. Clients should poll `/connect` before uploading the first image:
`granted:true` permits uploading, `pending:true` permits bounded waiting, and
`denied:true` must stop the request. This also avoids URI-handler startup races.
One image update may be queued at a time; a second update returns `429`. A different granted token cannot replace
another token’s owned overlay. Cancel/hide/Stop generations prevent queued work
from showing after a session has ended.

## Platform limits and verification

Supported targets are Windows and Linux X11. Wayland sessions are explicitly
rejected because a cross-application topmost window cannot be guaranteed there.
Offscreen Qt backends and macOS are unsupported. Desktop compositor policies
can still restrict topmost placement; this tool does not bypass OS restrictions.

Run the independent tests from this folder:

```sh
python3 -m unittest discover -s tests -p 'test_[pi]*.py' -v
xvfb-run -a python3 -m unittest discover -s tests -p test_gui.py -v
```

The native GUI fixture uses the real Qt XCB backend, actual consent dialogs,
transparent/nonfocusable window flags, original alpha and pixels, geometry,
another native window, and real HTTP-to-GUI image/hide requests. Policy tests
cover denial, authentication, body/geometry limits, malformed compression,
queue cancellation, and original-byte identity. Tests also cover
session release beyond eight cycles, canceled pending consent, strict filter
validation, absolute slow-input deadlines, and nonblocking GUI shutdown.
Synthetic smaller target bounds around a real QWidget exercise drag fitting;
this does not establish physical monitor migration. Installer tests cover explicit
owned-file changes and command quoting. Automated dialog answers are test-only;
the companion always asks the desktop user. Windows native execution, physical
multi-monitor dragging, and compositor placement are not established by the
Linux Xvfb tests.
