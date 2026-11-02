# aports

Alpine packages of [nexumia-de](https://github.com/nexumia-de), built by
GitHub Actions and published as a signed apk repository at
<https://apk.nexumia.de/>.

| Package | Source |
|---|---|
| `android-translation-layer` | [nexumia-de/android_translation_layer](https://github.com/nexumia-de/android_translation_layer), branch `phosh`: Android Translation Layer with the fixes for Phosh |
| `art_standalone` | [nexumia-de/art_standalone](https://github.com/nexumia-de/art_standalone), branch `phosh`: upstream plus two wolfssljni fixes that F-Droid needs in ATL and a fix for lambdas in the Java core library (`java.time`) ([details](docs/repository.md#packages)) |
| `bionic_translation` | [nexumia-de/bionic_translation](https://github.com/nexumia-de/bionic_translation), branch `phosh`: upstream plus two functions that current NDK libraries need (React Native, DB Navigator) ([details](docs/repository.md#packages)) |
| `libopensles-standalone` | [android_translation_layer/libopensles-standalone](https://gitlab.com/android_translation_layer/libopensles-standalone) on GitLab, branch `known_working_desktop_build`: upstream as is, newer than Alpine's package |

## Use

On Alpine or postmarketOS edge (aarch64), as root, once:

```sh
wget -O /etc/apk/keys/nexumia-de-20261028.rsa.pub https://apk.nexumia.de/keys/nexumia-de-20261028.rsa.pub
echo "@nexumia https://apk.nexumia.de/edge" >> /etc/apk/repositories
apk add android-translation-layer@nexumia
```

Updates come with `apk upgrade`. The tag `@nexumia` means apk takes a
package from this repository only when it is requested with `@nexumia`,
so it does not replace any other package of the distribution. A device
that already has Alpine's `libopensles-standalone` switches once with
`apk add libopensles-standalone@nexumia`.

How it works: [docs/repository.md](docs/repository.md).
