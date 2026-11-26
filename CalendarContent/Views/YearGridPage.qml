// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Flickable {
    id: yearScroll
    property int pagePeriod: 2026
    property var referenceDate: new Date()
    signal monthSelected(int monthIndex)
    clip: true
    contentWidth: width
    contentHeight: Math.max(0, grid.rows * grid.tileHeight + (grid.rows - 1) * grid.rowGap)
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    Item {
        id: grid
        width: yearScroll.width
        height: yearScroll.contentHeight
        readonly property int columns: width < Constants.breakpointPhone ? 3 : width < Constants.breakpointDesktop ? 4 : 6
        readonly property int rows: Math.ceil(12 / columns)
        readonly property real columnGap: Constants.spacingMd
        readonly property real rowGap: Constants.spacingLg
        readonly property real tileWidth: Math.max(0, (width - (columns - 1) * columnGap) / columns)
        readonly property real minimumTileHeight: Constants.fontSizeLg + Constants.spacingSm + (Constants.fontSizeXs + Constants.spacing2xs) * 7 + Constants.spacingXs
        readonly property real tileHeight: Math.max(minimumTileHeight, (yearScroll.height - (rows - 1) * rowGap) / rows)
        Repeater {
            model: 12
            YearMonthItem {
                required property int index
                x: (index % grid.columns) * (grid.tileWidth + grid.columnGap)
                y: Math.floor(index / grid.columns) * (grid.tileHeight + grid.rowGap)
                width: grid.tileWidth
                height: grid.tileHeight
                monthIndex: index
                yearNumber: yearScroll.pagePeriod
                referenceDate: yearScroll.referenceDate
                onMonthSelected: function (monthIndex) {
                    yearScroll.monthSelected(monthIndex);
                }
            }
        }
    }
}
