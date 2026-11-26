// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#include "EventDatabase.h"

#include <QDate>
#include <algorithm>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QSqlError>
#include <QSqlQuery>
#include <QTimeZone>
#include <QUuid>

namespace {
bool validRecord(const QVariantMap &record)
{
    const auto start = QDate::fromString(record.value("dateKey").toString(), Qt::ISODate);
    const auto end = QDate::fromString(record.value("endDateKey", record.value("dateKey")).toString(), Qt::ISODate);
    const int minutes = record.value("startMinute", -1).toInt();
    const int endMinutes = record.value("endMinute", -1).toInt();
    const auto zone = record.value("timeZone").toString();
    return !record.value("title").toString().trimmed().isEmpty()
        && start.isValid() && end.isValid() && start.year() >= 1900 && end.year() <= 2100
        && start.daysTo(end) >= 0 && start.daysTo(end) <= 365
        && minutes >= 0 && minutes < 1440 && endMinutes > 0 && endMinutes <= 1440
        && (start != end || minutes < endMinutes)
        && (zone.isEmpty() || QTimeZone(zone.toUtf8()).isValid() || !record.value("rawEvent").toString().isEmpty());
}
}

EventDatabase::EventDatabase(const QString &path, const QString &legacy, QObject *parent)
    : QAbstractListModel(parent),
      m_db(QSqlDatabase::addDatabase("QSQLITE", QUuid::createUuid().toString()))
{
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) {
        reportError(tr("Could not create the calendar data directory."));
        return;
    }
    m_db.setDatabaseName(path);
    m_db.setConnectOptions("QSQLITE_BUSY_TIMEOUT=3000");
    if (!m_db.open()) {
        reportError(m_db.lastError().text());
        return;
    }

    QSqlQuery query(m_db);
    for (const auto *sql : {
        "PRAGMA journal_mode=WAL",
        "CREATE TABLE IF NOT EXISTS events (id TEXT PRIMARY KEY NOT NULL, day TEXT NOT NULL, body BLOB NOT NULL)",
        "CREATE INDEX IF NOT EXISTS events_day ON events(day)",
        "CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY NOT NULL)"
    }) {
        if (!query.exec(QLatin1String(sql))) {
            reportError(query.lastError().text());
            return;
        }
    }
    m_ready = migrate(legacy) && reload();
}

EventDatabase::~EventDatabase()
{
    const auto name = m_db.connectionName();
    m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(name);
}

int EventDatabase::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_records.size();
}

QVariant EventDatabase::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || role != RecordRole || index.row() >= m_records.size())
        return {};
    return m_records.at(index.row());
}

QHash<int, QByteArray> EventDatabase::roleNames() const
{
    return {{RecordRole, "record"}};
}

bool EventDatabase::reportError(const QString &error)
{
    m_error = error;
    emit errorChanged();
    return false;
}

bool EventDatabase::migrate(const QString &legacy)
{
    if (!m_db.transaction())
        return reportError(m_db.lastError().text());

    auto rollback = [this](const QString &message) {
        m_db.rollback();
        return reportError(message);
    };
    QSqlQuery query(m_db);
    if (!query.exec("INSERT OR IGNORE INTO metadata (key) VALUES ('legacy-events-v1')"))
        return rollback(query.lastError().text());

    if (query.numRowsAffected() != 0 && QFileInfo::exists(legacy)) {
        QSettings old(legacy, QSettings::IniFormat);
        const auto json = old.value("CalendarEventsV1/recordsJson", "[]").toByteArray();
        const auto document = QJsonDocument::fromJson(json);
        if (old.status() != QSettings::NoError || !document.isArray())
            return rollback(tr("The old event file could not be read."));
        QSet<QString> ids;
        for (const auto &value : document.array()) {
            const auto record = value.toObject().toVariantMap();
            const auto id = record.value("id").toString();
            if (!validRecord(record) || id.isEmpty() || ids.contains(id))
                return rollback(tr("The old event file contains an invalid or duplicate record."));
            ids.insert(id);
            if (!upsert(record)) {
                m_db.rollback();
                return false;
            }
        }
    }
    if (!m_db.commit())
        return rollback(m_db.lastError().text());
    return true;
}

bool EventDatabase::reload()
{
    QSqlQuery query(m_db);
    if (!query.exec("SELECT body FROM events ORDER BY day, id"))
        return reportError(query.lastError().text());
    QVariantList records;
    while (query.next()) {
        const auto document = QJsonDocument::fromJson(query.value(0).toByteArray());
        if (!document.isObject())
            return reportError(tr("The calendar database contains an invalid record."));
        records.append(document.object().toVariantMap());
    }
    if (query.lastError().isValid())
        return reportError(query.lastError().text());

    beginResetModel();
    m_records.swap(records);
    endResetModel();
    emit recordsChanged();
    return true;
}

