// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick

QtObject {
    id: root

    property int period: new Date().getFullYear() * 12 + new Date().getMonth()
    property int firstWeekday: 1
    property var records: []
    property var zoneRules: ({})
    property string displayZone: ""
    readonly property int year: Math.floor(period / 12)
    readonly property int firstPeriod: Math.max(1900, year - 1) * 12
    readonly property int lastPeriod: Math.min(2100, year + 1) * 12 + 11
    property var months: ({})
    property string projectionFrom: ""
    property string projectionTo: ""
    property var segments: []
    property int projectionRequest: 0
    property bool projectionPending: false
    property int revision: 0
    property var previousRecords: ({})
    property int retainedYear: -1
    property bool busy: false

    function refresh(reset) {
        if (!worker.ready)
            return;
        const nextRecords = Object.create(null);
        const changed = [];
        let updateRecords = false;
        for (const record of records || []) {
            nextRecords[record.id] = record;
            const old = previousRecords[record.id];
            if (!old || old.title !== record.title || old.location !== record.location)
                updateRecords = true;
            if (!old || !sameMarkers(old, record)) {
                if (old)
                    changed.push(old);
                changed.push(record);
            }
        }
        for (const id in previousRecords) {
            if (!Object.prototype.hasOwnProperty.call(nextRecords, id))
                changed.push(previousRecords[id]);
        }
        previousRecords = nextRecords;
        if (reset) {
            months = {};
        } else if (changed.length) {
            const retained = {};
            for (const key in months) {
                const number = Number(key);
                const yearText = String(Math.floor(number / 12));
                const prefix = yearText + "-" + String(number % 12 + 1).padStart(2, "0");
                if (!changed.some(record => record.timeZone || (record.dateKey.slice(0, 7) <= prefix
                        && (record.repeat !== "none" || (record.endDateKey || record.dateKey).slice(0, 7) >= prefix))))
                    retained[key] = months[key];
            }
            months = retained;
        } else if (revision !== 0 && !updateRecords) {
            return;
        }
        ++revision;
        const fields = ["id", "title", "location", "marker", "dateKey", "endDateKey", "category",
                        "repeat", "repeatUntil", "startMinute", "endMinute", "allDay",
                        "weekdays", "excludedDates", "timeZone"];
        worker.sendMessage({records: JSON.stringify(records || [], fields), rules: JSON.stringify(zoneRules),
                            displayZone: displayZone, revision: revision});
        requestProjection();
    }

    function sameMarkers(old, record) {
        return old.dateKey === record.dateKey && old.endDateKey === record.endDateKey
            && old.category === record.category && old.marker === record.marker && old.repeat === record.repeat
            && old.repeatUntil === record.repeatUntil && old.startMinute === record.startMinute
            && old.endMinute === record.endMinute && old.allDay === record.allDay && old.timeZone === record.timeZone
            && (old.weekdays || []).join() === (record.weekdays || []).join()
            && (old.excludedDates || []).join() === (record.excludedDates || []).join();
    }

    function requestProjection() {
        ++projectionRequest;
        segments = [];
        projectionPending = !!projectionFrom && !!projectionTo && projectionFrom <= projectionTo;
        fillNext();
    }

    function keepWindow() {
        const newYear = Math.floor(period / 12);
        if (retainedYear !== newYear) {
            retainedYear = newYear;
            const kept = {};
            const earliest = Math.max(1900, newYear - 1) * 12;
            const latest = (Math.min(2100, newYear + 1) + 1) * 12;
            for (const key in months) {
                const value = Number(key);
                if (value >= earliest && value < latest)
                    kept[key] = months[key];
            }
            months = kept;
        }
        fillNext();
    }

    function fillNext() {
        if (busy || revision === 0)
            return;
        if (projectionPending) {
            projectionPending = false;
            busy = true;
            worker.sendMessage({projectionRequest: projectionRequest, from: projectionFrom, to: projectionTo});
            return;
        }
        const queue = [period, period - 1, period + 1];
        for (let distance = 2; distance <= 24; ++distance)
            queue.push(period - distance, period + distance);
        // Only one month is in flight. A new target can take priority immediately after it.
        for (const candidate of queue) {
            if (candidate >= firstPeriod && candidate <= lastPeriod && months[candidate] === undefined) {
                busy = true;
                worker.sendMessage({period: candidate, revision: revision, firstWeekday: firstWeekday});
                return;
            }
        }
    }

    onPeriodChanged: keepWindow()
    onProjectionFromChanged: requestProjection()
    onProjectionToChanged: requestProjection()
    onRecordsChanged: refresh(false)
    onZoneRulesChanged: refresh(true)
    onDisplayZoneChanged: refresh(true)
    onFirstWeekdayChanged: refresh(true)
    Component.onCompleted: refresh(true)

    property var nativeWorker: null
    readonly property var worker: nativeWorker || previewWorker
    property WorkerScript previewWorker: WorkerScript {
        id: previewWorker
        source: root.nativeWorker ? "" : "MonthCacheWorker.mjs"
    }

    property Connections workerConnection: Connections {
        target: root.worker
        function onReadyChanged() {
            if (root.worker.ready)
                root.refresh(true);
        }
        function onMessage(message) {
            root.busy = false;
            if (message.projectionRequest !== undefined) {
                if (message.projectionRequest === root.projectionRequest)
                    root.segments = message.segments;
            } else if (message.revision === root.revision
                       && message.period >= root.firstPeriod && message.period <= root.lastPeriod) {
                const updated = Object.assign({}, root.months);
                updated[message.period] = message.days || null;
                root.months = updated;
            }
            root.fillNext();
        }
    }
}
