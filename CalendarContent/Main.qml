// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Calendar
import "Components" as Components
import "Views" as Views
import "Shared/DateUtils.mjs" as DateUtils
import "Events" as EventPages
import "Events/EventLogic.mjs" as Logic
import "Settings" as SettingsPages
import "Shared/I18n.js" as L

Rectangle {
    id: root
    anchors.fill: parent
    color: Constants.background
    clip: true

    property var calendarWorker: null
    property var backend: null
    property var platform: null
    readonly property bool sidebar: width >= 600 && height >= 410

    property bool calendarModeOpen: false
    property string currentView: "year"
    property string mainTab: "calendar"
    property var todayDate: new Date()
    property var selectedDate: new Date(todayDate.getFullYear(), todayDate.getMonth(), todayDate.getDate(), 12)
    readonly property int selectedDay: selectedDate.getDate()
    readonly property int selectedMonth: selectedDate.getMonth() + 1
    readonly property int selectedYear: selectedDate.getFullYear()
    readonly property string selectedDateText: Qt.locale(Qt.uiLanguage).toString(selectedDate, "d MMMM yyyy")
    readonly property real pageMargin: Math.min(Constants.pagePadding, width / 8)

    EventPages.EventStore {
        id: eventStore
        backend: root.backend
        platform: root.platform
    }
    SettingsPages.Preferences {
        id: prefs
        onDisplayZoneChanged: root.updateToday()
    }
    property url importUrl
    property int importCount: 0
    function previewFile(url) {
        if (!backend || !backend.ready)
            return;
        importCount = backend.previewCalendar(url).length;
        if (!backend.error && importCount > 0) {
            importUrl = url;
            importConfirm.open();
        }
    }

    FileDialog {
        id: openCalendarFile
        title: L.tr("Open calendar file", Qt.uiLanguage)
        nameFilters: ["iCalendar (*.ics)", "*"]
        onAccepted: root.previewFile(selectedFile)
    }

    FileDialog {
        id: saveCalendarFile
        title: L.tr("Export calendar", Qt.uiLanguage)
        fileMode: FileDialog.SaveFile
        defaultSuffix: "ics"
        nameFilters: ["iCalendar (*.ics)"]
        onAccepted: root.backend.exportCalendar(selectedFile)
    }

    Components.CalendarDialog {
        id: importConfirm
        title: L.tr("Import calendar", Qt.uiLanguage)
        dialogAvailableWidth: root.width
        contentItem: ColumnLayout {
            Label {
                text: L.tr("Events to import", Qt.uiLanguage) + " · " + root.importCount
                color: Constants.textPrimary
            }
            Components.CalendarComboBox {
                id: importDestination
                Layout.fillWidth: true
                readonly property var ids: ["local", ...prefs.localCalendars.map(calendar => calendar.id)]
                model: [L.tr("Local calendar", Qt.uiLanguage), ...prefs.localCalendars.map(calendar => calendar.title)]
                Accessible.name: L.tr("Calendar", Qt.uiLanguage)
            }
        }
        footer: DialogButtonBox {
            Components.CalendarButton {
                text: L.tr("Cancel", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            Components.CalendarButton {
                text: L.tr("Import calendar", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        onAccepted: root.backend.importCalendar(root.importUrl, importDestination.ids[importDestination.currentIndex])
    }

    property string pageMode: ""
    property var editorRecord: null
    property string activeOccurrence: ""
    property string editingOccurrence: ""
    property string activeEventId: ""
    property string editorReturn: ""
    property string detailsReturn: ""
    readonly property var activeRecord: eventStore.find(activeEventId)
    readonly property var eventColors: {
        const result = {
            personal: [Constants.eventPersonal, Constants.eventPersonalBackground],
            work: [Constants.eventWork, Constants.eventWorkBackground],
            study: [Constants.eventStudy, Constants.eventStudyBackground],
            health: [Constants.eventHealth, Constants.eventHealthBackground],
            travel: [Constants.eventTravel, Constants.eventTravelBackground],
            family: [Constants.eventFamily, Constants.eventFamilyBackground],
            birthday: [Constants.eventBirthday, Constants.eventBirthdayBackground],
            holiday: [Constants.eventHoliday, Constants.eventHolidayBackground],
            other: [Constants.eventOther, Constants.eventOtherBackground]
        };
        for (const calendar of prefs.localCalendars)
            result[calendar.id] = [calendar.color, Constants.surfaceSecondary];
        return result;
    }
    readonly property var visibleRecords: {
        const ids = new Set(prefs.localCalendars.map(calendar => calendar.id));
        return eventStore.records.filter(record => !prefs.calendarFilter
                                         || (record.calendarId || "local") === prefs.calendarFilter).map(record =>
            ids.has(record.calendarId) ? Object.assign({}, record, {marker: record.calendarId}) : record);
    }

    readonly property string requestedZones: {
        const unique = new Set(["", prefs.displayZone]);
        for (const event of visibleRecords)
            if (event.timeZone)
                unique.add(event.timeZone);
        return JSON.stringify(Array.from(unique).sort());
    }
    readonly property var zoneRules: backend && typeof backend.timeZoneRules === "function"
                                     ? backend.timeZoneRules(JSON.parse(requestedZones)) : ({})
    readonly property bool showProjections: pageMode === "" && mainTab === "calendar" && currentView !== "year"
    readonly property var weekStart: DateUtils.addDays(selectedDate, -((selectedDate.getDay() - prefs.firstWeekday + 7) % 7))
    readonly property var previewEvents: monthCache.segments.map(segment => {
        const colors = eventColors[segment.marker || segment.category] || eventColors.other;
        return Object.assign({}, segment, {
            date: Logic.date(segment.visibleDate), color: colors[0], background: colors[1]
        });
    })
    Views.MonthCache {
        id: monthCache
        nativeWorker: root.calendarWorker
        period: root.selectedYear * 12 + root.selectedMonth - 1
        records: root.visibleRecords
        zoneRules: root.zoneRules
        displayZone: prefs.displayZone
        firstWeekday: prefs.firstWeekday
        projectionFrom: root.showProjections ? Logic.key(root.currentView === "week" ? root.weekStart : root.selectedDate) : ""
        projectionTo: {
            if (!root.showProjections)
                return "";
            return Logic.key(root.currentView === "week" ? DateUtils.addDays(root.weekStart, 6)
                           : root.currentView === "agenda" ? DateUtils.addDays(root.selectedDate, prefs.agendaDays - 1)
                           : root.selectedDate);
        }
    }
    Component.onCompleted: Qt.callLater(function () {
        root.currentView = prefs.defaultView;
        root.updateToday();
    })
    function openNew(date, minute) {
        if (!eventStore.ready)
            return;
        editingOccurrence = "";
        editorReturn = pageMode;
        editorRecord = eventStore.newRecord(date || selectedDate, minute, prefs.defaultDuration);
        editorRecord.calendarId = prefs.calendarFilter || "local";
        editorRecord.reminder = prefs.defaultReminder;
        editorRecord.timeZone = prefs.displayZone;
        pageMode = "editor";
    }
    function openDetails(id, occurrence) {
        if (!eventStore.find(id))
            return;
        activeOccurrence = occurrence || "";
        detailsReturn = pageMode;
        activeEventId = id;
        pageMode = "details";
    }
    function editEvent(duplicate, single) {
        if (!activeRecord || (activeRecord.readOnly && !duplicate))
            return;
        editorReturn = "details";
        editorRecord = Object.assign({}, activeRecord, {
            id: duplicate ? "" : activeRecord.id
        });
        editingOccurrence = single ? activeOccurrence : "";
        if (duplicate) {
            editorRecord.icsUid = "";
            editorRecord.icsRecurrenceId = "";
            editorRecord.readOnly = false;
            if (String(editorRecord.calendarId).startsWith("android-calendar:"))
                editorRecord.calendarId = "local";
        } else if (single) {
            const day = Logic.date(activeOccurrence);
            const duration = Logic.diff(Logic.date(activeRecord.endDateKey || activeRecord.dateKey),
                                        Logic.date(activeRecord.dateKey));
            editorRecord.dateKey = activeOccurrence;
            editorRecord.endDateKey = Logic.key(DateUtils.addDays(day, duration));
            editorRecord.repeat = "none";
            editorRecord.repeatUntil = "";
        }
        pageMode = "editor";
    }
    function backFromDetails() {
        pageMode = detailsReturn;
        activeEventId = "";
    }
    function saveRecord(record) {
        const id = editingOccurrence && backend
                 ? backend.saveOccurrence(activeEventId, editingOccurrence, record) : eventStore.save(record);
        if (!id)
            return;
        // Return to details for edited/duplicated items, otherwise calendar/search.
        if (editorReturn === "details") {
            if (id !== activeEventId)
                activeOccurrence = "";
            activeEventId = id;
            pageMode = "details";
        } else {
            pageMode = editorReturn;
            setDate(Logic.date(record.dateKey).getFullYear(), Logic.date(record.dateKey).getMonth(), Logic.date(record.dateKey).getDate());
        }
    }
    function showEvents() {
        mainTab = "calendar";
        pageMode = "search";
    }
    function setDate(year, monthIndex, day) {
        const candidate = DateUtils.clampedDate(year, monthIndex, day);
        if (candidate.getFullYear() >= 1900 && candidate.getFullYear() <= 2100)
            selectedDate = candidate;
    }
    function changeDay(offset) {
        const date = DateUtils.addDays(selectedDate, offset);
        setDate(date.getFullYear(), date.getMonth(), date.getDate());
    }
    function changeMonth(offset) {
        setDate(selectedYear, selectedMonth - 1 + offset, selectedDay);
    }
    function changeYear(offset) {
        if (selectedYear + offset >= 1900 && selectedYear + offset <= 2100)
            setDate(selectedYear + offset, selectedMonth - 1, selectedDay);
    }
    function changeWeek(offset) {
        const date = DateUtils.addDays(selectedDate, offset * 7);
        setDate(date.getFullYear(), date.getMonth(), date.getDate());
    }
    function showView(viewName) {
        mainTab = "calendar";
        currentView = viewName;
        calendarModeOpen = false;
    }
    function updateToday() {
        const next = backend && typeof backend.todayInZone === "function"
                   ? Logic.date(backend.todayInZone(prefs.displayZone)) : new Date();
        if (DateUtils.sameDate(next, todayDate))
            return;
        const wasToday = DateUtils.sameDate(selectedDate, todayDate);
        todayDate = next;
        if (wasToday)
            setDate(next.getFullYear(), next.getMonth(), next.getDate());
    }
    function goToday() {
        updateToday();
        setDate(todayDate.getFullYear(), todayDate.getMonth(), todayDate.getDate());
        mainTab = "calendar";
    }

    Components.HeaderBar {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.pageMargin
        anchors.rightMargin: root.pageMargin
        modeOpen: root.calendarModeOpen
        onAddRequested: root.openNew(root.selectedDate)
        onViewRequested: root.calendarModeOpen = !root.calendarModeOpen
        onSearchRequested: root.showEvents()
        onGoRequested: goDialog.open()
        onSettingsRequested: root.pageMode = "settings"
        onTodayRequested: root.goToday()
    }

    Components.CalendarModeArea {
        id: calendarModeArea
        visible: !root.sidebar
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.pageMargin
        anchors.rightMargin: root.pageMargin
        expanded: !root.sidebar && root.calendarModeOpen
        currentView: root.currentView
        onViewSelected: function (viewName) {
            root.showView(viewName);
        }
    }

    Components.HeaderArea {
        id: headerArea
        anchors.top: calendarModeArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.pageMargin
        anchors.rightMargin: root.pageMargin
        titleText: root.width < Constants.breakpointPhone ? L.tr("Calendar", Qt.uiLanguage) : Constants.appName
        dateText: root.selectedDateText
    }

    Rectangle {
        id: headerDivider
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Constants.borderWidth
        color: Constants.divider
    }

    Components.BottomNavigation {
        id: bottomNavigation
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        currentTab: root.mainTab
        visible: prefs.showImportantTab
        height: visible ? Constants.bottomNavigationHeight : 0
        onTabSelected: function (tab) {
            root.mainTab = tab;
            root.calendarModeOpen = false;
        }
    }

    Components.CalendarModeArea {
        id: sideNavigation
        anchors.top: headerDivider.bottom
        anchors.topMargin: Constants.spacingSm
        anchors.left: parent.left
        anchors.leftMargin: root.pageMargin
        visible: root.sidebar
        expanded: root.sidebar
        vertical: true
        width: 100
        currentView: root.mainTab === "calendar" ? root.currentView : ""
        onViewSelected: viewName => root.showView(viewName)
    }

    Item {
        id: calendarContent
        anchors.top: headerDivider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.pageMargin + (root.sidebar ? sideNavigation.width + Constants.spacingMd : 0)
        anchors.rightMargin: root.pageMargin
        anchors.topMargin: Constants.spacingSm
        height: Math.max(0, bottomNavigation.y - y - Constants.spacingSm)
        clip: true

        Loader {
            id: viewLoader
            anchors.fill: parent
            active: root.pageMode === ""
            sourceComponent: root.mainTab === "important" ? importantViewComponent : root.currentView === "year" ? yearViewComponent : root.currentView === "month" ? monthViewComponent : root.currentView === "week" ? weekViewComponent : agendaViewComponent
        }
    }

    Component {
        id: yearViewComponent
        Views.YearView {
            yearNumber: root.selectedYear
            referenceDate: root.todayDate
            onYearSelected: function (year) {
                root.setDate(year, root.selectedMonth - 1, root.selectedDay);
            }
            onMonthSelected: function (monthIndex) {
                root.setDate(root.selectedYear, monthIndex, 1);
                root.showView("month");
            }
        }
    }
    Component {
        id: monthViewComponent
        Views.MonthView {
            yearNumber: root.selectedYear
            monthIndex: root.selectedMonth - 1
            selectedDate: root.selectedDate
            referenceDate: root.todayDate
            events: root.previewEvents
            sideDetails: root.width >= 960 && root.height >= 400
            cache: monthCache
            firstWeekday: prefs.firstWeekday
            eventColors: root.eventColors
            showEventMarkers: prefs.showEventMarkers
            onEventSelected: function (e) {
                root.openDetails(e.id, e.occurrenceKey);
            }
            onAddRequested: root.openNew(root.selectedDate)
            onCreateRequested: function (date) {
                root.openNew(date);
            }
            onMonthSelected: function (year, month) {
                root.setDate(year, month, root.selectedDay);
            }
            onDaySelected: function (date) {
                root.setDate(date.getFullYear(), date.getMonth(), date.getDate());
            }
        }
    }
    Component {
        id: weekViewComponent
        Views.WeekView {
            firstWeekday: prefs.firstWeekday
            selectedDate: root.selectedDate
            referenceDate: root.todayDate
            events: root.previewEvents
            onEventSelected: function (eventData) {
                root.openDetails(eventData.id, eventData.occurrenceKey);
            }
            onCreateRequested: function (date, minute) {
                root.openNew(date, minute);
            }
            onPreviousRequested: root.changeWeek(-1)
            onNextRequested: root.changeWeek(1)
            onDaySelected: function (date) {
                root.setDate(date.getFullYear(), date.getMonth(), date.getDate());
            }
        }
    }
    Component {
        id: agendaViewComponent
        Views.AgendaView {
            id: agendaView
            rangeDays: prefs.agendaDays
            selectedDate: root.selectedDate
            referenceDate: root.todayDate
            events: root.previewEvents
            onEventSelected: function (eventData) {
                root.openDetails(eventData.id, eventData.occurrenceKey);
            }
            onPreviousRequested: root.changeDay(-agendaView.rangeDays)
            onNextRequested: root.changeDay(agendaView.rangeDays)
        }
    }
    Component {
        id: importantViewComponent
        EventPages.EventListPage {
            records: root.visibleRecords
            importantOnly: true
            onBackRequested: root.mainTab = "calendar"
            onEventRequested: function (eventId) {
                root.openDetails(eventId);
            }
        }
    }

    Components.GoToDateDialog {
        id: goDialog
        selectedDate: root.selectedDate
        dialogAvailableWidth: root.width
        onDateRequested: function (year, monthIndex, day) {
            root.setDate(year, monthIndex, day);
            root.showView("month");
        }
    }
    Loader {
        id: pageLoader
        anchors.fill: parent
        z: 20
        active: root.pageMode !== ""
        onLoaded: {
            if (Constants.animationsEnabled)
                pageEnter.restart();
        }
        NumberAnimation {
            id: pageEnter
            target: pageLoader
            property: "opacity"
            from: 0.65
            to: 1
            duration: Constants.durationNormal
            easing.type: Easing.OutCubic
        }
        sourceComponent: root.pageMode === "editor" ? editorPage : root.pageMode === "details" ? detailsPage : root.pageMode === "settings" ? settingsPage : searchPage
    }
    Component {
        id: editorPage
        EventPages.EventEditorPage {
            record: root.editorRecord
            calendars: prefs.localCalendars
            onSaved: function (record) {
                root.saveRecord(record);
            }
            onCancelRequested: root.pageMode = root.editorReturn
        }
    }
    Component {
        id: detailsPage
        EventPages.EventDetailsPage {
            record: root.activeRecord || ({
                    title: "",
                    dateKey: Logic.key(root.selectedDate),
                    endDateKey: Logic.key(root.selectedDate),
                    startMinute: 0,
                    endMinute: 0,
                    category: "other",
                    repeat: "none"
                })
            onBackRequested: root.backFromDetails()
            canEditOccurrence: !!root.backend && !!root.activeOccurrence && root.activeRecord?.repeat !== "none" && !root.activeRecord?.readOnly
            onEditRequested: root.editEvent(false, false)
            onEditOccurrenceRequested: root.editEvent(false, true)
            onDuplicateRequested: root.editEvent(true)
            onDeleteRequested: {
                if (eventStore.remove(root.activeEventId))
                    root.backFromDetails();
            }
            onImportantRequested: {
                if (root.activeRecord)
                    eventStore.save(Object.assign({}, root.activeRecord, {
                        important: !root.activeRecord.important
                    }));
            }
        }
    }
    Component {
        id: settingsPage
        SettingsPages.SettingsPage {
            preferences: prefs
            backend: root.backend
            canUseFiles: !!root.backend && root.backend.ready
            platform: root.platform
            onImportRequested: openCalendarFile.open()
            onExportRequested: saveCalendarFile.open()
            onBackRequested: {
                root.pageMode = "";
                if (!prefs.showImportantTab)
                    root.mainTab = "calendar";
            }
            onSamplesRequested: eventStore.addSamples(root.todayDate)
        }
    }
    Component {
        id: searchPage
        EventPages.EventListPage {
            records: root.visibleRecords
            onBackRequested: root.pageMode = ""
            onEventRequested: function (eventId) {
                root.openDetails(eventId);
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+N"
        enabled: root.pageMode === ""
        onActivated: root.openNew(root.selectedDate)
    }
    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.pageMode === ""
        onActivated: root.showEvents()
    }
    Shortcut {
        sequence: "Ctrl+,"
        enabled: root.pageMode === ""
        onActivated: root.pageMode = "settings"
    }
    Shortcut {
        sequence: "Ctrl+T"
        enabled: root.pageMode === ""
        onActivated: root.goToday()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.pageMode !== ""
        onActivated: {
            if (pageLoader.item)
                pageLoader.item.backRequested();
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.updateToday()
    }
    Label {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        z: 50
        visible: eventStore.storageError.length > 0
        text: eventStore.storageError
        wrapMode: Text.WordWrap
        color: Constants.error
        padding: Constants.spacingSm
        background: Rectangle {
            color: Constants.errorBackground
        }
    }
}
