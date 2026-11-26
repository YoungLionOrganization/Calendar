// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

// Bounded sliding window: at most 25 lightweight slots, three live pages.
// The consumer owns the canonical period. A swipe requests a new period.
SwipeView {
    id: root
    required property int period
    required property int minimumPeriod
    required property int maximumPeriod
    required property Component pageDelegate
    signal periodRequested(int value)

    readonly property int slotCount: Math.min(25, maximumPeriod - minimumPeriod + 1)
    property int windowStart: minimumPeriod
    property bool ready: false
    property bool synchronizing: false
    property bool jumping: false

    padding: 0
    spacing: 0
    clip: true
    interactive: ready && !synchronizing

    function startFor(value) {
        return Math.max(minimumPeriod, Math.min(value - Math.floor(slotCount / 2), maximumPeriod - slotCount + 1));
    }
    function jumpTo(value) {
        synchronizing = true;
        jumping = true;
        pager.cancelFlick();
        windowStart = startFor(value);
        setCurrentIndex(value - windowStart);
        pager.positionViewAtIndex(currentIndex, ListView.Beginning);
        jumping = false;
        synchronizing = false;
    }
    function synchronize() {
        if (!ready || synchronizing)
            return;
        const target = Math.max(minimumPeriod, Math.min(maximumPeriod, period));
        const index = target - windowStart;
        if (index === currentIndex)
            return;
        if (index < 0 || index >= slotCount || Math.abs(index - currentIndex) > 1) {
            jumpTo(target);
        } else {
            synchronizing = true;
            setCurrentIndex(index);
            synchronizing = false;
        }
        deferredUpdate.restart();
    }
    function recenterIfNeeded() {
        if (!ready || synchronizing || pager.moving || currentIndex < 0)
            return;
        const value = windowStart + currentIndex;
        if (value !== period)
            return;
        if ((currentIndex <= 1 && windowStart > minimumPeriod) || (currentIndex >= slotCount - 2 && windowStart + slotCount - 1 < maximumPeriod)) {
            jumpTo(value);
        }
    }
    function step(offset) {
        const target = period + offset;
        if (target < minimumPeriod || target > maximumPeriod)
            return;
        // Requests from buttons use the same canonical state as a swipe.
        periodRequested(target);
    }
    function initialize() {
        if (ready || count !== slotCount)
            return;
        jumpTo(Math.max(minimumPeriod, Math.min(maximumPeriod, period)));
        ready = true;
    }
    Component.onCompleted: deferredUpdate.restart()
    onCountChanged: if (!ready)
        deferredUpdate.restart()
    onPeriodChanged: synchronize()
    onCurrentIndexChanged: deferredUpdate.restart()
    function commitCurrentPeriod() {
        if (!ready || synchronizing || pager.moving || currentIndex < 0)
            return;
        const value = windowStart + currentIndex;
        if (value !== period)
            periodRequested(value);
    }

    Timer {
        id: deferredUpdate
        interval: 0
        onTriggered: {
            if (root.ready) {
                root.commitCurrentPeriod();
                root.recenterIfNeeded();
            } else {
                root.initialize();
            }
        }
    }

    // Explicit paging geometry; no implicit-size feedback into the page.
    contentItem: ListView {
        id: pager
        model: root.contentModel
        currentIndex: root.currentIndex
        interactive: root.interactive
        focus: root.focus
        spacing: root.spacing
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        boundsBehavior: Flickable.StopAtBounds
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: 0
        highlightMoveDuration: root.jumping ? 0 : Constants.durationNormal
        maximumFlickVelocity: 4 * width
        onMovementEnded: deferredUpdate.restart()
    }
    Repeater {
        model: root.slotCount
        Loader {
            id: slot
            required property int index
            readonly property int pageValue: root.windowStart + index
            active: root.ready && (SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem)
            sourceComponent: root.pageDelegate
            Binding {
                target: slot.item
                property: "pagePeriod"
                value: slot.pageValue
                when: slot.item !== null
                restoreMode: Binding.RestoreNone
            }
        }
    }
}
