// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Components" as Common
import "EventLogic.mjs" as Logic
import "../Shared/I18n.js" as L

Common.PageShell {
    id: root
    required property var record
    property bool canEditOccurrence: false
    signal editOccurrenceRequested
    signal editRequested
    signal duplicateRequested
    signal deleteRequested
    signal importantRequested
    titleText: L.tr("Event", Qt.uiLanguage)
    actionText: record.readOnly ? "" : L.tr("Edit", Qt.uiLanguage)
    onActionRequested: editRequested()
    Common.CalendarDialog {
        id: confirm
        parent: Overlay.overlay
        anchors.centerIn: parent
        title: L.tr("Delete event?", Qt.uiLanguage)
        width: Math.max(1, Math.min(root.width - 2 * Constants.spacingSm, Constants.dialogPreferredWidth))
        contentItem: Label {
            text: L.tr("This deletes the event and all its repetitions.", Qt.uiLanguage)
            wrapMode: Text.WordWrap
            color: Constants.textPrimary
        }
        footer: DialogButtonBox {
            Common.CalendarButton {
                text: L.tr("Cancel", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            Common.CalendarButton {
                destructive: true
                text: L.tr("Delete", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        onAccepted: root.deleteRequested()
    }
    Flickable {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: column.height + 2 * Constants.pagePadding
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        ColumnLayout {
            id: column
            width: Math.max(0, Math.min(scroll.width - 2 * Constants.pagePadding, Constants.formMaxWidth))
            x: (scroll.width - width) / 2
            y: Constants.pagePadding
            spacing: Constants.spacingLg
            Label {
                Layout.fillWidth: true
                text: root.record.title
                textFormat: Text.PlainText
                font.family: Constants.fontFamily
                font.pixelSize: Constants.fontSizePageTitle
                font.weight: Constants.fontWeightBold
                color: Constants.textPrimary
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: L.tr(Logic.categoryLabel(root.record.category), Qt.uiLanguage)
                color: Constants.primary
                font.pixelSize: Constants.fontSizeMd
            }
            Common.SectionLabel {
                text: L.tr("Date and time", Qt.uiLanguage)
            }
            Label {
                Layout.fillWidth: true
                text: Qt.locale(Qt.uiLanguage).toString(Logic.date(root.record.dateKey), "dddd, d MMMM yyyy") + (root.record.endDateKey !== root.record.dateKey ? " – " + Qt.locale(Qt.uiLanguage).toString(Logic.date(root.record.endDateKey), "d MMMM yyyy") : "")
                wrapMode: Text.WordWrap
                color: Constants.textPrimary
            }
            Label {
                Layout.fillWidth: true
                text: root.record.allDay ? L.tr("All day", Qt.uiLanguage) : Logic.time(root.record.startMinute) + " – " + Logic.time(root.record.endMinute)
                color: Constants.textSecondary
            }
            Common.SectionLabel {
                text: L.tr("Repeat and reminder", Qt.uiLanguage)
            }
            Label {
                Layout.fillWidth: true
                text: L.tr(({
                        none: "Does not repeat",
                        daily: "Daily",
                        weekly: "Weekly",
                        monthly: "Monthly",
                        yearly: "Yearly"
                    })[root.record.repeat] || "Does not repeat", Qt.uiLanguage) + (root.record.repeatUntil ? " · " + L.tr("Repeat until", Qt.uiLanguage) + " " + Qt.locale(Qt.uiLanguage).toString(Logic.date(root.record.repeatUntil), "d MMM yyyy") : "")
                color: Constants.textPrimary
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: L.tr(({
                        "-1": "No reminder",
                        "0": "At event time",
                        "5": "5 minutes before",
                        "10": "10 minutes before",
                        "15": "15 minutes before",
                        "30": "30 minutes before",
                        "60": "1 hour before",
                        "1440": "1 day before"
                    })[String(root.record.reminder)] || "No reminder", Qt.uiLanguage)
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                visible: root.record.repeat !== "none"
                text: L.tr("Repeating event — changes apply to the entire series.", Qt.uiLanguage)
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
            }
            Common.SectionLabel {
                visible: !!root.record.location
                text: L.tr("Location", Qt.uiLanguage)
            }
            Label {
                Layout.fillWidth: true
                visible: !!root.record.location
                text: root.record.location || ""
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Constants.textPrimary
            }
            Common.SectionLabel {
                visible: !!root.record.description
                text: L.tr("Description", Qt.uiLanguage)
            }
            Label {
                Layout.fillWidth: true
                visible: !!root.record.description
                text: root.record.description || ""
                wrapMode: Text.WordWrap
                color: Constants.textPrimary
                textFormat: Text.PlainText
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                visible: root.canEditOccurrence
                text: L.tr("Edit this occurrence", Qt.uiLanguage)
                onClicked: root.editOccurrenceRequested()
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                text: root.record.important ? L.tr("Remove from important days", Qt.uiLanguage) : L.tr("Mark as important", Qt.uiLanguage)
                visible: !String(root.record.id || "").startsWith("android:")
                onClicked: root.importantRequested()
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                text: L.tr("Duplicate", Qt.uiLanguage)
                onClicked: root.duplicateRequested()
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                visible: !root.record.readOnly
                destructive: true
                text: L.tr("Delete", Qt.uiLanguage)
                onClicked: confirm.open()
            }
        }
    }
}
