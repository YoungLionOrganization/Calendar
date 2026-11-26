// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#include "EventDatabase.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QFile>
#include <QSaveFile>
#include <memory>
#include <libical/ical.h>
#if ICAL_MAJOR_VERSION < 4
#define icaldurationtype_as_seconds icaldurationtype_as_int
#define icaldurationtype_from_seconds icaldurationtype_from_int
#endif

namespace {
using Component = std::unique_ptr<icalcomponent, decltype(&icalcomponent_free)>;

QString string(const char *value)
{
    return QString::fromUtf8(value ? value : "");
}

QString propertyText(icalcomponent *event, icalproperty_kind kind)
{
    const auto property = icalcomponent_get_first_property(event, kind);
    return property ? string(icalproperty_get_value_as_string(property)) : QString();
}

QDate date(const icaltimetype &time)
{
    return QDate(time.year, time.month, time.day);
}

QString repeatName(const QString &rule)
{
    if (rule.isEmpty())
        return "none";
    const auto parts = rule.split(';');
    QHash<QString, QString> properties;
    for (const auto &part : parts) {
        const auto separator = part.indexOf('=');
        if (separator < 1 || properties.contains(part.left(separator)))
            return "none";
        properties.insert(part.left(separator), part.mid(separator + 1));
    }
    const auto frequency = properties.take("FREQ");
    const auto until = properties.take("UNTIL");
    if (!until.isEmpty() && !QDate::fromString(until.left(8), "yyyyMMdd").isValid())
        return "none";
    if (properties.contains("BYDAY")) {
        const QStringList weekdays{"MO", "TU", "WE", "TH", "FR", "SA", "SU"};
        if (frequency != "WEEKLY")
            return "none";
        for (const auto &day : properties.take("BYDAY").split(','))
            if (!weekdays.contains(day))
                return "none";
    }
    if (!properties.isEmpty())
        return "none";
    if (frequency == "DAILY" || frequency == "WEEKLY"
        || frequency == "MONTHLY" || frequency == "YEARLY")
        return frequency.toLower();
    return "none";
}

icaltimetype dateTime(const QVariantMap &record, const char *dayKey, const char *minuteKey)
{
    auto day = QDate::fromString(record.value(dayKey).toString(), Qt::ISODate);
    int minutes = record.value(minuteKey).toInt();
    const bool allDay = record.value("allDay").toBool();
    if ((allDay && qstrcmp(dayKey, "endDateKey") == 0) || minutes == 1440) {
        day = day.addDays(1);
        minutes = 0;
    }
    icaltimetype time = icaltime_null_time();
    time.year = day.year();
    time.month = day.month();
    time.day = day.day();
    time.is_date = allDay;
    if (!allDay) {
        time.hour = minutes / 60;
        time.minute = minutes % 60;
        if (record.value("timeZone").toString() == "UTC")
            time.zone = icaltimezone_get_utc_timezone();
    }
    return time;
}

void setDateTime(icalcomponent *event, icalproperty *property, const QVariantMap &record)
{
    const auto zone = record.value("timeZone").toString().toUtf8();
    if (!record.value("allDay").toBool() && !zone.isEmpty() && zone != "UTC")
        icalproperty_add_parameter(property, icalparameter_new_tzid(zone.constData()));
    icalcomponent_add_property(event, property);
}
}

