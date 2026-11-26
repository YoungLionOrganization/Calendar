// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

export function makeDate(year, month, day) {
    return new Date(year, month, day, 12, 0, 0, 0);
}
export function daysInMonth(year, month) {
    return makeDate(year, month + 1, 0).getDate();
}
export function mondayOffset(date) {
    return (date.getDay() + 6) % 7;
}
export function addDays(date, offset) {
    return makeDate(date.getFullYear(), date.getMonth(), date.getDate() + offset);
}
export function clampedDate(year, month, day) {
    const first = makeDate(year, month, 1);
    // Month and year navigation preserve the day when possible.
    return makeDate(first.getFullYear(), first.getMonth(), Math.min(Math.max(day, 1), daysInMonth(first.getFullYear(), first.getMonth())));
}
export function sameDate(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
export function weekStart(date) {
    return addDays(date, -mondayOffset(date));
}
