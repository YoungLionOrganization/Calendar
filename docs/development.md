# Building and testing

## Linux source build

Install Qt 6.8 or newer with Qt Quick, Qt Quick Controls, Qt SQL with the SQLite plugin, and Qt D-Bus. Install the distribution's libical development package, a C++ compiler, CMake, and Ninja. A system Qt installation can use `cmake` in place of the Qt SDK's `qt-cmake`.

```sh
qt-cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
ctest --test-dir build --output-on-failure
./build/CalendarApp
cmake --install build
```

The installation places the desktop entry, application icon, and AppStream metadata under the selected prefix. If you want to use the executable from a terminal, add the prefix's `bin` directory to your PATH.

Run the QML regression tests with the `qmltestrunner` from your Qt kit.

```sh
QT_QUICK_CONTROLS_CONF="$PWD/qtquickcontrols2.conf" \
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  XDG_CONFIG_HOME="$(mktemp -d)" qmltestrunner -import "$PWD" -input tests
```

## Project layout

| Path | Purpose |
| --- | --- |
| `App/` | C++ launcher, Qt SQL storage, ICS handling, background projection, and platform integration |
| `Calendar/` | Shared theme and design constants |
| `CalendarContent/` | QML views, controls, settings, and translation dictionaries |
| `packaging/` | Distribution recipes and Android bridge |
| `tests/` | Migration, ICS, calendar layout, and month-cache regression tests |

Open `Calendar.qmlproject` in Qt Design Studio to preview QML with in-memory events. Run the CMake executable to test the native database, file associations, or platform features.

## Performance measurements

An offscreen Qt 6.12.0 QML preview with 10,000 one-time events and 100 December–January transitions recorded a 95th-percentile frame interval of about 229 ms before the cache changes and 42 ms afterward. Peak process memory rose from about 170 MiB to 244 MiB. These numbers describe the synthetic preview and do not establish native Release performance or battery usage.