QVariantList EventDatabase::decodeCalendar(const QUrl &url)
{
    const auto filename = url.isLocalFile() ? url.toLocalFile() : url.toString();
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly) || file.size() > 32 * 1024 * 1024) {
        reportError(tr("Could not open the calendar file or the file is too large."));
        return {};
    }
    const auto bytes = file.read(32 * 1024 * 1024 + 1);
    Component calendar(icalparser_parse_string(bytes.constData()), icalcomponent_free);
    if (!calendar || icalcomponent_isa(calendar.get()) != ICAL_VCALENDAR_COMPONENT
        || icalcomponent_count_errors(calendar.get()) != 0) {
        reportError(tr("The file is not a valid iCalendar file."));
        return {};
    }

    QByteArray timezones;
    for (auto *zone = icalcomponent_get_first_component(calendar.get(), ICAL_VTIMEZONE_COMPONENT);
         zone; zone = icalcomponent_get_next_component(calendar.get(), ICAL_VTIMEZONE_COMPONENT))
        timezones += icalcomponent_as_ical_string(zone);

    QVariantList records;
    for (auto *event = icalcomponent_get_first_component(calendar.get(), ICAL_VEVENT_COMPONENT);
         event; event = icalcomponent_get_next_component(calendar.get(), ICAL_VEVENT_COMPONENT)) {
        const auto start = icalcomponent_get_dtstart(event);
        const auto finish = icalcomponent_get_dtend(event);
        const auto uid = propertyText(event, ICAL_UID_PROPERTY);
        const auto recurrenceId = propertyText(event, ICAL_RECURRENCEID_PROPERTY);
        if (!date(start).isValid() || uid.isEmpty()) {
            reportError(tr("An event is missing its start date or UID."));
            return {};
        }
        const auto id = QCryptographicHash::hash(uid.toUtf8() + '\0' + recurrenceId.toUtf8(),
                                                QCryptographicHash::Sha256).toHex();

        const bool allDay = start.is_date;
        const int startMinute = allDay ? 0 : start.hour * 60 + start.minute;
        auto endDate = date(finish);
        int endMinute = allDay ? 1440 : finish.hour * 60 + finish.minute;
        if (!endDate.isValid()) {
            endDate = date(start);
            endMinute = allDay ? 1440 : qMin(startMinute + 60, 1440);
        } else if (endDate > date(start) && (allDay || endMinute == 0)) {
            endDate = endDate.addDays(-1);
            endMinute = 1440;
        }

        QString zone = icaltime_is_utc(start) ? "UTC" : "";
        if (auto *dtstart = icalcomponent_get_first_property(event, ICAL_DTSTART_PROPERTY))
            if (auto *parameter = icalproperty_get_first_parameter(dtstart, ICAL_TZID_PARAMETER))
                zone = string(icalparameter_get_tzid(parameter));
        const auto rule = propertyText(event, ICAL_RRULE_PROPERTY);
        const auto frequency = repeatName(rule);
        const auto title = string(icalcomponent_get_summary(event)).trimmed();
        QString repeatUntil;
        QVariantList weekdays;
        for (const auto &part : rule.split(';')) {
            if (part.startsWith("UNTIL="))
                repeatUntil = QDate::fromString(part.mid(6, 8), "yyyyMMdd").toString(Qt::ISODate);
            if (part.startsWith("BYDAY=")) {
                const QStringList names = {"MO", "TU", "WE", "TH", "FR", "SA", "SU"};
                for (const auto &weekday : part.mid(6).split(','))
                    if (names.contains(weekday))
                        weekdays.append(names.indexOf(weekday) + 1);
            }
        }
        QVariantList excluded;
        for (auto *property = icalcomponent_get_first_property(event, ICAL_EXDATE_PROPERTY);
             property; property = icalcomponent_get_next_property(event, ICAL_EXDATE_PROPERTY))
            excluded.append(date(icalproperty_get_exdate(property)).toString(Qt::ISODate));

        QVariantList reminders;
        for (auto *alarm = icalcomponent_get_first_component(event, ICAL_VALARM_COMPONENT);
             alarm; alarm = icalcomponent_get_next_component(event, ICAL_VALARM_COMPONENT)) {
            auto *property = icalcomponent_get_first_property(alarm, ICAL_TRIGGER_PROPERTY);
            if (!property || icalproperty_get_first_parameter(property, ICAL_RELATED_PARAMETER))
                continue;
            const auto trigger = icalproperty_get_trigger(property);
            const int seconds = icaldurationtype_as_seconds(trigger.duration);
            if (icaltime_is_null_time(trigger.time) && seconds <= 0 && seconds % 60 == 0)
                reminders.append(-seconds / 60);
        }

        QVariantMap record {
            {"id", "ics-" + QString::fromLatin1(id)}, {"icsUid", uid}, {"icsRecurrenceId", recurrenceId},
            {"title", title.isEmpty() ? tr("Untitled event") : title},
            {"dateKey", date(start).toString(Qt::ISODate)}, {"endDateKey", endDate.toString(Qt::ISODate)},
            {"startMinute", startMinute}, {"endMinute", endMinute},
            {"allDay", allDay}, {"timeZone", zone}, {"category", "other"},
            {"location", string(icalcomponent_get_location(event))}, {"description", string(icalcomponent_get_description(event))},
            {"important", false}, {"reminder", reminders.isEmpty() ? -1 : reminders.first().toInt()},
            {"reminders", reminders}, {"weekdays", weekdays}, {"excludedDates", excluded},
            {"repeat", frequency}, {"repeatUntil", repeatUntil}, {"rawRule", rule},
            {"rawEvent", string(icalcomponent_as_ical_string(event))}, {"rawZones", QString::fromUtf8(timezones)}
        };
        records.append(record);
    }
    // A detached occurrence supersedes the original instance of the same series.
    QHash<QString, QVariantList> exceptions;
    for (const auto &item : std::as_const(records)) {
        const auto record = item.toMap();
        const auto day = QDate::fromString(record.value("icsRecurrenceId").toString().left(8), "yyyyMMdd");
        if (day.isValid())
            exceptions[record.value("icsUid").toString()].append(day.toString(Qt::ISODate));
    }
    for (auto &item : records) {
        auto record = item.toMap();
        if (!record.value("icsRecurrenceId").toString().isEmpty())
            continue;
        const auto extra = exceptions.value(record.value("icsUid").toString());
        if (extra.isEmpty())
            continue;
        auto excluded = record.value("excludedDates").toList();
        excluded.append(extra);
        record["excludedDates"] = excluded;
        item = record;
    }
    return records;
}

