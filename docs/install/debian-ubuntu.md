# Debian and Ubuntu

Use Debian 13, Ubuntu 26.04, or another release with Qt 6.8 or newer. From a checkout of this repository, download the matching versioned source tarball and use the current package recipe.

```sh
sudo apt update
sudo apt install build-essential debhelper cmake ninja-build qt6-base-dev qt6-declarative-dev libical-dev libqt6sql6-sqlite
tar -xf younglion-calendar-0.2.0.tar.gz
cp -a packaging/deb/debian younglion-calendar-0.2.0/
cd younglion-calendar-0.2.0
dpkg-buildpackage -us -uc -b
sudo apt install ../younglion-calendar_*.deb
```

Run the commands in a directory containing only the matching Calendar source and package files. APT installs the runtime QML modules and Qt SQLite plugin declared by the package. Open **YoungLion Calendar** from the application menu. Remove it with `sudo apt remove younglion-calendar`.
