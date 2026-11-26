// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import * as Dates from "../Shared/DateUtils.mjs";

export function key(d) {
    return String(d.getFullYear()).padStart(4, "0") + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
}
export function date(k) {
    const p = String(k).split("-");
    return Dates.makeDate(Number(p[0]), Number(p[1]) - 1, Number(p[2]));
}
export function ordinal(d) {
    return Math.round(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / 86400000);
}
export function diff(a, b) {
    return ordinal(a) - ordinal(b);
}
export function minute(text) {
    const m = /^(\d{1,2}):(\d{2})$/.exec(text.trim());
    if (!m)
        return -1;
    const h = Number(m[1]), n = Number(m[2]);
    return h <= 23 && n <= 59 ? h * 60 + n : h === 24 && n === 0 ? 1440 : -1;
}
export function time(n) {
    return String(Math.floor(n / 60)).padStart(2, "0") + ":" + String(n % 60).padStart(2, "0");
}
export function categories() {
    return ["personal", "work", "study", "health", "travel", "family", "birthday", "holiday", "other"];
}
export function categoryLabel(c) {
    return ({
            personal: "Personal",
            work: "Work",
            study: "Study",
            health: "Health",
            travel: "Travel",
            family: "Family",
            birthday: "Birthday",
            holiday: "Holiday",
            other: "Other"
        })[c] || "Other";
}
export function matches(record, start, candidate) {
    const n = diff(candidate, start);
    if (n < 0 || (record.repeatUntil && key(candidate) > record.repeatUntil)
            || (record.excludedDates && record.excludedDates.includes(key(candidate))))
        return false;
    switch (record.repeat) {
    case "daily":
        return true;
    case "weekly":
        return record.weekdays && record.weekdays.length
                ? record.weekdays.includes(candidate.getDay() || 7) : n % 7 === 0;
    case "monthly":
        return candidate.getDate() === start.getDate();
    case "yearly":
        return candidate.getDate() === start.getDate() && candidate.getMonth() === start.getMonth();
    default:
        return n === 0;
    }
}
const millisPerDay = 86400000;
const millisPerMinute = 60000;

function offsetAt(table, instant) {
    let first = 0;
    let last = table.length - 1;
    while (first < last) {
        const middle = Math.floor((first + last + 1) / 2);
        if (table[middle][0] <= instant)
            first = middle;
        else
            last = middle - 1;
    }
    return table[first][1] * 1000;
}

function toInstant(table, wallTime) {
    const before = offsetAt(table, wallTime - millisPerDay);
    const instant = wallTime - before;
    const current = offsetAt(table, instant);
    const adjusted = wallTime - current;
    return current !== before && offsetAt(table, adjusted) === current ? adjusted : instant;
}

function projectZoned(event, candidate, span, from, to, sourceZone, targetZone, visit) {
    const sourceDay = ordinal(candidate) * millisPerDay;
    const start = toInstant(sourceZone, sourceDay + event.startMinute * millisPerMinute);
    const end = toInstant(sourceZone, sourceDay + span * millisPerDay + event.endMinute * millisPerMinute);
    const first = start + offsetAt(targetZone, start);
    const last = Math.max(first + millisPerMinute, end + offsetAt(targetZone, end));
    const firstDay = Math.max(ordinal(from), Math.floor(first / millisPerDay));
    const lastDay = Math.min(ordinal(to), Math.ceil(last / millisPerDay) - 1);
    for (let serial = firstDay; serial <= lastDay; ++serial) {
        const wallDay = serial * millisPerDay;
        const utc = new Date(wallDay);
        const day = Dates.makeDate(utc.getUTCFullYear(), utc.getUTCMonth(), utc.getUTCDate());
        const begin = Math.max(0, Math.floor((first - wallDay) / millisPerMinute));
        const finish = Math.min(1440, Math.ceil((last - wallDay) / millisPerMinute));
        if (finish > begin)
            visit(day, begin, finish, candidate);
    }
}

