// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar
import "../Shared/DateUtils.mjs" as Dates
import "EventLogic.mjs" as Logic
import "../Shared/I18n.js" as L

QtObject {
    id: root
    property var backend: null
    property var platform: null
    readonly property var records: backend ? backend.records.concat(platform ? platform.systemRecords : []) : previewRecords
    readonly property bool ready: backend ? backend.ready : true
    readonly property string storageError: backend ? backend.error : ""
    property var previewRecords: []
    function find(id) {
        return records.find(function (e) {
            return e.id === id;
        }) || null;
    }
    function save(record) {
        if (!ready)
            return "";
        const item = Object.assign({}, record);
        if (item.id.startsWith("android:"))
            return platform && platform.saveSystemEvent(item) ? item.id : "";
        if (backend)
            return backend.save(item);
        if (!Logic.validRecord(item))
            return "";
        if (!item.id)
            item.id = Date.now().toString(36) + "-" + Math.random().toString(36).slice(2);
        const items = records.filter(function (e) {
            return e.id !== item.id;
        });
        items.push(item);
        previewRecords = items;
        return item.id;
    }
    function remove(id) {
        if (id.startsWith("android:"))
            return platform && platform.removeSystemEvent(id);
        if (backend)
            return backend.remove(id);
        previewRecords = records.filter(e => e.id !== id);
        return true;
    }
    function newRecord(date, minute, duration) {
        const start = minute === undefined ? 540 : Math.max(0, Math.min(1410, minute));
        return {
            id: "",
            title: "",
            dateKey: Logic.key(date),
            endDateKey: Logic.key(date),
            startMinute: start,
            endMinute: Math.min(1440, start + (duration || 60)),
            allDay: false,
            category: "personal",
            location: "",
            description: "",
            important: false,
            reminder: -1,
            repeat: "none",
            repeatUntil: ""
        };
    }
    function addSamples(date) {
        if (!ready)
            return;
        const items = records.slice();
        const samples = [["Project meeting", 0, 540, 630, "work"], ["Study session", 0, 600, 690, "study"], ["Project deadline", 1, 0, 1440, "work"], ["Team planning", 2, 840, 930, "personal"]];
        for (let i = 0; i < samples.length; i++) {
            const s = samples[i], e = newRecord(Dates.addDays(date, s[1]));
            e.id = "sample-" + Date.now() + "-" + i;
            e.title = L.tr(s[0], Qt.uiLanguage);
            e.startMinute = s[2];
            e.endMinute = s[3];
            e.category = s[4];
            e.allDay = s[2] === 0 && s[3] === 1440;
            e.important = e.allDay;
            items.push(e);
        }
        if (backend) {
            for (let i = items.length - samples.length; i < items.length; ++i)
                backend.save(items[i]);
        } else {
            previewRecords = items;
        }
    }
}
