// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtTest
import "../CalendarContent/Views" as Views

TestCase {
    name: "MonthCache"
    Views.MonthCache {
        id: cache
        period: 2026 * 12 + 11
        records: [{id: "a", title: "New year", category: "work", dateKey: "2027-01-01",
                   endDateKey: "2027-01-01", startMinute: 540, endMinute: 600, repeat: "none"}]
    }
    function test_windowAndMarkers() {
        const january = 2027 * 12;
        tryVerify(() => Object.keys(cache.months).length === 36, 10000);
        const januaryData = cache.months[january];
        verify(januaryData.some(day => day.key === "2027-01-01" && day.markers[0] === "work"));
        cache.period = january;
        compare(cache.months[january], januaryData);
        verify(cache.months[2025 * 12] === undefined);
        tryVerify(() => cache.months[2028 * 12 + 11] !== undefined);
        cache.period = 2025 * 12 + 11;
        verify(cache.months[2028 * 12] === undefined);
        tryVerify(() => cache.months[2024 * 12] !== undefined);
        tryVerify(() => Object.keys(cache.months).length === 36);
    }
    function test_timeZoneAndStaleResult() {
        cache.period = 2026 * 12 + 11;
        cache.displayZone = "Asia/Baku";
        cache.zoneRules = {
            "Asia/Baku": [[0, 14400]],
            "America/New_York": [[0, -18000]]
        };
        cache.records = [{id: "z", title: "Later tonight", category: "work",
                          dateKey: "2026-12-31", endDateKey: "2026-12-31",
                          startMinute: 1200, endMinute: 1260, repeat: "none",
                          timeZone: "America/New_York"}];
        cache.projectionFrom = "2026-12-31";
        cache.projectionTo = "2026-12-31";
        cache.projectionFrom = "2027-01-01";
        cache.projectionTo = "2027-01-01";
        tryVerify(() => cache.segments.length === 1);
        compare(cache.segments[0].startMinute, 300);
        compare(cache.segments[0].visibleDate, "2027-01-01");
        compare(cache.segments[0].occurrenceKey, "2026-12-31");
    }

}