// Visit only the segments intersecting this view's date range.
export function forEachSegment(event, from, to, visit, rules = {}, displayZone = "") {
    const sourceZone = !event.allDay && event.timeZone && rules[event.timeZone];
    const targetZone = sourceZone && rules[displayZone];
    const zoned = !!targetZone && event.timeZone !== displayZone;
    const start = date(event.dateKey);
    const end = date(event.endDateKey || event.dateKey);
    const span = diff(end, start);
    const rangeEnd = ordinal(to) + (zoned ? 2 : 0);
    if (!isFinite(span) || span < 0 || span > 365 || ordinal(start) > rangeEnd)
        return;
    const repeating = event.repeat && event.repeat !== "none";
    if (!repeating && ordinal(end) < ordinal(from) - (zoned ? 2 : 0))
        return;
    const earliest = repeating ? Dates.addDays(from, -span - (zoned ? 2 : 0)) : start;
    let candidate = ordinal(start) > ordinal(earliest) ? start : earliest;
    const last = event.repeatUntil ? Math.min(rangeEnd, ordinal(date(event.repeatUntil))) : rangeEnd;
    const jumpWeekly = event.repeat === "weekly" && !(event.weekdays && event.weekdays.length);
    if (jumpWeekly)
        candidate = Dates.addDays(candidate, (7 - diff(candidate, start) % 7) % 7);
    const step = jumpWeekly ? 7 : 1;
    for (; ordinal(candidate) <= last; candidate = Dates.addDays(candidate, step)) {
        if (matches(event, start, candidate)) {
            if (zoned) {
                projectZoned(event, candidate, span, from, to, sourceZone, targetZone, visit);
            } else for (let offset = Math.max(0, diff(from, candidate)); offset <= span; ++offset) {
                const day = Dates.addDays(candidate, offset);
                if (ordinal(day) > rangeEnd)
                    break;
                const begin = event.allDay ? 0 : offset === 0 ? event.startMinute : 0;
                const finish = event.allDay ? 1440 : offset === span ? event.endMinute : 1440;
                if (finish > begin)
                    visit(day, begin, finish, candidate);
            }
        }
        if (!repeating)
            break;
    }
}

export function project(records, from, to, palette) {
    const out = [];
    for (const event of records) {
        const colors = palette[event.marker || event.category] || palette.other;
        forEachSegment(event, from, to, function (day, begin, finish, occurrence) {
            out.push(Object.assign({}, event, {
                date: day, startMinute: begin, endMinute: finish,
                color: colors[0], background: colors[1], occurrenceKey: key(occurrence)
            }));
        });
    }
    return out;
}
export function search(records, query, category, importantOnly) {
    const q = query.trim().toLocaleLowerCase();
    return records.filter(function (e) {
        return (!importantOnly || e.important) && (category === "all" || e.category === category) && (!q || [e.title, e.location, e.description, e.dateKey].join(" ").toLocaleLowerCase().indexOf(q) >= 0);
    }).sort(function (a, b) {
        return a.dateKey.localeCompare(b.dateKey) || a.startMinute - b.startMinute;
    });
}

export function validRecord(e) {
    if (!e || typeof e.id !== "string" || typeof e.title !== "string" || !e.title.trim() || typeof e.dateKey !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(e.dateKey))
        return false;
    const end = e.endDateKey || e.dateKey, a = date(e.dateKey), b = date(end), span = diff(b, a);
    if (key(a) !== e.dateKey || key(b) !== end || a.getFullYear() < 1900 || b.getFullYear() > 2100 || span < 0 || span > 365 || !isFinite(span))
        return false;
    if (!Number.isInteger(e.startMinute) || !Number.isInteger(e.endMinute) || e.startMinute < 0 || e.startMinute >= 1440 || e.endMinute <= 0 || e.endMinute > 1440 || (span === 0 && e.endMinute <= e.startMinute))
        return false;
    if (["none", "daily", "weekly", "monthly", "yearly"].indexOf(e.repeat) < 0)
        return false;
    if (e.repeatUntil && (typeof e.repeatUntil !== "string" || key(date(e.repeatUntil)) !== e.repeatUntil || e.repeatUntil < e.dateKey))
        return false;
    // Disallow overlapping instances in this prototype; full recurrence rules are a backend task.
    return e.repeat === "none" || span < ({
            daily: 1,
            weekly: 7,
            monthly: 28,
            yearly: 365
        })[e.repeat];
}
