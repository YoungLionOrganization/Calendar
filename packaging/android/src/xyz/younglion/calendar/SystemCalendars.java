// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
package xyz.younglion.calendar;

import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.provider.CalendarContract.Calendars;
import android.provider.CalendarContract.Events;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

final class SystemCalendars {
    static String list(Context context) {
        JSONArray calendars = new JSONArray();
        String[] columns = {Calendars._ID, Calendars.CALENDAR_DISPLAY_NAME,
                Calendars.CALENDAR_ACCESS_LEVEL, Calendars.CALENDAR_COLOR};
        try (Cursor cursor = context.getContentResolver().query(Calendars.CONTENT_URI,
                columns, null, null, Calendars.CALENDAR_DISPLAY_NAME)) {
            while (cursor != null && cursor.moveToNext()) {
                calendars.put(new JSONObject()
                        .put("id", cursor.getString(0))
                        .put("title", cursor.getString(1))
                        .put("writable", cursor.getInt(2) >= Calendars.CAL_ACCESS_CONTRIBUTOR)
                        .put("color", String.format("#%06x", cursor.getInt(3) & 0xffffff)));
            }
        } catch (JSONException | SecurityException error) {
            return "[]";
        }
        return calendars.toString();
    }

    static String read(Context context, String calendarId) {
        JSONArray records = new JSONArray();
        if (calendarId.isEmpty()) return records.toString();
        boolean writable = false;
        boolean found = false;
        try {
            JSONArray calendars = new JSONArray(list(context));
            for (int i = 0; i < calendars.length(); ++i) {
                JSONObject calendar = calendars.getJSONObject(i);
                if (calendarId.equals(calendar.getString("id"))) {
                    found = true;
                    writable = calendar.getBoolean("writable");
                    break;
                }
            }
            if (!found) return "[]";
        } catch (JSONException error) {
            return "[]";
        }

        String[] columns = {Events._ID, Events.TITLE, Events.DTSTART, Events.DTEND,
                Events.ALL_DAY, Events.EVENT_TIMEZONE, Events.EVENT_LOCATION, Events.DESCRIPTION,
                Events.RRULE, Events.DURATION, Events.RDATE, Events.EXDATE, Events.ORIGINAL_ID};
        try (Cursor cursor = context.getContentResolver().query(Events.CONTENT_URI,
                columns, Events.CALENDAR_ID + " = ? AND " + Events.DELETED + " = 0",
                new String[]{calendarId}, Events.DTSTART)) {
            while (cursor != null && cursor.moveToNext()) {
                if (cursor.isNull(2)) continue;
                boolean allDay = cursor.getInt(4) != 0;
                ZoneId zone = allDay ? ZoneOffset.UTC : ZoneId.systemDefault();
                try { if (!allDay && !cursor.isNull(5)) zone = ZoneId.of(cursor.getString(5)); }
                catch (java.time.DateTimeException ignored) { }
                ZonedDateTime start = Instant.ofEpochMilli(cursor.getLong(2)).atZone(zone);
                ZonedDateTime end = cursor.isNull(3) ? start.plusHours(allDay ? 24 : 1)
                        : Instant.ofEpochMilli(cursor.getLong(3)).atZone(zone);
                if (cursor.isNull(3) && !cursor.isNull(9)) {
                    try { end = start.plus(java.time.Duration.parse(cursor.getString(9))); }
                    catch (java.time.DateTimeException badDuration) { }
                }
                int endMinutes = end.getHour() * 60 + end.getMinute();
                if ((allDay || endMinutes == 0) && end.toLocalDate().isAfter(start.toLocalDate())) {
                    end = end.minusDays(1);
                    endMinutes = 1440;
                }
                String rule = cursor.getString(8);
                boolean special = rule != null || !cursor.isNull(10) || !cursor.isNull(11) || !cursor.isNull(12);
                String repeat = "none";
                if (rule != null) {
                    if (rule.equals("FREQ=DAILY")) repeat = "daily";
                    if (rule.equals("FREQ=WEEKLY")) repeat = "weekly";
                    if (rule.equals("FREQ=MONTHLY")) repeat = "monthly";
                    if (rule.equals("FREQ=YEARLY")) repeat = "yearly";
                }
                String title = cursor.getString(1);
                records.put(new JSONObject().put("id", "android:" + cursor.getString(0))
                        .put("calendarId", "android-calendar:" + calendarId)
                        .put("readOnly", !writable || special)
                        .put("title", title == null || title.isEmpty() ? "Calendar event" : title)
                        .put("dateKey", start.toLocalDate()).put("endDateKey", end.toLocalDate())
                        .put("allDay", allDay).put("startMinute", allDay ? 0 : start.getHour() * 60 + start.getMinute())
                        .put("endMinute", allDay ? 1440 : endMinutes).put("timeZone", zone.getId())
                        .put("category", "other").put("repeat", repeat).put("reminder", -1)
                        .put("location", cursor.getString(6)).put("description", cursor.getString(7)));
            }
        } catch (JSONException | SecurityException error) {
            return "[]";
        }
        return records.toString();
    }

    static boolean update(Context context, String json) {
        try {
            JSONObject record = new JSONObject(json);
            if (record.optBoolean("readOnly")) return false;
            long id = Long.parseLong(record.getString("id").replaceFirst("^android:", ""));
            boolean allDay = record.optBoolean("allDay");
            String timezone = record.optString("timeZone", "");
            ZoneId zone = allDay ? ZoneOffset.UTC
                    : timezone.isEmpty() ? ZoneId.systemDefault() : ZoneId.of(timezone);
            long start = ZonedDateTime.of(LocalDate.parse(record.getString("dateKey")),
                    LocalTime.MIDNIGHT, zone).plusMinutes(record.optInt("startMinute")).toInstant().toEpochMilli();
            long end = ZonedDateTime.of(LocalDate.parse(record.getString("endDateKey")),
                    LocalTime.MIDNIGHT, zone).plusMinutes(record.optInt("endMinute")).toInstant().toEpochMilli();
            if (end <= start) return false;
            ContentValues values = new ContentValues();
            values.put(Events.TITLE, record.getString("title"));
            values.put(Events.EVENT_LOCATION, record.optString("location", ""));
            values.put(Events.DESCRIPTION, record.optString("description", ""));
            values.put(Events.DTSTART, start);
            values.put(Events.DTEND, end);
            values.put(Events.ALL_DAY, allDay ? 1 : 0);
            values.put(Events.EVENT_TIMEZONE, allDay ? "UTC" : zone.getId());
            return context.getContentResolver().update(ContentUris.withAppendedId(Events.CONTENT_URI, id),
                    values, null, null) == 1;
        } catch (JSONException | RuntimeException error) {
            return false;
        }
    }

    static boolean delete(Context context, String key) {
        try {
            long id = Long.parseLong(key.replaceFirst("^android:", ""));
            return context.getContentResolver().delete(ContentUris.withAppendedId(Events.CONTENT_URI, id),
                    null, null) == 1;
        } catch (RuntimeException error) {
            return false;
        }
    }

    private SystemCalendars() { }
}
