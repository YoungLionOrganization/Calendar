// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QUrl>

class EventDatabase : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready CONSTANT)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QVariantList records READ records NOTIFY recordsChanged)

public:
    explicit EventDatabase(const QString &path, const QString &legacy, QObject *parent = nullptr);
    ~EventDatabase() override;
    bool ready() const { return m_ready; }
    QString error() const { return m_error; }
    QVariantList records() const { return m_records; }

    enum { RecordRole = Qt::UserRole + 1 };
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool refresh() { return m_ready && reload(); }
    Q_INVOKABLE QVariantMap timeZoneRules(const QStringList &identifiers) const;
    Q_INVOKABLE bool isTimeZone(const QString &identifier) const;
    Q_INVOKABLE QString todayInZone(const QString &identifier) const;
    Q_INVOKABLE QString save(QVariantMap record);
    Q_INVOKABLE QString saveOccurrence(const QString &seriesId, const QString &date, QVariantMap record);
    Q_INVOKABLE bool remove(const QString &id);
    Q_INVOKABLE int importCalendar(const QUrl &url, const QString &calendarId = "local");
    Q_INVOKABLE bool exportCalendar(const QUrl &url);
    Q_INVOKABLE QVariantList previewCalendar(const QUrl &url);

signals:
    void recordsChanged();
    void errorChanged();

private:
    bool migrate(const QString &legacy);
    bool reload();
    bool upsert(const QVariantMap &record);
    bool reportError(const QString &error);
    QVariantList decodeCalendar(const QUrl &url);

    QSqlDatabase m_db;
    QVariantList m_records;
    QString m_error;
    bool m_ready = false;
};
