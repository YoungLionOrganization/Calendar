// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtCore
import Calendar

QtObject {
    id: root
    property bool ready: false
    property string language: disk.language
    property string defaultView: disk.defaultView
    property int agendaDays: disk.agendaDays
    property alias calendarFilter: preferenceDisk.calendarFilter
    property alias accent: preferenceDisk.accent
    property alias use24HourClock: preferenceDisk.use24HourClock
    property alias defaultReminder: preferenceDisk.defaultReminder
    readonly property var localCalendars: {
        try { return JSON.parse(disk.calendarsJson); }
        catch (_) { return []; }
    }
    property alias displayZone: preferenceDisk.displayZone
    property alias defaultDuration: preferenceDisk.defaultDuration
    property alias nonWorkingDays: preferenceDisk.nonWorkingDays
    property alias firstWeekday: preferenceDisk.firstWeekday
    property bool showImportantTab: disk.showImportantTab
    property bool showEventMarkers: disk.showEventMarkers
    property QtObject disk: Settings {
        id: preferenceDisk
        property string calendarFilter: ""
        property string accent: "blue"
        property bool use24HourClock: true
        property int defaultReminder: -1
        property string calendarsJson: "[]"
        property string displayZone: ""
        property int defaultDuration: 60
        property int nonWorkingDays: 65
        property int firstWeekday: 1
        location: String(StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)) + "/YoungLion/Calendar/preferences.ini"
        category: "CalendarPreferencesV1"
        property string language: "system"
        property string defaultView: "year"
        property int agendaDays: 14
        property bool showImportantTab: true
        property bool showEventMarkers: true
        property string themeMode: "system"
        property bool highContrast: false
        property bool touchMode: false
        property bool compactDensity: false
        property bool reduceMotion: false
        property bool lowPowerMode: false
        property real uiScale: 1.0
    }
    function addCalendar(name, color) {
        const title = name.trim();
        if (!title || localCalendars.some(calendar => calendar.title === title))
            return false;
        disk.calendarsJson = JSON.stringify(localCalendars.concat({
            id: Date.now().toString(36), title: title, color: color
        }));
        return true;
    }
    onFirstWeekdayChanged: Constants.firstWeekday = firstWeekday
    onNonWorkingDaysChanged: Constants.nonWorkingDays = nonWorkingDays
    onAccentChanged: Constants.accent = accent
    onUse24HourClockChanged: Constants.use24HourClock = use24HourClock
    function applyLanguage() {
        Qt.uiLanguage = disk.language === "system" ? Qt.locale().name : disk.language;
    }
    function setLanguage(value) {
        disk.language = value;
        applyLanguage();
    }
    function setDefaultView(value) {
        disk.defaultView = value;
    }
    function setAgendaDays(value) {
        disk.agendaDays = value;
    }
    function setImportantTab(value) {
        disk.showImportantTab = value;
    }
    function setEventMarkers(value) {
        disk.showEventMarkers = value;
    }
    function reset() {
        setLanguage("system");
        setDefaultView("year");
        setAgendaDays(14);
        firstWeekday = 1;
        nonWorkingDays = 65;
        defaultDuration = 60;
        defaultReminder = -1;
        calendarFilter = "";
        displayZone = "";
        accent = "blue";
        use24HourClock = true;
        setImportantTab(true);
        setEventMarkers(true);
        Constants.themeMode = "system";
        Constants.highContrast = false;
        Constants.touchMode = false;
        Constants.compactDensity = false;
        Constants.reduceMotion = false;
        Constants.lowPowerMode = false;
        Constants.uiScale = 1.0;
    }
    Component.onCompleted: {
        Constants.firstWeekday = firstWeekday;
        Constants.nonWorkingDays = nonWorkingDays;
        Constants.accent = accent;
        Constants.use24HourClock = use24HourClock;
        Constants.themeMode = disk.themeMode;
        Constants.highContrast = disk.highContrast;
        Constants.touchMode = disk.touchMode;
        Constants.compactDensity = disk.compactDensity;
        Constants.reduceMotion = disk.reduceMotion;
        Constants.lowPowerMode = disk.lowPowerMode;
        Constants.uiScale = disk.uiScale;
        applyLanguage();
        ready = true;
    }
    property QtObject watcher: Connections {
        target: Constants
        function onThemeModeChanged() {
            if (root.ready)
                root.disk.themeMode = Constants.themeMode;
        }
        function onHighContrastChanged() {
            if (root.ready)
                root.disk.highContrast = Constants.highContrast;
        }
        function onTouchModeChanged() {
            if (root.ready)
                root.disk.touchMode = Constants.touchMode;
        }
        function onCompactDensityChanged() {
            if (root.ready)
                root.disk.compactDensity = Constants.compactDensity;
        }
        function onReduceMotionChanged() {
            if (root.ready)
                root.disk.reduceMotion = Constants.reduceMotion;
        }
        function onLowPowerModeChanged() {
            if (root.ready)
                root.disk.lowPowerMode = Constants.lowPowerMode;
        }
        function onUiScaleChanged() {
            if (root.ready)
                root.disk.uiScale = Constants.uiScale;
        }
    }
}
