// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import * as Dates from "DateUtils.mjs";

export function dayEvents(events, date, allDay) {
    return events.filter(function (event) {
        return Dates.sameDate(event.date, date) && event.allDay === allDay;
    }).sort(function (a, b) {
        return a.startMinute - b.startMinute || a.endMinute - b.endMinute;
    });
}
export function agendaRows(events, start, days) {
    const rows = [];
    for (let i = 0; i < days; ++i) {
        const date = Dates.addDays(start, i);
        const items = dayEvents(events, date, true).concat(dayEvents(events, date, false));
        if (items.length === 0)
            continue;
        rows.push({
            kind: "day",
            date: date,
            count: items.length
        });
        for (let j = 0; j < items.length; ++j)
            rows.push({
                kind: "event",
                event: items[j]
            });
    }
    return rows;
}
// Assign overlapping intervals to distinct lanes within each overlap group.
export function lanes(events, date) {
    const sorted = dayEvents(events, date, false);
    const output = [];
    let group = [], ends = [], groupEnd = -1;
    function finish() {
        for (let i = 0; i < group.length; ++i) {
            group[i].laneCount = ends.length;
            output.push(group[i]);
        }
        group = [];
        ends = [];
        groupEnd = -1;
    }
    for (let i = 0; i < sorted.length; ++i) {
        const event = sorted[i];
        if (event.startMinute >= groupEnd && group.length)
            finish();
        let lane = 0;
        while (lane < ends.length && ends[lane] > event.startMinute)
            ++lane;
        ends[lane] = event.endMinute;
        groupEnd = Math.max(groupEnd, event.endMinute);
        group.push({
            event: event,
            lane: lane,
            laneCount: 1
        });
    }
    if (group.length)
        finish();
    return output;
}
export function timeText(date, minute, locale, use24HourClock = true) {
    if (minute === 1440 && use24HourClock)
        return "24:00";
    const value = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, minute);
    return locale.toString(value, use24HourClock ? "HH:mm" : "h:mm AP");
}
