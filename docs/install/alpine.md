# Alpine Linux

Use Alpine 3.23 or a release with Qt 6.8 or newer. Enable the matching `community` repository. The package builds against musl.

```sh
doas apk add alpine-sdk
doas addgroup "$USER" abuild
```

Start a new session after changing groups. Generate a local package signing key with `abuild-keygen -a -i`. As a regular user, put the release tarball next to `packaging/alpine/APKBUILD` and run these commands from that directory.

```sh
abuild checksum
abuild -r
find "$HOME/packages" -name 'younglion-calendar-*.apk'
```

Install the resulting Alpine package with `doas apk add /absolute/path/to/younglion-calendar-0.2.0-r0.apk`. This `.apk` is an Alpine Linux package. For a phone, use the [Android guide](android.md). Remove the Linux package with `doas apk del younglion-calendar`.
