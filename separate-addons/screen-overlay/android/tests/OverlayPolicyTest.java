package com.zyn.lightengine.overlay;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/** Plain JVM assertions: no Android runtime or mock permission grant. */
public final class OverlayPolicyTest {
    private static final String TOKEN = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final byte[] PNG = Base64.getDecoder().decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=");
    private static int checks;
    private static void check(boolean value, String message) {
        checks++; if (!value) throw new AssertionError(message);
    }
    private static Map<String, String> fields() {
        Map<String, String> fields = new HashMap<>();
        fields.put("token", TOKEN); fields.put("image", Base64.getUrlEncoder().withoutPadding().encodeToString(PNG));
        fields.put("x", "24"); fields.put("y", "80"); fields.put("width", "128"); fields.put("height", "128");
        fields.put("label", "Original transparent PNG"); return fields;
    }
    private static void reject(String field, String value) {
        Map<String, String> fields = fields();
        if (value == null) fields.remove(field); else fields.put(field, value);
        try { OverlayRequest.parse("show", fields); throw new AssertionError("accepted invalid " + field); }
        catch (IllegalArgumentException expected) { checks++; }
    }
    private static String imageWithBounds(int width, int height) {
        byte[] png = PNG.clone();
        for (int i = 0; i < 4; i++) {
            png[16 + i] = (byte)(width >>> ((3 - i) * 8)); png[20 + i] = (byte)(height >>> ((3 - i) * 8));
        }
        java.util.zip.CRC32 crc = new java.util.zip.CRC32(); crc.update(png, 12, 17);
        for (int i = 0; i < 4; i++) png[29 + i] = (byte)(crc.getValue() >>> ((3 - i) * 8));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(png);
    }
    public static void main(String[] args) {
        OverlayRequest request = OverlayRequest.parse("show", fields());
        check(java.util.Arrays.equals(request.png, PNG), "must preserve original PNG bytes without recompression");
        check(request.imageWidth == 1 && request.imageHeight == 1 && request.width == 128, "PNG bounds and display size");
        reject("token", "abc"); reject("token", TOKEN.substring(1) + "g"); reject("image", null);
        reject("image", fields().get("image") + "="); reject("image", "abcd/+"); reject("image", "a");
        reject("image", Base64.getUrlEncoder().withoutPadding().encodeToString(new byte[256 * 1024 + 1]));
        reject("width", "0"); reject("height", "4097"); reject("x", "2147483648"); reject("y", "-100001");
        reject("label", "bad\nlabel"); reject("unexpected", "field");
        byte[] large = PNG.clone(); large[16] = 0; large[17] = 0; large[18] = 16; large[19] = 1;
        reject("image", Base64.getUrlEncoder().withoutPadding().encodeToString(large));
        reject("image", imageWithBounds(4096, 4096));
        Map<String, String> boundary = fields(); boundary.put("image", imageWithBounds(4000, 4000));
        check(OverlayRequest.parse("show", boundary).imageWidth == 4000, "exact 16 million pixel header is permitted for native decoder validation");
        byte[] fake = PNG.clone(); fake[0] = 0;
        reject("image", Base64.getUrlEncoder().withoutPadding().encodeToString(fake));
        Map<String, String> hidden = new HashMap<>(); hidden.put("token", TOKEN);
        check(OverlayRequest.parse("hide", hidden).hide, "hide needs only matching token");
        hidden.put("image", fields().get("image"));
        try { OverlayRequest.parse("hide", hidden); throw new AssertionError("hide accepted image"); }
        catch (IllegalArgumentException expected) { checks++; }
        OverlaySession session = new OverlaySession();
        long cancelled = session.request(request);
        check(!session.hide(TOKEN.replace('0', 'a')), "wrong token cannot cancel pending consent");
        check(session.hide(TOKEN), "hide must cancel pending image before consent or permission");
        session.consent(cancelled);
        check(!session.canActivate(cancelled, true), "late consent and permission must not revive a hidden request");
        long generation = session.request(request);
        check(!session.canActivate(generation, true), "permission alone never authorizes an image");
        session.consent(generation);
        check(!session.canActivate(generation, false), "consent without actual permission cannot show");
        check(session.canActivate(generation, true), "explicit image consent plus granted permission may show");
        check(session.activate(generation, true), "activation records current token");
        check(!session.hide(TOKEN.replace('0', 'a')), "wrong token must not hide another image");
        check(session.hide(TOKEN), "matching token hides");
        check(!session.canActivate(generation, true), "hide invalidates old work");
        long old = session.request(request); session.consent(old);
        long next = session.request(request);
        check(!session.canActivate(old, true) && !session.canActivate(next, true), "replacement requires new consent and cancels stale work");
        session.consent(next); check(session.activate(next, true), "new consent works");
        session.revoke(); check(!session.hide(TOKEN) && !session.canActivate(next, true), "revocation invalidates overlay and work");
        OverlayGeometry portrait = OverlayGeometry.fit(800, 700, 48, 1080, 1920, 900, 1700);
        check(portrait.width == 800 && portrait.height == 700 && portrait.x == 280 && portrait.y == 1220, "portrait window must remain on screen");
        OverlayGeometry landscape = OverlayGeometry.fit(800, 700, 96, 1920, 600, portrait.x, portrait.y);
        check(landscape.height == 600 && landscape.imageHeight == 600 && landscape.y == 0, "rotation clamps image and close control to new bounds");
        OverlayGeometry tiny = OverlayGeometry.fit(1, 1, 48, 320, 240, -100, 99999);
        check(tiny.width == 48 && tiny.height == 48 && tiny.imageWidth == 1 && tiny.x == 0 && tiny.y == 192, "tiny image retains accessible close control");
        System.out.println("OVERLAY POLICY PASSED: " + checks + " protocol, PNG bounds, byte preservation, consent, denied/granted permission, token, generation and rotation geometry checks");
    }
}
