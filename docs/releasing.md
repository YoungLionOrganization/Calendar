# Release procedure

Calendar separates artifact builds from publication. Both workflows run manually from `main`.

1. Update the version in root `CMakeLists.txt`, `Calendar/Constants.qml`, and the native packaging recipes. Update the AppStream release entry and increment the Android version code for an Android release. Add English release notes at `docs/releases/vX.Y.Z.md`.
2. Push the candidate commit to `main` and wait for **Linux build and smoke tests** to pass on that commit.
3. Run **Build Release Artifacts** from `main`. It produces the source tarball and Arch x86_64 package. Select the Android option to include a signed arm64 APK.
4. Copy the successful artifact run's numeric ID from its GitHub Actions URL. Run **Publish Release** with that ID in `validate` mode. It checks the commit, Linux CI, source archive, and expected downloads without publishing.
5. When ready, run **Publish Release** with the same ID in `publish` mode. It uploads a draft, attaches the packages and SHA-256 checksums, then publishes the release. A new commit on `main` requires a new artifact build. An existing tag blocks publication.

The Android build option requires `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, and `ANDROID_KEY_PASSWORD` in GitHub Actions secrets. Use a persistent signing key to support future in-place upgrades. The source and Arch build require no signing secrets.

If asset upload fails after creating a draft, check the draft and run logs before retrying. Keep the versioned release notes accurate about distributions, architectures, and tests that are included.