bool EventDatabase::upsert(const QVariantMap &record)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO events (id, day, body) VALUES (?, ?, ?) "
                  "ON CONFLICT(id) DO UPDATE SET day=excluded.day, body=excluded.body");
    query.addBindValue(record.value("id"));
    query.addBindValue(record.value("dateKey"));
    query.addBindValue(QJsonDocument::fromVariant(record).toJson(QJsonDocument::Compact));
    return query.exec() || reportError(query.lastError().text());
}

QString EventDatabase::save(QVariantMap record)
{
    if (!m_ready)
        return {};
    if (!validRecord(record)) {
        reportError(tr("Check the dates, times and time zone."));
        return {};
    }
    if (record.value("id").toString().isEmpty())
        record["id"] = QUuid::createUuid().toString(QUuid::WithoutBraces);
    if (!upsert(record))
        return {};
    if (!reload())
        return {};
    reportError({});
    return record.value("id").toString();
}

QString EventDatabase::saveOccurrence(const QString &seriesId, const QString &date, QVariantMap record)
{
    if (!m_ready || !QDate::fromString(date, Qt::ISODate).isValid())
        return {};
    const auto series = std::find_if(m_records.cbegin(), m_records.cend(), [&](const QVariant &value) {
        return value.toMap().value("id") == seriesId;
    });
    if (series == m_records.cend())
        return {};
    auto parent = series->toMap();
    auto excluded = parent.value("excludedDates").toList();
    if (excluded.contains(date) || parent.value("repeat") == "none") {
        reportError(tr("The occurrence is no longer part of the series."));
        return {};
    }
    excluded.append(date);
    parent["excludedDates"] = excluded;
    parent.remove("rawEvent");

    const auto id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    record["id"] = id;
    record["repeat"] = "none";
    record["repeatUntil"] = "";
    record.remove("rawEvent");
    record.remove("rawRule");
    record.remove("icsUid");
    record.remove("icsRecurrenceId");
    if (!validRecord(record)) {
        reportError(tr("Check the dates, times and time zone."));
        return {};
    }
    if (!m_db.transaction()) {
        reportError(m_db.lastError().text());
        return {};
    }
    if (!upsert(parent) || !upsert(record)) {
        m_db.rollback();
        return {};
    }
    if (!m_db.commit()) {
        const auto message = m_db.lastError().text();
        m_db.rollback();
        reportError(message);
        return {};
    }
    if (!reload())
        return {};
    reportError({});
    return id;
}

bool EventDatabase::remove(const QString &id)
{
    if (!m_ready)
        return false;
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM events WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec())
        return reportError(query.lastError().text());
    if (!reload())
        return false;
    reportError({});
    return true;
}

QVariantList EventDatabase::previewCalendar(const QUrl &url)
{
    reportError({});
    return decodeCalendar(url);
}

int EventDatabase::importCalendar(const QUrl &url, const QString &calendarId)
{
    if (!m_ready)
        return -1;
    const auto records = previewCalendar(url);
    if (records.isEmpty() && !error().isEmpty())
        return -1;
    if (!m_db.transaction()) {
        reportError(m_db.lastError().text());
        return -1;
    }
    for (const auto &item : records) {
        auto record = item.toMap();
        record["calendarId"] = calendarId;
        if (!validRecord(record) || !upsert(record)) {
            if (error().isEmpty())
                reportError(tr("The calendar contains an event with unsupported dates."));
            m_db.rollback();
            return -1;
        }
    }
    if (!m_db.commit()) {
        const auto message = m_db.lastError().text();
        m_db.rollback();
        reportError(message);
        return -1;
    }
    return reload() ? records.size() : -1;
}

bool EventDatabase::isTimeZone(const QString &identifier) const
{
    return identifier.isEmpty() || QTimeZone(identifier.toUtf8()).isValid();
}

QVariantMap EventDatabase::timeZoneRules(const QStringList &identifiers) const
{
    QVariantMap tables;
    const QDateTime start(QDate(1898, 1, 1), QTime(0, 0), QTimeZone::utc());
    const QDateTime end(QDate(2104, 1, 1), QTime(0, 0), QTimeZone::utc());
    for (const auto &identifier : identifiers) {
        if (tables.contains(identifier))
            continue;
        const auto zone = identifier.isEmpty() ? QTimeZone::systemTimeZone()
                                               : QTimeZone(identifier.toUtf8());
        if (!zone.isValid())
            continue;
        QVariantList intervals;
        intervals.append(QVariant(QVariantList{start.toMSecsSinceEpoch(), zone.offsetFromUtc(start)}));
        for (const auto &transition : zone.transitions(start, end))
            intervals.append(QVariant(QVariantList{transition.atUtc.toMSecsSinceEpoch(), transition.offsetFromUtc}));
        tables.insert(identifier, intervals);
    }
    return tables;
}

QString EventDatabase::todayInZone(const QString &identifier) const
{
    const auto zone = identifier.isEmpty() ? QTimeZone::systemTimeZone() : QTimeZone(identifier.toUtf8());
    return (zone.isValid() ? QDateTime::currentDateTimeUtc().toTimeZone(zone).date()
                           : QDate::currentDate()).toString(Qt::ISODate);
}
