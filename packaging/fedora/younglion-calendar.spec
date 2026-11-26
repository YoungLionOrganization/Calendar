Name:           younglion-calendar
Version:        0.2.0
Release:        1%{?dist}
Summary:        Personal Qt Quick calendar and event planner
License:        GPL-3.0-only
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  cmake
BuildRequires:  cmake-rpm-macros
BuildRequires:  gcc-c++
BuildRequires:  ninja-build
BuildRequires:  qt6-qtbase-devel >= 6.8
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  libical-devel
Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       qt6-qtsvg

%description
Create events and work offline in year, month, week and agenda views.

%prep
%autosetup

%build
%cmake -G Ninja
%cmake_build

%install
%cmake_install

%check
%ctest

%files
%license COPYING
%doc README.md
%{_bindir}/CalendarApp
%{_datadir}/applications/xyz.younglion.Calendar.desktop
%{_datadir}/metainfo/xyz.younglion.Calendar.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/xyz.younglion.Calendar.svg
