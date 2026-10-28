#!/bin/sh
# Build every package of this repository (*/APKBUILD) into the apk
# repository DEST/edge/<arch>/, signed with abuild's key
# (PACKAGER_PRIVKEY or abuild.conf).
#
# Usage: scripts/build.sh DEST [abuild options]
#
# In CI: scripts/ci-build.sh runs it as root with "-F -r". On a device
# with the makedepends installed, without arguments; "-d" skips the
# dependency check. The index step needs the public key in
# /etc/apk/keys.
set -eu

[ $# -ge 1 ] || { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
mkdir -p "$1"
dest=$(cd "$1" && pwd)
shift
root=$(cd "$(dirname "$0")/.." && pwd)

# abuild names the repository after the directory above the APKBUILD and
# writes src/ and pkg/ next to it, so build from a copy.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/edge"
for apkbuild in "$root"/*/APKBUILD; do
	pkg=$(basename "$(dirname "$apkbuild")")
	cp -r "$root/$pkg" "$work/edge/"
	(cd "$work/edge/$pkg" && REPODEST=$dest SRCDEST=$work/distfiles abuild "$@")
done
echo "Repository: $dest/edge"
