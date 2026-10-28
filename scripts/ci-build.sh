#!/bin/sh
# Run as root in an alpine:edge container by .github/workflows/publish.yml,
# with this checkout at /src: build all packages into /out, signed with
# /keys/<name>.rsa. Without a key (pull requests) a throwaway key is
# generated, so the build is still tested.
set -eu

echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >>/etc/apk/repositories
# Build against current edge, like the devices, not the image's snapshot.
apk upgrade --update-cache --no-cache
apk add --no-cache alpine-sdk

export PACKAGER="GitHub Actions <41898282+github-actions[bot]@users.noreply.github.com>"
if ls /keys/*.rsa >/dev/null 2>&1; then
	PACKAGER_PRIVKEY=$(ls /keys/*.rsa)
else
	# abuild-keygen -i would call doas, which the container lacks.
	abuild-keygen -n -a
	. "$HOME/.config/abuild/abuild.conf"
fi
export PACKAGER_PRIVKEY
cp "$PACKAGER_PRIVKEY.pub" /etc/apk/keys/
# The packages fetched by fetch-published.sh are signed with the real key.
cp /src/keys/*.pub /etc/apk/keys/

/src/scripts/build.sh /out -F -r
