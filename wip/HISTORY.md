# Published history and original commit recovery

At the start of this continuation, origin/wip/psych-compat was a304cf5893d8897102e6d88af024482eec75af97.

```
a304cf5 wip(docs): refresh native default evidence and build blockers
be22192 Correct native Psych field defaults and log Light menu recovery extensions
6d06ded wip(docs): preserve compatibility rules audits status and cleanup plan
a92469b Record provenance and adaptation notices for Psych reference excerpts
60cb9bc Initialize Psych counters and Lua globals before script execution
5733096 Fix title text and week character asset loading
44241ec Implement Psych Lua input and utility APIs with reference contracts
567588a Support Psych note skins, gameplay counters and mobile pause navigation
```

Checked with git log and git merge-base --is-ancestor: 5733096 and 60cb9bc are ancestors; b3b68ac is not. The original local b3b68ac was recreated as published 44241ec using the GitHub commit API; tree identity is preserved, commit metadata differs. It was incorrect to imply that the original hash was part of the published branch. No published commit was force-pushed or removed during these continuations.

The original b3b68ac remains in the local repository. recovery-original-b3b68ac.bundle preserves that exact commit and its new objects, with 567588a1620a0651eae8822fbddcd17f1d624aa7 as a prerequisite. git bundle verify passed. The bundled commit contains engine code/tests/reference data, not user mods.

After cloning/fetching this repository (including the prerequisite ancestor), recover the original on a separate local branch:

```sh
git bundle verify wip/recovery-original-b3b68ac.bundle
git fetch wip/recovery-original-b3b68ac.bundle refs/heads/recovery/psych-original-input:refs/heads/recovered/psych-original-input
git log -1 recovered/psych-original-input
```

The recovered head is b3b68ac27247dda7d99613960a6f6130aef68225. This does not move main, the WIP branch, or PR #22.