bool EventDatabase::exportCalendar(const QUrl &url)
{
    if (!m_ready)
        return false;
    QSaveFile file(url.isLocalFile() ? url.toLocalFile() : url.toString());
    file.setDirectWriteFallback(url.scheme() == "content");
    if (!file.open(QIODevice::WriteOnly))
        return reportError(file.errorString());

    QByteArray output = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//YoungLion//Calendar//EN\r\n";
    QSet<QByteArray> zones;
    for (const auto &item : std::as_const(m_records)) {
        const auto record = item.toMap();
        const auto rawZones = record.value("rawZones").toString().toUtf8();
        if (!rawZones.isEmpty() && !zones.contains(rawZones)) {
            output += rawZones;
            zones.insert(rawZones);
        }
        const auto raw = record.value("rawEvent").toString().toUtf8();
        if (!raw.isEmpty()) {
            output += raw;
            continue;
        }
        Component event(icalcomponent_new_vevent(), icalcomponent_free);
        auto uid = record.value("icsUid").toString();
        if (uid.isEmpty())
            uid = record.value("id").toString() + "@younglion.xyz";
        icalcomponent_set_uid(event.get(), uid.toUtf8().constData());
        icalcomponent_set_summary(event.get(), record.value("title").toString().toUtf8().constData());
        icalcomponent_set_location(event.get(), record.value("location").toString().toUtf8().constData());
        icalcomponent_set_description(event.get(), record.value("description").toString().toUtf8().constData());
        icalcomponent_set_dtstamp(event.get(), icaltime_current_time_with_zone(icaltimezone_get_utc_timezone()));
        setDateTime(event.get(), icalproperty_new_dtstart(dateTime(record, "dateKey", "startMinute")), record);
        setDateTime(event.get(), icalproperty_new_dtend(dateTime(record, "endDateKey", "endMinute")), record);
        auto rule = record.value("rawRule").toString();
        const auto frequency = record.value("repeat").toString();
        if (rule.isEmpty() && !frequency.isEmpty() && frequency != "none") {
            rule = "FREQ=" + frequency.toUpper();
            const auto until = QDate::fromString(record.value("repeatUntil").toString(), Qt::ISODate);
            if (until.isValid())
                rule += ";UNTIL=" + until.toString("yyyyMMdd")
                        + (record.value("allDay").toBool() ? "" : "T235959");
            const QStringList names = {"MO", "TU", "WE", "TH", "FR", "SA", "SU"};
            QStringList days;
            if (frequency == "weekly")
                for (const auto &day : record.value("weekdays").toList())
                    if (day.toInt() >= 1 && day.toInt() <= 7)
                        days.append(names.at(day.toInt() - 1));
            if (!days.isEmpty())
                rule += ";BYDAY=" + days.join(',');
        }
        if (!rule.isEmpty()) {
            const auto property = "RRULE:" + rule.toUtf8();
            if (auto *recurrence = icalproperty_new_from_string(property.constData()))
                icalcomponent_add_property(event.get(), recurrence);
        }
        for (const auto &day : record.value("excludedDates").toList()) {
            auto occurrence = record;
            occurrence["dateKey"] = day;
            setDateTime(event.get(), icalproperty_new_exdate(dateTime(occurrence, "dateKey", "startMinute")), record);
        }
        for (const auto &reminder : record.value("reminders", QVariantList{record.value("reminder", -1)}).toList()) {
            const int minutes = reminder.toInt();
            if (minutes < 0 || minutes > 525600)
                continue;
            auto *alarm = icalcomponent_new_valarm();
            icalcomponent_add_property(alarm, icalproperty_new_action(ICAL_ACTION_DISPLAY));
            icalcomponent_add_property(alarm, icalproperty_new_description(record.value("title").toString().toUtf8().constData()));
            icaltriggertype trigger{};
            trigger.duration = icaldurationtype_from_seconds(-minutes * 60);
            icalcomponent_add_property(alarm, icalproperty_new_trigger(trigger));
            icalcomponent_add_component(event.get(), alarm);
        }
        output += icalcomponent_as_ical_string(event.get());
    }
    output += "END:VCALENDAR\r\n";
    if (file.write(output) != output.size() || !file.commit())
        return reportError(file.errorString());
    reportError({});
    return true;
}
