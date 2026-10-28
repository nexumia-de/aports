# Directory Update Log

## 2026-10-28
* **Creation**: [apk repository](repository.md) with `android-translation-layer` from `nexumia-de/android_translation_layer` (branch `phosh`), published at `https://apk.nexumia.de/edge` with the tag `@nexumia`; daily update check and Dependabot for the Actions.
* **First publish**: `android-translation-layer-0_git20261028094753-r0` is live at `https://apk.nexumia.de/edge`; the signing key moved to the environment `apk-signing` ([apk repository](repository.md)).
* **art_standalone with the wolfssljni fix**: Alpine's `art_standalone` plus a one-line backport from upstream wolfssljni, without which F-Droid crashes in ATL; temporary until Alpine has it. Publishing now downloads the packages already published and builds only new versions (`scripts/fetch-published.sh`), so the long ART build runs once per version ([apk repository](repository.md)).
