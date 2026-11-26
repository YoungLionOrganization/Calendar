# Fedora

Use Fedora 44 or another release with Qt 6.8 or newer. From a checkout of this repository, download the matching source tarball from GitHub Releases and build the RPM with the current spec.

```sh
sudo dnf install rpm-build cmake cmake-rpm-macros gcc-c++ ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel libical-devel
mkdir -p "$HOME/rpmbuild/SOURCES"
cp younglion-calendar-0.2.0.tar.gz "$HOME/rpmbuild/SOURCES/"
rpmbuild -bb packaging/fedora/younglion-calendar.spec
sudo dnf install "$HOME"/rpmbuild/RPMS/"$(uname -m)"/younglion-calendar-0.2.0-1.*.rpm
```

Fedora supplies the SQLite plugin in `qt6-qtbase`. Open **YoungLion Calendar** from the application menu or run `CalendarApp`. Remove the package with `sudo dnf remove younglion-calendar`.
