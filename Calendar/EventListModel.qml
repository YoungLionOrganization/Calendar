// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick

ListModel {
    id: eventListModel

    ListElement {
        eventId: "enterPressed"
        eventDescription: "Emitted when pressing the enter button"
        shortcut: "Return"
        parameters: "Enter"
    }
}
