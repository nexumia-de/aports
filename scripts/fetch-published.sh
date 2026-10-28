#!/bin/sh
# Download the packages published at URL into DEST/edge/<arch>/, so
# scripts/build.sh skips every package whose version is already built
# there (art_standalone takes most of an hour) and the new index lists
# them again. Packages whose directory is gone from this repository are
# left out, so removing a directory drops its packages on the next
# publish.
#
# Usage: scripts/fetch-published.sh DEST [URL] [ARCH]
#        (defaults: https://apk.nexumia.de, aarch64)
#
# A missing or unreachable repository is not an error: then everything
# is built.
set -eu

[ $# -ge 1 ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
url=${2:-https://apk.nexumia.de}
arch=${3:-aarch64}
dir=$1/edge/$arch
root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$dir"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if ! curl -sSfL -m 60 -o "$tmp/APKINDEX.tar.gz" "$url/edge/$arch/APKINDEX.tar.gz"; then
	echo "No published repository at $url, building everything"
	exit 0
fi
tar -xzf "$tmp/APKINDEX.tar.gz" -C "$tmp" APKINDEX

# APKINDEX: one block per package, "P:" name, "V:" version, "o:" origin
# (the directory of its APKBUILD), blocks separated by empty lines.
awk -F: '
	/^P:/ { p = substr($0, 3) }
	/^V:/ { v = substr($0, 3) }
	/^o:/ { o = substr($0, 3) }
	/^$/ { if (p != "") print o, p "-" v ".apk"; p = v = o = "" }
	END { if (p != "") print o, p "-" v ".apk" }
' "$tmp/APKINDEX" | while read -r origin file; do
	if [ ! -f "$root/$origin/APKBUILD" ]; then
		echo "Skipping $file: $origin is no longer in this repository"
		continue
	fi
	echo "Fetching $file"
	curl -sSfL -m 600 -o "$dir/$file" "$url/edge/$arch/$file"
done
