// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import * as Events from "../Events/EventLogic.mjs";
import * as Dates from "../Shared/DateUtils.mjs";

let records = [];
let rules = {};
let displayZone = "";

WorkerScript.onMessage = function (request) {
    if (request.records !== undefined) {
        records = JSON.parse(request.records);
        rules = JSON.parse(request.rules || "{}");
        displayZone = request.displayZone || "";
        return;
    }

    if (request.projectionRequest !== undefined) {
        projectRange(request);
        return;
    }
    const year = Math.floor(request.period / 12);
    const month = request.period % 12;
    const start = Dates.makeDate(year, month, 1);
    const end = Dates.makeDate(year, month + 1, 0);
    const offset = (start.getDay() - request.firstWeekday + 7) % 7;
    const days = Array.from({ length: 42 }, (_, index) => {
        const day = Dates.addDays(start, index - offset);
        return { key: Events.key(day), markers: [] };
    });
    const firstKey = Events.key(start);
    const lastKey = Events.key(end);
    for (const record of records) {
        if (!record.timeZone && (record.dateKey > lastKey || ((!record.repeat || record.repeat === "none") && (record.endDateKey || record.dateKey) < firstKey)))
            continue;
        Events.forEachSegment(record, start, end, function (day) {
            const markers = days[day.getDate() - 1 + offset].markers;
            if (markers.length < 4 && !markers.includes(record.marker || record.category))
                markers.push(record.marker || record.category || "other");
        }, rules, displayZone);
    }
    WorkerScript.sendMessage({period: request.period, revision: request.revision, days: days});
};

function projectRange(request) {
    const start = Events.date(request.from);
    const end = Events.date(request.to);
    const segments = [];
    for (const record of records) {
        if (!record.timeZone && (record.dateKey > request.to || ((!record.repeat || record.repeat === "none")
                && (record.endDateKey || record.dateKey) < request.from)))
            continue;
        Events.forEachSegment(record, start, end, (day, begin, finish, occurrence) => {
            segments.push({
                id: record.id, title: record.title, location: record.location || "", allDay: !!record.allDay,
                category: record.category, marker: record.marker || "",
                startMinute: begin, endMinute: finish, visibleDate: Events.key(day),
                occurrenceKey: Events.key(occurrence)
            });
        }, rules, displayZone);
    }
    WorkerScript.sendMessage({projectionRequest: request.projectionRequest, segments});
}
