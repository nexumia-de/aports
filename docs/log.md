# Directory Update Log

## 2026-10-28
* **Creation**: [apk repository](repository.md) with `android-translation-layer` from `nexumia-de/android_translation_layer` (branch `phosh`), published at `https://apk.nexumia.de/edge` with the tag `@nexumia`; daily update check and Dependabot for the Actions.
* **First publish**: `android-translation-layer-0_git20261028094753-r0` is live at `https://apk.nexumia.de/edge`; the signing key moved to the environment `apk-signing` ([apk repository](repository.md)).
* **Fixes for DB Navigator**: `art_standalone` gets `lambda-metafactory.patch` (lambdas inside the Java core library, e.g. `java.time`), and `bionic_translation` is added with `__register_atfork` and `__strncat_chk` (React Native, Akamai). Both temporary until Alpine has them ([apk repository](repository.md)).
* **art_standalone with the wolfssljni fix**: Alpine's `art_standalone` plus a one-line backport from upstream wolfssljni, without which F-Droid crashes in ATL; temporary until Alpine has it. Publishing now downloads the packages already published and builds only new versions (`scripts/fetch-published.sh`), so the long ART build runs once per version ([apk repository](repository.md)).
* **art_standalone r102**: `wolfssljni-session-store-lock.patch` guards wolfssljni's session store with a lock; F-Droid crashed with `ConcurrentModificationException` in `WolfSSLAuthStore.updateTimeouts` while downloading over several connections ([repository](repository.md#packages)).

## 2026-10-29
* **ATL with libadwaita**: `android-translation-layer` builds with `libadwaita-dev`, needed from nexumia-de/android_translation_layer pull request #20 on (the page that asks before installing an opened APK).
* **Forks instead of patches**: `art_standalone` and `bionic_translation` are built from the forks `nexumia-de/art_standalone` and `nexumia-de/bionic_translation` (branch `phosh`, the former patches as commits), pinned and updated by `scripts/update.sh` and the daily update check like `android-translation-layer`; no more `pkgrel=10x`. Each fork mirrors upstream daily and opens a pull request into `phosh`. `scripts/build.sh` builds dependencies first ([apk repository](repository.md#from-a-fix-to-the-phone)).
