// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
package xyz.younglion.calendar;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import org.qtproject.qt.android.bindings.QtActivity;

public final class CalendarActivity extends QtActivity {
    private static native void deliverTarget(String target);
    private static native void calendarsChanged();
    private android.database.ContentObserver calendarObserver;

    public String activationTarget() {
        Intent intent = getIntent();
        if (intent == null) return "";
        String event = intent.getStringExtra("event");
        return event != null ? "event:" + event
                : intent.getData() != null ? intent.getData().toString() : "";
    }

    @Override protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        try {
            deliverTarget(activationTarget());
        } catch (UnsatisfiedLinkError ignored) {
            // Qt reads the activity's current intent when it starts.
        }
    }

    public void requestCalendars() {
        runOnUiThread(() -> {
            if (checkSelfPermission(Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED
                    || checkSelfPermission(Manifest.permission.WRITE_CALENDAR) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR}, 2);
            } else {
                watchCalendar();
                notifyCalendarChanged();
            }
        });
    }

    @Override public void onRequestPermissionsResult(int code, String[] permissions, int[] result) {
        super.onRequestPermissionsResult(code, permissions, result);
        if (code == 2) {
            watchCalendar();
            notifyCalendarChanged();
        }
    }

    @Override protected void onResume() {
        super.onResume();
        watchCalendar();
        notifyCalendarChanged();
    }

    @Override protected void onDestroy() {
        if (calendarObserver != null)
            getContentResolver().unregisterContentObserver(calendarObserver);
        super.onDestroy();
    }

    private void watchCalendar() {
        if (calendarObserver != null ||
                checkSelfPermission(Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED) return;
        calendarObserver = new android.database.ContentObserver(new android.os.Handler(getMainLooper())) {
            @Override public void onChange(boolean selfChange) { notifyCalendarChanged(); }
        };
        getContentResolver().registerContentObserver(android.provider.CalendarContract.Events.CONTENT_URI, true, calendarObserver);
        getContentResolver().registerContentObserver(android.provider.CalendarContract.Calendars.CONTENT_URI, true, calendarObserver);
    }

    private static void notifyCalendarChanged() {
        try { calendarsChanged(); } catch (UnsatisfiedLinkError ignored) { }
    }

    public String availableCalendars() { return SystemCalendars.list(this); }

    public String readCalendar(String id) { return SystemCalendars.read(this, id); }

    public boolean updateCalendarEvent(String record) { return SystemCalendars.update(this, record); }

    public boolean deleteCalendarEvent(String id) { return SystemCalendars.delete(this, id); }

    public void remindersChanged(String records) {
        CalendarReminders.update(this, records);
    }

    public boolean toggleReminders(boolean enabled) {
        runOnUiThread(() -> {
            if (enabled && Build.VERSION.SDK_INT >= 33
                    && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
                requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 1);
        });
        CalendarReminders.setEnabled(this, enabled);
        return true;
    }

    public void requestExactAlarm() {
        if (Build.VERSION.SDK_INT >= 31) {
            runOnUiThread(() -> startActivity(new Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    android.net.Uri.parse("package:" + getPackageName()))));
        }
    }

    public boolean remindersEnabled() {
        return CalendarReminders.enabled(this);
    }
}
