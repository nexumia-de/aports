#!/bin/sh
# Build every package of this repository (*/APKBUILD) into the apk
# repository DEST/edge/<arch>/, signed with abuild's key
# (PACKAGER_PRIVKEY or abuild.conf).
#
# Usage: scripts/build.sh DEST [abuild options]
#
# A package whose <pkgname>-<pkgver>-r<pkgrel>.apk is already in DEST is
# skipped (scripts/fetch-published.sh puts the published ones there), so
# a changed APKBUILD needs a new pkgver or pkgrel. In CI:
# scripts/ci-build.sh runs it as root with "-F -r". On a device with the
# makedepends installed, without arguments; "-d" skips the dependency
# check. The index step needs the public key in /etc/apk/keys.
set -eu

[ $# -ge 1 ] || { sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
mkdir -p "$1"
dest=$(cd "$1" && pwd)
shift
root=$(cd "$(dirname "$0")/.." && pwd)
arch=$(apk --print-arch)

# abuild names the repository after the directory above the APKBUILD and
# writes src/ and pkg/ next to it, so build from a copy.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/edge"
# Dependencies first, so a package builds against the ones built here:
# art_standalone needs bionic_translation, android-translation-layer both.
first="bionic_translation art_standalone"
rest=$(cd "$root" && ls -d */APKBUILD | sed 's,/APKBUILD$,,' | grep -vxF -e bionic_translation -e art_standalone)
for pkg in $first $rest; do
	apkbuild=$root/$pkg/APKBUILD
	[ -f "$apkbuild" ] || continue
	# APKBUILDs use variables abuild sets, like $srcdir
	apk=$(set +u && . "$apkbuild" && echo "$pkgname-$pkgver-r$pkgrel.apk")
	if [ -f "$dest/edge/$arch/$apk" ]; then
		echo "$pkg: $apk is already built, skipping"
		continue
	fi
	cp -r "$root/$pkg" "$work/edge/"
	(cd "$work/edge/$pkg" && REPODEST=$dest SRCDEST=$work/distfiles abuild "$@")
done

# abuild indexes only after building a package; index here as well, so
# the index is current when everything was skipped or a package was
# dropped.
cd "$dest/edge/$arch"
apk index --no-warnings --quiet --output APKINDEX.tar.gz.new \
	--description edge --rewrite-arch "$arch" ./*.apk
abuild-sign -q APKINDEX.tar.gz.new
chmod 644 APKINDEX.tar.gz.new
mv APKINDEX.tar.gz.new APKINDEX.tar.gz
echo "Repository: $dest/edge"
