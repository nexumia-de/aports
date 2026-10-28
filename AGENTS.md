@../phosh-toolkit/AGENTS.md

# aports

Alpine packages (APKBUILDs) of nexumia-de, built by CI and published as
one signed apk repository on GitHub Pages: `https://apk.nexumia.de/edge`,
added on devices with the tag `@nexumia`. Like Alpine's own aports, the
sources stay in their repositories; each APKBUILD pins an exact commit.
Knowledge of this repository: [docs/index.md](docs/index.md).

## Which shared rules apply

This is a distribution repository like `phosh-apps`, not an app. Of the
shared rules in ../phosh-toolkit/AGENTS.md these do **not** apply: UI,
design, metadata, Flatpak workflow, changelog fragments and
`release.toml`, REUSE compliance (as in `phosh-apps`), and the milestone
layout. Everything else applies:
English, knowledge in `docs/`, pinned dependencies, network rules, pull
requests and CI.

## Rules

- One directory per package with its `APKBUILD`, in Alpine's style.
  Pin `_commit` and `sha512sums`; `scripts/update.sh` moves the pin.
- Never commit the private signing key; it lives in the secret
  `APK_SIGNING_KEY`. The public key in `keys/` must keep the name the
  workflow's `KEY_NAME` uses.
- Before a pull request, build the changed package on the phone with
  `scripts/build.sh` (see [docs/repository.md](docs/repository.md)).
- Do not merge; merging stays with the owner.
