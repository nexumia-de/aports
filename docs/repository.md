---
type: Playbook
title: apk repository
description: How the packages are built, signed and published at apk.nexumia.de, kept current, set up once by the owner, and who can publish.
resource: ../.github/workflows/publish.yml
tags: [alpine, apk, packaging, ci, pages, signing]
generated: { by: claude-code/2.1.308, at: 2026-10-28T12:40:00Z }
sources:
  - id: apk-tags
    resource: https://wiki.alpinelinux.org/wiki/Alpine_Package_Keeper
    title: Alpine wiki, Alpine Package Keeper (repository tags)
  - id: pages-domain
    resource: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
    title: GitHub Docs, custom domain for a GitHub Pages site
  - id: environments
    resource: https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment
    title: GitHub Docs, environments (secrets, deployment branches, required reviewers)
---

# Why

The owner's phone needs packages that the distribution does not ship,
first `android-translation-layer` built from the fork's `phosh` branch
(Alpine's package is upstream without the fork's fixes). One central,
signed apk repository serves them, like
[phosh-apps](../../phosh-toolkit/docs/app-repository.md) serves the
Flatpak apps. It needs its own repository and domain because one Pages
site has one custom domain, and `flatpak.nexumia.de` is already the
Flatpak remote's address.

# Pieces

```
<package>/APKBUILD          pinned _commit + sha512sums (Alpine style)
scripts/update.sh           moves the pin to the newest commit of the source branch
scripts/build.sh DEST       abuild for every package not yet in DEST/edge/<arch>/, then index (also on the phone)
scripts/fetch-published.sh DEST  the packages published now into DEST/edge/<arch>/, so they are not rebuilt
scripts/ci-build.sh         root in alpine:edge: edge/testing, apk upgrade, alpine-sdk, keys, build.sh -F -r
keys/<name>.rsa.pub         public signing key

publish.yml       pull request: build with a throwaway key, publish nothing
                  push to main: build in environment apk-signing, sign,
                  site = edge/aarch64/{APKINDEX.tar.gz,*.apk} + keys/ + index.html,
                  deploy to Pages → https://apk.nexumia.de/
update-check.yml  daily 03:41 UTC: scripts/update.sh per package, one pull request each
dependabot.yml    weekly: GitHub Actions SHAs
```

- Packages are built for aarch64 on `ubuntu-24.04-arm` in `alpine:edge`
  (pinned by digest, then `apk upgrade`d so packages link against
  current edge, like the devices).
- Only packages whose `<pkgname>-<pkgver>-r<pkgrel>.apk` is not yet
  published are built; the others are downloaded from the site and
  indexed again. A changed APKBUILD therefore needs a new `pkgver` or
  `pkgrel`, like in Alpine. A removed package directory drops its
  packages on the next publish. The first build of `art_standalone`
  takes most of an hour (job timeout 180 minutes); after that a publish
  rebuilds only what changed.
- The site holds only the newest build; apk keeps installed versions,
  but the repository has no older ones to downgrade to.
- The repository name is `edge` (the Alpine branch the packages are
  for), the tag on devices `@nexumia`.

# Packages

| Package | Source | Notes |
|---|---|---|
| `android-translation-layer` | `nexumia-de/android_translation_layer`, branch `phosh`, as GitHub archive of the pinned commit | Follows Alpine's APKBUILD and upstream's nightly one: JDK 17, maven and `-Ddownload_tool_deps=true` (`options="net"`) for `tools/jni_upcall_gen`; `gtk4-layer-shell-dev` for the on-screen keyboard. Dependencies `art_standalone`, `bionic_translation`, `libopensles-standalone` from Alpine testing. Version `0_git<commit time, UTC>`. |
| `art_standalone` (with `libandroidfw`, `adbd`, `-dev`) | Alpine's `testing/art_standalone` (alpinelinux/aports `f35539597b0e`), same source commit | Plus `wolfssljni-freed-session-timeout.patch`: art_standalone's vendored wolfssljni throws `IllegalStateException: Object has been freed` when the TLS session timeout is set after a connection closed, which crashes F-Droid; upstream wolfssljni already catches it. Plus `wolfssljni-session-store-lock.patch`: its session store (a `LinkedHashMap`) is used by connections on several threads without a lock, so setting the timeout threw `ConcurrentModificationException` and crashed F-Droid while downloading; upstream wolfssljni guards it with `storeLock`. Plus `lambda-metafactory.patch`: libcore is compiled with dx, which keeps the `invokedynamic` of libcore's own lambdas, but `LambdaMetafactory` is Android's stub that returns null, so e.g. `java.time.format.DateTimeFormatter` failed in its static initializer (DB Navigator); the patch implements the metafactory with `java.lang.reflect.Proxy` and lets ART pass mixed static arguments to `altMetafactory(..., Object...)`. `pkgrel=100` (101 since the lambda patch, 102 since the store lock) keeps it above Alpine rebuilds of the same version; no `-dbg`. Not updated by `update-check.yml`. **Temporary**: once Alpine's package has the fixes, delete the directory and switch devices back with `apk add art_standalone libandroidfw adbd` (without the tag). |
| `bionic_translation` (with `-dev`, `-dbg`) | Alpine's `testing/bionic_translation` (alpinelinux/aports `f35539597b0e`), same source commit | Plus `register-atfork-strncat-chk.patch`: `__register_atfork` (what the NDK's `pthread_atfork` calls) and `__strncat_chk`, without which Hermes (React Native) and Akamai's library fail to load. `pkgrel=100`; aarch64 only. Not updated by `update-check.yml`. **Temporary** like `art_standalone`; switch back with `apk add bionic_translation` (without the tag). |

