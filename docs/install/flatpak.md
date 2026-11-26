# Flatpak

Install Flatpak and Flatpak Builder with your distribution's package manager. From an extracted Calendar source tree, install the KDE runtime and SDK and build the checked-in manifest.

```sh
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.kde.Platform//6.10 org.kde.Sdk//6.10
flatpak-builder --user --install --force-clean build-flatpak packaging/flatpak/xyz.younglion.Calendar.yml
flatpak run xyz.younglion.Calendar
```

`--force-clean` replaces the specified build directory on repeat builds. The manifest builds libical from a checksum-pinned source archive. Notification and background permission prompts depend on the host desktop portal. Remove the application with `flatpak uninstall --user xyz.younglion.Calendar`.
