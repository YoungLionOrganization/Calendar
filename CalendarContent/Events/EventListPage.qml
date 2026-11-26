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
    property var records: []
    property bool importantOnly: false
    signal eventRequested(string eventId)
    titleText: importantOnly ? L.tr("Important days", Qt.uiLanguage) : L.tr("Search events", Qt.uiLanguage)
    readonly property var categoryKeys: ["all"].concat(Logic.categories())
    readonly property var filtered: Logic.search(records, query.text, categoryKeys[Math.max(0, category.currentIndex)], importantOnly)
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.pagePadding
        spacing: Constants.spacingSm
        Common.CalendarTextField {
            id: query
            Layout.fillWidth: true
            placeholderText: L.tr("Search title, location or notes", Qt.uiLanguage)
            Accessible.name: placeholderText
        }
        Common.CalendarComboBox {
            id: category
            Layout.fillWidth: true
            model: [L.tr("All categories", Qt.uiLanguage)].concat(Logic.categories().map(function (c) {
                return L.tr(Logic.categoryLabel(c), Qt.uiLanguage);
            }))
        }
        ListView {
            id: results
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true
            model: root.filtered
            spacing: Constants.spacingXs
            reuseItems: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            delegate: ItemDelegate {
                id: result
                required property var modelData
                width: results.width
                text: modelData.title + "\n" + Qt.locale(Qt.uiLanguage).toString(Logic.date(modelData.dateKey), "d MMM yyyy") + " · " + L.tr(Logic.categoryLabel(modelData.category), Qt.uiLanguage)
                onClicked: root.eventRequested(modelData.id)
                hoverEnabled: true
                font.family: Constants.fontFamily
                font.pixelSize: Constants.fontSizeBody
                palette.text: Constants.textPrimary
                background: Common.ControlSurface {
                    target: result
                    hovered: result.hovered
                    fill: result.down ? Constants.surfacePressed : result.hovered ? Constants.surfaceHover : Constants.surfaceSecondary
                }
            }
            Label {
                anchors.centerIn: parent
                visible: results.count === 0
                width: parent.width
                text: L.tr("No matching events", Qt.uiLanguage)
                color: Constants.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
