# Using YoungLion Calendar

## Import and export events

Open **Settings → Import calendar**, choose an `.ics` file, and select the destination calendar in the preview. In an installed Linux session, opening an `.ics` file in the file manager also opens the import preview. **Settings → Export calendar** writes a local iCalendar file. Complex imported recurrence rules are retained for export and may appear as read-only in the editor.

On a native Linux installation with `xdg-mime`, **Settings → Set as default for calendar files** registers YoungLion Calendar as the default `text/calendar` handler. You can also choose the application in your desktop's file association settings.

## Reminders and system calendars

On Linux, turn on closed-window reminders in **Settings** to keep reminders active for your desktop session. Flatpak uses desktop portals, whose availability depends on the host session. On Android, notification permission controls whether alerts appear. The Android guide explains exact alarm permission and optional system calendar access. GNOME Evolution Data Server and KDE Akonadi calendar linking are currently unavailable.

## Back up or move your data

Export an ICS file for a portable copy of your local events. For a full Linux backup, close the application and stop its reminder helper before copying its data directory, including any SQLite sidecar files, and its configuration directory.

Native Linux installs normally store the database at `${XDG_DATA_HOME:-~/.local/share}/YoungLion/Calendar/events.sqlite` and preferences under `${XDG_CONFIG_HOME:-~/.config}/YoungLion/Calendar/`. Flatpak uses application-specific storage under `~/.var/app/xyz.younglion.Calendar/`. The first native launch imports existing records from `YoungLion/Calendar/events.ini` and leaves that file in place.