# Building on the phone

With the makedepends installed (as `claude`, `-d` skips the check of the
runtime dependency `libopensles-standalone`):

```sh
scripts/fetch-published.sh /tmp/apkrepo   # optional: only build what is not published
scripts/build.sh /tmp/apkrepo -d
```

`build.sh` builds in `mktemp -d`. On the phone `/tmp` is a 3.6 GB RAM
disk, which `art_standalone` fills while packaging ("No space left on
device" after about an hour); build it with
`TMPDIR=$HOME/build-tmp` (on the disk) instead.

The package lands in `/tmp/apkrepo/edge/aarch64/`. The final index step
fails unless the signing key's public part is in `/etc/apk/keys`
("UNTRUSTED signature"); the package itself is complete.

# One-time setup by the owner

Done on 2026-10-28: repository `nexumia-de/aports`, DNS `CNAME`
`apk.nexumia.de` → `nexumia-de.github.io`, Pages source "GitHub Actions"
with custom domain `apk.nexumia.de`[^pages-domain], key pair
`nexumia-de-20261028.rsa` (RSA 4096, created by the owner; public part in
`keys/`), and the environment `apk-signing` with deployment branch
`main` and the environment secret `APK_SIGNING_KEY`[^environments].
Pull request #1 was merged and published the first package; the
published `edge/aarch64/APKINDEX.tar.gz` verifies with the public key
(`apk --keys-dir <dir> verify`) and is untrusted without it.

Still to do:

1. In `apk-signing`: the owner as required reviewer, and "Allow
   administrators to bypass configured protection rules" off (the
   agent's token acts as the owner's admin account). Not confirmed on
   2026-10-28.
2. "Enforce HTTPS" in the Pages settings once the certificate exists.
3. Optional: secret `UPDATE_TOKEN` (see `update-check.yml`) so CI builds
   the update pull requests; otherwise the setting "Allow GitHub Actions
   to create and approve pull requests" must be on.
4. On the device, as root (the owner runs root commands with `sudo`):
   ```sh
   wget -O /etc/apk/keys/nexumia-de-20261028.rsa.pub https://apk.nexumia.de/keys/nexumia-de-20261028.rsa.pub
   echo "@nexumia https://apk.nexumia.de/edge" >> /etc/apk/repositories
   apk add android-translation-layer@nexumia
   ```
   apk takes packages from a tagged repository only when they are
   requested with the tag, and keeps them there on `apk upgrade`, even if
   the distribution has a newer version.[^apk-tags]

# Trust

Installing a package runs its install scripts as root, so whoever can
publish here can run code as root on the devices. The agent works with a
token of the owner's own GitHub account: on GitHub it acts as the owner,
so "only the owner merges" is a rule, not a barrier. The barriers are:

- The token has no access to secrets or Pages settings (`403`, checked
  2026-10-28), so the agent can neither read nor set the key.
- With the environment `apk-signing` (deployment branch `main`, required
  reviewer), only jobs on `main` see the key, and each publish waits for
  the owner's approval in GitHub. Without it, any workflow run on a push
  can read a repository secret, including one the agent could write
  with workflow permission.
- Every published package comes from a commit in `main` and a public CI
  run; the index page links the commit.

Rotation: new key pair with a new date, new secret, new file in `keys/`,
`KEY_NAME` in `publish.yml`, and the new public key on every device.
