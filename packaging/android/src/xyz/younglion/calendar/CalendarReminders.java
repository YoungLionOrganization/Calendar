// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
package xyz.younglion.calendar;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import org.json.JSONArray;
import org.json.JSONObject;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.DateTimeException;

public final class CalendarReminders extends BroadcastReceiver {
    private static final String FIRE = "xyz.younglion.calendar.REMINDER";
    private static final String CHANNEL = "events";

    private static SharedPreferences preferences(Context context) {
        return context.getSharedPreferences("CalendarReminders", Context.MODE_PRIVATE);
    }

    static boolean enabled(Context context) {
        return preferences(context).getBoolean("enabled", false);
    }

    static void update(Context context, String records) {
        preferences(context).edit().putString("records", records).apply();
        schedule(context);
    }

    static void setEnabled(Context context, boolean enabled) {
        preferences(context).edit().putBoolean("enabled", enabled).apply();
        schedule(context);
    }

    private static boolean occurs(JSONObject event, LocalDate day, LocalDate start) {
        if (day.isBefore(start)) return false;
        String until = event.optString("repeatUntil");
        if (!until.isEmpty() && day.toString().compareTo(until) > 0) return false;
        JSONArray excluded = event.optJSONArray("excludedDates");
        if (excluded != null)
            for (int i = 0; i < excluded.length(); ++i)
                if (day.toString().equals(excluded.optString(i))) return false;
        switch (event.optString("repeat")) {
        case "daily": return true;
        case "weekly":
            JSONArray days = event.optJSONArray("weekdays");
            if (days == null || days.length() == 0) return day.getDayOfWeek() == start.getDayOfWeek();
            for (int i = 0; i < days.length(); ++i)
                if (days.optInt(i) == day.getDayOfWeek().getValue()) return true;
            return false;
        case "monthly": return day.getDayOfMonth() == start.getDayOfMonth();
        case "yearly": return day.getMonth() == start.getMonth()
                && day.getDayOfMonth() == start.getDayOfMonth();
        default: return day.equals(start);
        }
    }

    private static synchronized void schedule(Context context) {
        AlarmManager alarms = context.getSystemService(AlarmManager.class);
        Intent signal = new Intent(context, CalendarReminders.class).setAction(FIRE);
        PendingIntent old = PendingIntent.getBroadcast(context, 1, signal,
                PendingIntent.FLAG_NO_CREATE | PendingIntent.FLAG_IMMUTABLE);
        if (old != null) alarms.cancel(old);
        if (!enabled(context)) return;

        long next = Long.MAX_VALUE;
        java.util.LinkedHashMap<String, String> events = new java.util.LinkedHashMap<>();
        try {
            JSONArray records = new JSONArray(preferences(context).getString("records", "[]"));
            Instant now = Instant.now();
            for (int index = 0; index < records.length(); ++index) {
                JSONObject event = records.getJSONObject(index);
                LocalDate start = LocalDate.parse(event.getString("dateKey"));
                ZoneId zone = ZoneId.systemDefault();
                String zoneName = event.optString("timeZone");
                if (!zoneName.isEmpty() && !event.optBoolean("allDay"))
                    try { zone = ZoneId.of(zoneName); } catch (DateTimeException ignored) { }
                JSONArray reminders = event.optJSONArray("reminders");
                if (reminders == null) reminders = new JSONArray().put(event.optInt("reminder", -1));
                for (int i = 0; i < reminders.length(); ++i) {
                    int before = reminders.optInt(i, -1);
                    if (before < 0 || before > 525600) continue;
                    LocalDate first = now.atZone(zone).toLocalDate().plusDays(before / 1440 - 1L);
                    if (first.isBefore(start)) first = start;
                    LocalDate last = event.optString("repeat").equals("none") ? first : first.plusYears(4).plusDays(1);
                    for (LocalDate day = first; !day.isAfter(last); day = day.plusDays(1)) {
                        if (!occurs(event, day, start)) continue;
                        LocalTime time = LocalTime.MIDNIGHT.plusMinutes(event.optInt("startMinute"));
                        Instant due = ZonedDateTime.of(day, time, zone).toInstant().minusSeconds(before * 60L);
                        if (!due.isAfter(now)) continue;
                        if (due.toEpochMilli() < next) {
                            next = due.toEpochMilli();
                            events.clear();
                        }
                        if (due.toEpochMilli() == next)
                            events.put(event.optString("id"), event.optString("title"));
                        break;
                    }
                }
            }
        } catch (org.json.JSONException | DateTimeException invalid) {
            android.util.Log.w("YoungLionCalendar", "Could not read reminder records", invalid);
        }
        if (next == Long.MAX_VALUE) return;
        signal.putExtra("events", new JSONObject(events).toString());
        PendingIntent action = PendingIntent.getBroadcast(context, 1, signal,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
            try {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, action);
                return;
            } catch (SecurityException revoked) {
                // Permission may be revoked between checking it and scheduling.
            }
        }
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, action);
    }

    @Override public void onReceive(Context context, Intent intent) {
        if (FIRE.equals(intent.getAction()) && enabled(context)) {
            NotificationManager manager = context.getSystemService(NotificationManager.class);
            manager.createNotificationChannel(new NotificationChannel(CHANNEL, "Calendar events",
                    NotificationManager.IMPORTANCE_DEFAULT));
            if (manager.areNotificationsEnabled()) {
                try {
                    JSONObject events = new JSONObject(intent.getStringExtra("events"));
                    java.util.Iterator<String> ids = events.keys();
                    while (ids.hasNext()) {
                        String id = ids.next();
                        Intent open = new Intent(context, CalendarActivity.class)
                                .setAction(Intent.ACTION_VIEW)
                                .setData(android.net.Uri.fromParts("event", id, null))
                                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP)
                                .putExtra("event", id);
                        PendingIntent destination = PendingIntent.getActivity(context, 1, open,
                                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                        Notification notification = new Notification.Builder(context, CHANNEL)
                                .setSmallIcon(android.R.drawable.ic_menu_my_calendar)
                                .setContentTitle(events.optString(id))
                                .setContentIntent(destination)
                                .setAutoCancel(true).build();
                        manager.notify(id, 1, notification);
                    }
                } catch (org.json.JSONException invalid) {
                    android.util.Log.w("YoungLionCalendar", "Invalid reminder payload", invalid);
                }
            }
        }
        schedule(context);
    }
}
