#!/bin/sh
# Pin a package to the newest commit of its branch: updates _commit,
# pkgver (0_git<commit time, UTC>), pkgrel and sha512sums in its APKBUILD.
# Prints the new version, or nothing if the pin is current.
#
# Usage: scripts/update.sh PACKAGE
#
# Needs curl, sha512sum and, for GitHub sources, gh (GitHub API; GH_TOKEN
# in CI). GitLab sources use GitLab's public API without a token.
set -eu

pkg=${1:?usage: scripts/update.sh PACKAGE}
root=$(cd "$(dirname "$0")/.." && pwd)
apkbuild=$root/$pkg/APKBUILD

case $pkg in
android-translation-layer)
	host=github
	repo=nexumia-de/android_translation_layer
	archive=android_translation_layer
	branch=phosh
	;;
art_standalone | bionic_translation)
	host=github
	repo=nexumia-de/$pkg
	archive=$pkg
	branch=phosh
	;;
libopensles-standalone)
	host=gitlab
	repo=android_translation_layer/libopensles-standalone
	archive=$pkg
	branch=known_working_desktop_build
	;;
*)
	echo "no update rule for $pkg" >&2
	exit 1
	;;
esac

old=$(sed -n 's/^_commit="\(.*\)"$/\1/p' "$apkbuild")
case $host in
github)
	new=$(gh api "repos/$repo/commits/$branch" --jq .sha)
	[ "$new" != "$old" ] || exit 0
	date=$(gh api "repos/$repo/commits/$new" --jq .commit.committer.date)
	pkgver=0_git$(echo "$date" | tr -d -- '-:TZ')
	url=https://github.com/$repo/archive/$new.tar.gz
	;;
gitlab)
	api=https://gitlab.com/api/v4/projects/$(echo "$repo" | sed 's,/,%2F,g')
	commit=$(curl -fsSL "$api/repository/commits/$branch")
	new=$(echo "$commit" | grep -o '"id":"[0-9a-f]\{40\}"' | head -n 1 | cut -d'"' -f4)
	[ -n "$new" ] || { echo "no commit for $repo $branch" >&2; exit 1; }
	[ "$new" != "$old" ] || exit 0
	# committed_date carries the committer's offset, like
	# 2026-10-25T15:45:11.000+01:00; busybox date cannot parse offsets.
	date=$(echo "$commit" | grep -o '"committed_date":"[^"]*"' | cut -d'"' -f4)
	stamp=$(echo "$date" | sed 's/^\(....-..-..\)T\(..:..:..\).*/\1 \2/')
	secs=$(date -u -d "$stamp" +%s)
	offset=$(echo "$date" | sed -n 's/.*\([+-]\)\(..\):\(..\)$/\1 \2 \3/p')
	if [ -n "$offset" ]; then
		read -r sign hh mm <<-END
			$offset
		END
		shift_secs=$((${hh#0} * 3600 + ${mm#0} * 60))
		case $sign in
		+) secs=$((secs - shift_secs)) ;;
		-) secs=$((secs + shift_secs)) ;;
		esac
	fi
	pkgver=0_git$(date -u -d "@$secs" +%Y%m%d%H%M%S)
	url=https://gitlab.com/$repo/-/archive/$new/$archive-$new.tar.gz
	;;
esac
file=$archive-$new.tar.gz
sum=$(curl -fsSL "$url" | sha512sum | cut -d' ' -f1)

sed -i -e "s/^_commit=\".*\"$/_commit=\"$new\"/" \
	-e "s/^pkgver=.*/pkgver=$pkgver/" \
	-e "s/^pkgrel=.*/pkgrel=0/" "$apkbuild"
# The checksum line is the only one after sha512sums=" that ends the file.
sed -i -e "/^sha512sums=\"$/,\$d" "$apkbuild"
printf 'sha512sums="\n%s  %s\n"\n' "$sum" "$file" >>"$apkbuild"
echo "$pkgver"
