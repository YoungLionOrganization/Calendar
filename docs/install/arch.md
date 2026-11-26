# Arch Linux

Download the `x86_64.pkg.tar.zst` asset for your version from [GitHub Releases](https://github.com/YoungLionOrganization/Calendar/releases/latest). From the download directory, install the package.

```sh
sudo pacman -U ./younglion-calendar-0.2.0-1-x86_64.pkg.tar.zst
```

Open **YoungLion Calendar** from the application menu or run `CalendarApp`. Use the actual package filename when installing a newer release. Remove the package with `sudo pacman -R younglion-calendar`.

To build a package yourself, put the versioned source tarball beside `packaging/arch/PKGBUILD` and run `makepkg -si` from that directory as a regular user. Install the `base-devel` group first.
