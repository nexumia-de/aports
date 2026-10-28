#!/bin/sh
# Pin a package to the newest commit of its branch: updates _commit,
# pkgver (0_git<commit time, UTC>), pkgrel and sha512sums in its APKBUILD.
# Prints the new version, or nothing if the pin is current.
#
# Usage: scripts/update.sh PACKAGE
#
# Needs curl, sha512sum and gh (GitHub API; GH_TOKEN in CI).
set -eu

pkg=${1:?usage: scripts/update.sh PACKAGE}
root=$(cd "$(dirname "$0")/.." && pwd)
apkbuild=$root/$pkg/APKBUILD

case $pkg in
android-translation-layer)
	repo=nexumia-de/android_translation_layer
	branch=phosh
	archive=android_translation_layer
	;;
*)
	echo "no update rule for $pkg" >&2
	exit 1
	;;
esac

old=$(sed -n 's/^_commit="\(.*\)"$/\1/p' "$apkbuild")
new=$(gh api "repos/$repo/commits/$branch" --jq .sha)
[ "$new" != "$old" ] || exit 0

date=$(gh api "repos/$repo/commits/$new" --jq .commit.committer.date)
pkgver=0_git$(echo "$date" | tr -d -- '-:TZ')
file=$archive-$new.tar.gz
sum=$(curl -fsSL "https://github.com/$repo/archive/$new.tar.gz" | sha512sum | cut -d' ' -f1)

sed -i -e "s/^_commit=\".*\"$/_commit=\"$new\"/" \
	-e "s/^pkgver=.*/pkgver=$pkgver/" \
	-e "s/^pkgrel=.*/pkgrel=0/" "$apkbuild"
# The checksum line is the only one after sha512sums=" that ends the file.
sed -i -e "/^sha512sums=\"$/,\$d" "$apkbuild"
printf 'sha512sums="\n%s  %s\n"\n' "$sum" "$file" >>"$apkbuild"
echo "$pkgver"
