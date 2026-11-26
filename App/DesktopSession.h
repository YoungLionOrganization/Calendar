// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QDateTime>
#include <QTimer>
#include <QVariantMap>
#include <QVariantList>

class EventDatabase;

class DesktopSession : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool notificationsAvailable READ notificationsAvailable CONSTANT)
    Q_PROPERTY(bool canLinkCalendars READ canLinkCalendars CONSTANT)
    Q_PROPERTY(QVariantList systemCalendars READ systemCalendars NOTIFY systemCalendarsChanged)
    Q_PROPERTY(QVariantList systemRecords READ systemRecords NOTIFY systemCalendarsChanged)
    Q_PROPERTY(QString selectedSystemCalendar READ selectedSystemCalendar WRITE selectSystemCalendar NOTIFY systemCalendarsChanged)
    Q_PROPERTY(bool canSetDefault READ canSetDefault CONSTANT)
    Q_PROPERTY(bool backgroundAvailable READ backgroundAvailable CONSTANT)
    Q_PROPERTY(bool backgroundEnabled READ backgroundEnabled NOTIFY backgroundEnabledChanged)
public:
    explicit DesktopSession(EventDatabase *database);
    bool acquire(const QString &target);
    void reschedule();
    bool notificationsAvailable() const;
    bool backgroundAvailable() const;
    bool canSetDefault() const;
    bool canLinkCalendars() const;
    QVariantList systemCalendars() const { return m_calendars; }
    QVariantList systemRecords() const { return m_systemRecords; }
    QString selectedSystemCalendar() const { return m_selectedSystemCalendar; }
    void selectSystemCalendar(const QString &id);
    void refreshSystemCalendars();
    Q_INVOKABLE void authorizeSystemCalendars();
    Q_INVOKABLE bool saveSystemEvent(const QVariantMap &record);
    Q_INVOKABLE bool removeSystemEvent(const QString &id);
    Q_INVOKABLE bool setAsDefault();
    Q_INVOKABLE void allowExactReminders();
    bool backgroundEnabled() const;
    Q_INVOKABLE bool allowBackground(bool enabled);

public slots:
Q_SCRIPTABLE void open(const QString &target);
    Q_SCRIPTABLE void reload();
    void backgroundResult(uint response, const QVariantMap &results);
    void resumed(bool sleeping);
    void actionInvoked(uint id, const QString &action);
    void Activate(const QVariantMap &options);
    void ActivateAction(const QString &action, const QVariantList &parameters, const QVariantMap &options);

signals:
    void openRequested(const QString &target);
    void backgroundEnabledChanged();
    void systemCalendarsChanged();

private:
    EventDatabase *m_database;
    QTimer m_timer;
    QDateTime m_due;
    QVariantList m_dueEvents;
    QHash<uint, QString> m_notificationEvents;
    bool m_helper = false;
    bool m_pendingBackground = false;
    bool m_portalEnable = false;
    QString m_portalRequest;
    QVariantList m_calendars;
    QVariantList m_systemRecords;
    QString m_selectedSystemCalendar;

public:
    void startHelper();
};
