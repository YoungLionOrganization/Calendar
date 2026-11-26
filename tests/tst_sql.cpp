// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#include "EventDatabase.h"

#include <QSettings>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

class DatabaseTest : public QObject
{
    Q_OBJECT
private slots:
    void importAndReopen()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const auto legacy = dir.filePath("events.ini");
        QSettings settings(legacy, QSettings::IniFormat);
        settings.setValue("CalendarEventsV1/recordsJson",
            R"([{"id":"existing","title":"Old","dateKey":"2026-12-31","endDateKey":"2026-12-31","startMinute":540,"endMinute":600,"repeat":"none"}])");
        settings.sync();
        const auto path = dir.filePath("events.sqlite");
        {
            EventDatabase database(path, legacy);
            QVERIFY2(database.ready(), qPrintable(database.error()));
            QCOMPARE(database.rowCount(), 1);
            auto record = database.records().constFirst().toMap();
            record["title"] = "Updated";
            QCOMPARE(database.save(record), "existing");
        }
        {
            EventDatabase database(path, legacy);
            QCOMPARE(database.rowCount(), 1);
            QCOMPARE(database.records().constFirst().toMap().value("title").toString(), "Updated");
            QVERIFY(database.remove("existing"));
        }
        EventDatabase database(path, legacy);
        QCOMPARE(database.rowCount(), 0);
    }
    void calendarRoundTripAndRepeatException()
    {
        QTemporaryDir dir;
        EventDatabase database(dir.filePath("data.sqlite"), dir.filePath("missing.ini"));
        QVERIFY2(database.ready(), qPrintable(database.error()));
        QFile source(dir.filePath("source.ics"));
        QVERIFY(source.open(QIODevice::WriteOnly));
        source.write("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Test//EN\r\n"
                     "BEGIN:VEVENT\r\nUID:opaque\r\nDTSTAMP:20260101T000000Z\r\n"
                     "DTSTART;VALUE=DATE:20261201\r\nDTEND;VALUE=DATE:20261202\r\n"
                     "SUMMARY:Monthly meeting\r\nRRULE:FREQ=MONTHLY;BYDAY=1MO\r\n"
                     "END:VEVENT\r\nEND:VCALENDAR\r\n");
        source.close();
        const auto url = QUrl::fromLocalFile(source.fileName());
        QCOMPARE(database.importCalendar(url, "study"), 1);
        QCOMPARE(database.importCalendar(url, "study"), 1);
        QCOMPARE(database.rowCount(), 1);
        const auto imported = database.records().first().toMap();
        QCOMPARE(imported.value("repeat").toString(), "none");
        QCOMPARE(imported.value("calendarId").toString(), "study");
        const auto destination = QUrl::fromLocalFile(dir.filePath("export.ics"));
        QVERIFY(database.exportCalendar(destination));
        QFile exported(destination.toLocalFile());
        QVERIFY(exported.open(QIODevice::ReadOnly));
        QVERIFY(exported.readAll().contains("RRULE:FREQ=MONTHLY;BYDAY=1MO"));

        QVariantMap weekly = {
            {"title", "Weekly class"}, {"dateKey", "2026-12-29"}, {"endDateKey", "2026-12-29"},
            {"startMinute", 540}, {"endMinute", 600}, {"repeat", "weekly"}
        };
        const auto series = database.save(weekly);
        QVERIFY(!series.isEmpty());
        weekly["dateKey"] = "2027-01-06";
        weekly["endDateKey"] = "2027-01-06";
        const auto detached = database.saveOccurrence(series, "2027-01-05", weekly);
        QVERIFY(!detached.isEmpty());
        QCOMPARE(database.rowCount(), 3);
        QVERIFY(database.saveOccurrence(series, "2027-01-05", weekly).isEmpty());
        QCOMPARE(database.rowCount(), 3);
    }

};
QTEST_GUILESS_MAIN(DatabaseTest)
#include "tst_sql.moc"
