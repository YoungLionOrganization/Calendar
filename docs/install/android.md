# Android

The published APK targets arm64 phones and tablets with Android 9 or newer. Download the Android arm64 asset from [GitHub Releases](https://github.com/YoungLionOrganization/Calendar/releases/latest). Open it on the device and allow installation from the file manager or browser if Android prompts you.

To install from a computer with USB debugging enabled, connect the device and use Android Platform Tools.

```sh
adb devices
adb install -r younglion-calendar-0.2.0-android-arm64.apk
```

APK updates require the same signing certificate as the installed build. The v0.2.0 APK uses a test certificate. If Android rejects an update because the signatures differ, export your local events before uninstalling the previous app.

In **Settings**, enable reminders and grant notification access. Allow exact alarms if you want precise scheduling and Android makes that setting available. **System calendars** lets you connect a calendar after granting Android Calendar Provider permissions.

## Build from source

Use the Qt for Android kit and matching desktop Qt tools, Java, Android SDK and NDK, and libical built for the target Android ABI. The [artifact workflow](../../.github/workflows/build-artifacts.yml) contains the dependency build commands. Set `ANDROID_SDK_ROOT` and `ANDROID_NDK_ROOT` before configuring.

```sh
/path/to/Qt/android_arm64_v8a/bin/qt-cmake -S . -B build-android -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DANDROID_ABI=arm64-v8a \
  -DLibIcal_DIR=/path/to/android/libical/lib/cmake/LibIcal
cmake --build build-android --target apk
```

Sign a Release APK with Android `apksigner` before installing or distributing it. The CI workflow signs and verifies it when repository signing credentials are configured.
