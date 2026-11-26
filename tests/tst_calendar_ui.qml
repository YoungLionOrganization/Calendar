// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtTest
import "../CalendarContent" as Ui

Item {
    id: window
    width: 1000
    height: 760
    Ui.Main { id: calendar }
    TestCase {
        name: "CalendarUi"
        when: windowShown

        function test_layoutAndNavigation() {
            for (const width of [390, 800, 1200]) {
                window.width = width;
                compare(calendar.sidebar, width >= 600);
                for (const view of ["year", "month", "week", "agenda"]) {
                    calendar.showView(view);
                    compare(calendar.currentView, view);
                    wait(10);
                }
            }
            calendar.showView("month");
            calendar.setDate(2026, 11, 31);
            calendar.changeMonth(1);
            compare(calendar.selectedYear, 2027);
            compare(calendar.selectedMonth, 1);
            calendar.openNew(calendar.selectedDate);
            compare(calendar.pageMode, "editor");
            const event = calendar.editorRecord;
            event.title = "Test event";
            calendar.saveRecord(event);
            compare(calendar.pageMode, "");
            calendar.showEvents();
            compare(calendar.pageMode, "search");
            calendar.pageMode = "settings";
            wait(100);
        }
    }
}
