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
scripts/build.sh DEST       abuild for every package into DEST/edge/<arch>/ (also on the phone)
scripts/ci-build.sh         root in alpine:edge: edge/testing, apk upgrade, alpine-sdk, key, build.sh -F -r
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
- The site holds only the newest build; apk keeps installed versions,
  but the repository has no older ones to downgrade to.
- The repository name is `edge` (the Alpine branch the packages are
  for), the tag on devices `@nexumia`.

# Packages

| Package | Source | Notes |
|---|---|---|
| `android-translation-layer` | `nexumia-de/android_translation_layer`, branch `phosh`, as GitHub archive of the pinned commit | Follows Alpine's APKBUILD and upstream's nightly one: JDK 17, maven and `-Ddownload_tool_deps=true` (`options="net"`) for `tools/jni_upcall_gen`; `gtk4-layer-shell-dev` for the on-screen keyboard. Dependencies `art_standalone`, `bionic_translation`, `libopensles-standalone` from Alpine testing. Version `0_git<commit time, UTC>`. |

# Building on the phone

With the makedepends installed (as `claude`, `-d` skips the check of the
runtime dependency `libopensles-standalone`):

```sh
scripts/build.sh /tmp/apkrepo -d
```

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

Still to do:

1. In `apk-signing`: the owner as required reviewer, and "Allow
   administrators to bypass configured protection rules" off (the
   agent's token acts as the owner's admin account). Not confirmed on
   2026-10-28.
2. Merge pull request #1; the first publish then waits for the
   reviewer's approval under Actions.
3. "Enforce HTTPS" in the Pages settings once the certificate exists.
4. Optional: secret `UPDATE_TOKEN` (see `update-check.yml`) so CI builds
   the update pull requests; otherwise the setting "Allow GitHub Actions
   to create and approve pull requests" must be on.
5. On the device, as root (the owner runs root commands with `sudo`):
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
