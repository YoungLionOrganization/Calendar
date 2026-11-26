// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#include "DesktopSession.h"
#include "EventDatabase.h"

#include <QCoreApplication>
#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>
#include <QJsonDocument>
#include <QPointer>
#include <QCoreApplication>

static QPointer<DesktopSession> activeSession;

extern "C" JNIEXPORT void JNICALL
Java_xyz_younglion_calendar_CalendarActivity_calendarsChanged(JNIEnv *, jclass)
{
    if (activeSession)
        QMetaObject::invokeMethod(activeSession, &DesktopSession::refreshSystemCalendars, Qt::QueuedConnection);
}

extern "C" JNIEXPORT void JNICALL
Java_xyz_younglion_calendar_CalendarActivity_deliverTarget(JNIEnv *, jclass, jstring target)
{
    if (!activeSession)
        return;
    const auto value = QJniObject(target).toString();
    QMetaObject::invokeMethod(activeSession, [value] {
        if (activeSession)
            activeSession->open(value);
    }, Qt::QueuedConnection);
}
#endif
#include <algorithm>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QSaveFile>
#include <QSettings>
#include <QUuid>
#include <QStandardPaths>
#include <QTimeZone>
#ifdef YOUNGLION_DESKTOP_DBUS
#include <QDBusConnection>
#include <QDBusAbstractAdaptor>
#include <QDBusVariant>
#include <QDBusPendingCallWatcher>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusObjectPath>
#endif

namespace {
constexpr auto appId = "xyz.younglion.Calendar";
constexpr auto helperId = "xyz.younglion.Calendar.Reminders";
constexpr auto objectPath = "/xyz/younglion/Calendar";
constexpr auto bridge = "xyz.younglion.Calendar.Session";
constexpr auto notifications = "org.freedesktop.Notifications";
constexpr auto portal = "org.freedesktop.portal.Desktop";
constexpr auto portalPath = "/org/freedesktop/portal/desktop";

bool flatpak()
{
    return QFile::exists("/.flatpak-info");
}

#ifdef YOUNGLION_DESKTOP_DBUS
class PortalApplication final : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Application")
public:
    explicit PortalApplication(DesktopSession *parent) : QDBusAbstractAdaptor(parent), m_session(parent) {}
public slots:
    void Activate(const QVariantMap &options) { m_session->Activate(options); }
    void ActivateAction(const QString &action, const QVariantList &args, const QVariantMap &options)
    {
        auto decoded = args;
        for (auto &value : decoded)
            if (value.canConvert<QDBusVariant>())
                value = value.value<QDBusVariant>().variant();
        m_session->ActivateAction(action, decoded, options);
    }
private:
    DesktopSession *m_session;
};
#endif

bool occurs(const QVariantMap &event, QDate date, QDate start)
{
    if (date < start || event.value("excludedDates").toList().contains(date.toString(Qt::ISODate)))
        return false;
    const auto until = QDate::fromString(event.value("repeatUntil").toString(), Qt::ISODate);
    if (until.isValid() && date > until)
        return false;
    const auto repeat = event.value("repeat").toString();
    if (repeat == "daily")
        return true;
    if (repeat == "weekly") {
        const auto days = event.value("weekdays").toList();
        return days.isEmpty() ? date.dayOfWeek() == start.dayOfWeek()
            : std::any_of(days.cbegin(), days.cend(), [date](const QVariant &day) { return day.toInt() == date.dayOfWeek(); });
    }
    if (repeat == "monthly")
        return date.day() == start.day();
    if (repeat == "yearly")
        return date.day() == start.day() && date.month() == start.month();
    return date == start;
}
}

DesktopSession::DesktopSession(EventDatabase *database) : m_database(database)
{
#ifdef Q_OS_ANDROID
    activeSession = this;
    m_selectedSystemCalendar = QSettings().value("providers/androidCalendar").toString();
    QTimer::singleShot(0, this, &DesktopSession::refreshSystemCalendars);
#endif
    m_timer.setSingleShot(true);
    connect(&m_timer, &QTimer::timeout, this, &DesktopSession::reschedule);
#ifdef YOUNGLION_DESKTOP_DBUS
    auto bus = QDBusConnection::sessionBus();
    bus.connect(notifications, "/org/freedesktop/Notifications", notifications, "ActionInvoked",
                this, SLOT(actionInvoked(uint,QString)));
    QDBusConnection::systemBus().connect("org.freedesktop.login1", "/org/freedesktop/login1",
        "org.freedesktop.login1.Manager", "PrepareForSleep", this, SLOT(resumed(bool)));
#endif
    connect(database, &EventDatabase::recordsChanged, this, [this] {
        if (m_helper)
            return;
#ifdef YOUNGLION_DESKTOP_DBUS
        auto bus = QDBusConnection::sessionBus();
        auto call = QDBusMessage::createMethodCall(helperId, objectPath, bridge, "reload");
        bus.asyncCall(call);
#endif
        reschedule();
    });
}

bool DesktopSession::notificationsAvailable() const
{
#ifdef YOUNGLION_DESKTOP_DBUS
    return QDBusConnection::sessionBus().isConnected();
#elif defined(Q_OS_ANDROID)
    return true;
#else
    return false;
#endif
}

bool DesktopSession::acquire(const QString &target)
{
#ifdef YOUNGLION_DESKTOP_DBUS
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
        return true;
    if (!bus.registerService(QString::fromLatin1(appId))) {
        auto call = QDBusMessage::createMethodCall(appId, objectPath, bridge, "open");
        call << target;
        return bus.call(call, QDBus::Block, 2500).type() == QDBusMessage::ErrorMessage;
    }
    new PortalApplication(this);
    bus.registerObject(objectPath, bridge, this, QDBusConnection::ExportScriptableSlots | QDBusConnection::ExportAdaptors);
#else
    Q_UNUSED(target)
#endif
    return true;
}

void DesktopSession::startHelper()
{
    m_helper = true;
#ifdef YOUNGLION_DESKTOP_DBUS
    auto bus = QDBusConnection::sessionBus();
    if (!bus.registerService(helperId)) {
        QTimer::singleShot(0, qApp, &QCoreApplication::quit);
        return;
    }
    bus.registerObject(objectPath, bridge, this, QDBusConnection::ExportScriptableSlots);
#endif
    reschedule();
}

void DesktopSession::open(const QString &target)
{
    emit openRequested(target);
}

void DesktopSession::Activate(const QVariantMap &)
{
    open({});
}

void DesktopSession::ActivateAction(const QString &action, const QVariantList &parameters,
                                    const QVariantMap &)
{
    if (action == "event" && !parameters.isEmpty())
        open("event:" + parameters.first().toString());
}

void DesktopSession::reload()
{
    m_database->refresh();
    reschedule();
}

bool DesktopSession::canLinkCalendars() const
{
#ifdef Q_OS_ANDROID
    return true;
#else
    return false;
#endif
}

void DesktopSession::selectSystemCalendar(const QString &id)
{
    m_selectedSystemCalendar = id;
    QSettings().setValue("providers/androidCalendar", id);
    refreshSystemCalendars();
}

void DesktopSession::refreshSystemCalendars()
{
#ifdef Q_OS_ANDROID
    const auto activity = QNativeInterface::QAndroidApplication::context();
    auto decode = [](const QString &json) { return QJsonDocument::fromJson(json.toUtf8()).toVariant().toList(); };
    m_calendars = decode(activity.callMethod<jstring>("availableCalendars").toString());
    const auto id = QJniObject::fromString(m_selectedSystemCalendar);
    m_systemRecords = decode(activity.callMethod<jstring>("readCalendar", id.object<jstring>()).toString());
    emit systemCalendarsChanged();
#endif
}

void DesktopSession::authorizeSystemCalendars()
{
#ifdef Q_OS_ANDROID
    QNativeInterface::QAndroidApplication::context().callMethod<void>("requestCalendars");
#endif
}

bool DesktopSession::saveSystemEvent(const QVariantMap &record)
{
#ifdef Q_OS_ANDROID
    const auto value = QJniObject::fromString(QString::fromUtf8(QJsonDocument::fromVariant(record).toJson(QJsonDocument::Compact)));
    const auto success = QNativeInterface::QAndroidApplication::context()
                             .callMethod<jboolean>("updateCalendarEvent", value.object<jstring>());
    if (success)
        refreshSystemCalendars();
    return success;
#else
    Q_UNUSED(record)
    return false;
#endif
}

bool DesktopSession::removeSystemEvent(const QString &id)
{
#ifdef Q_OS_ANDROID
    const auto value = QJniObject::fromString(id);
    const auto success = QNativeInterface::QAndroidApplication::context()
                             .callMethod<jboolean>("deleteCalendarEvent", value.object<jstring>());
    if (success)
        refreshSystemCalendars();
    return success;
#else
    Q_UNUSED(id)
    return false;
#endif
}

bool DesktopSession::canSetDefault() const
{
#ifdef YOUNGLION_DESKTOP_DBUS
    return !flatpak() && !QStandardPaths::findExecutable("xdg-mime").isEmpty();
#else
    return false;
#endif
}

bool DesktopSession::setAsDefault()
{
    return canSetDefault() && QProcess::execute(QStandardPaths::findExecutable("xdg-mime"),
        {"default", QString(appId) + ".desktop", "text/calendar"}) == 0;
}

void DesktopSession::allowExactReminders()
{
#ifdef Q_OS_ANDROID
    QNativeInterface::QAndroidApplication::context().callMethod<void>("requestExactAlarm");
#endif
}

bool DesktopSession::backgroundAvailable() const
{
    return notificationsAvailable();
}

bool DesktopSession::backgroundEnabled() const
{
#ifdef Q_OS_ANDROID
    return QNativeInterface::QAndroidApplication::context().callMethod<jboolean>("remindersEnabled");
#else
    if (flatpak())
        return QSettings().value("portal/autoStartReminders", false).toBool();
    const auto dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    return backgroundAvailable() && QFile::exists(dir + "/autostart/" + appId + ".desktop");
#endif
}

bool DesktopSession::allowBackground(bool enabled)
{
#ifdef YOUNGLION_DESKTOP_DBUS
    if (flatpak()) {
        if (m_pendingBackground)
            return false;
        auto bus = QDBusConnection::sessionBus();
        const auto token = "calendar_" + QUuid::createUuid().toString(QUuid::Id128);
        auto sender = bus.baseService().mid(1).replace('.', '_');
        m_portalRequest = QString(portalPath) + "/request/" + sender + "/" + token;
        if (!bus.connect(portal, m_portalRequest, "org.freedesktop.portal.Request", "Response",
                         this, SLOT(backgroundResult(uint,QVariantMap))))
            return false;
        m_portalEnable = enabled;
        m_pendingBackground = true;
        auto message = QDBusMessage::createMethodCall(portal, portalPath, "org.freedesktop.portal.Background", "RequestBackground");
        message << QString() << QVariantMap{
            {"handle_token", token}, {"reason", tr("Show calendar reminders while the window is closed.")},
            {"autostart", enabled}, {"commandline", QStringList{"CalendarApp", "--reminder-service"}}};
        auto *watcher = new QDBusPendingCallWatcher(bus.asyncCall(message), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher] {
            if (watcher->isError())
                backgroundResult(2, {});
            watcher->deleteLater();
        });
        return true;
    }
    const auto dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/autostart";
    const auto file = dir + "/" + appId + ".desktop";
    if (!enabled) {
        if (QFile::exists(file) && !QFile::remove(file))
            return false;
        auto message = QDBusMessage::createMethodCall(helperId, objectPath, bridge, "reload");
        QDBusConnection::sessionBus().asyncCall(message);
        emit backgroundEnabledChanged();
        reschedule();
        return true;
    }
    if (!QDir().mkpath(dir))
        return false;
    QSaveFile config(file);
    if (!config.open(QIODevice::WriteOnly))
        return false;
    auto executable = QCoreApplication::applicationFilePath();
    executable.replace("\\", "\\\\").replace("\"", "\\\"").replace("%", "%%").replace("$", "\\$").replace("`", "\\`");
    const auto entry = QString("[Desktop Entry]\nType=Application\nName=YoungLion Calendar Reminders\nExec=\"%1\" --reminder-service\n").arg(executable).toUtf8();
    if (config.write(entry) != entry.size() || !config.commit())
        return false;
    emit backgroundEnabledChanged();
    reschedule();
    return QProcess::startDetached(QCoreApplication::applicationFilePath(), {"--reminder-service"});
#elif defined(Q_OS_ANDROID)
    const auto activity = QNativeInterface::QAndroidApplication::context();
    const auto result = activity.callMethod<jboolean>("toggleReminders", jboolean(enabled));
    emit backgroundEnabledChanged();
    return result;
#else
    Q_UNUSED(enabled)
    return false;
#endif
}

void DesktopSession::backgroundResult(uint response, const QVariantMap &results)
{
#ifdef YOUNGLION_DESKTOP_DBUS
    if (!m_pendingBackground)
        return;
    auto bus = QDBusConnection::sessionBus();
    bus.disconnect(portal, m_portalRequest, "org.freedesktop.portal.Request", "Response",
                   this, SLOT(backgroundResult(uint,QVariantMap)));
    m_pendingBackground = false;
    if (response == 0) {
        const bool enabled = m_portalEnable && results.value("autostart").toBool()
                             && results.value("background").toBool();
        QSettings settings;
        settings.setValue("portal/autoStartReminders", enabled);
        settings.sync();
        if (enabled)
            QProcess::startDetached(QCoreApplication::applicationFilePath(), {"--reminder-service"});
        else
            bus.asyncCall(QDBusMessage::createMethodCall(helperId, objectPath, bridge, "reload"));
        reschedule();
    }
    emit backgroundEnabledChanged();
#else
    Q_UNUSED(response)
    Q_UNUSED(results)
#endif
}

void DesktopSession::resumed(bool sleeping)
{
    if (!sleeping)
        reschedule();
}

void DesktopSession::reschedule()
{
#ifdef YOUNGLION_DESKTOP_DBUS
    const bool background = backgroundEnabled();
    if (m_helper && !background) {
        QCoreApplication::quit();
        return;
    }

    const auto now = QDateTime::currentDateTimeUtc();
    if (m_due.isValid() && m_due <= now && m_due.secsTo(now) <= 600 && !m_dueEvents.isEmpty()) {
        for (const auto &value : std::as_const(m_dueEvents)) {
            const auto event = value.toMap();
            const auto title = event.value("title").toString();
            const auto id = event.value("id").toString();
            if (flatpak()) {
                auto message = QDBusMessage::createMethodCall(portal, portalPath, "org.freedesktop.portal.Notification", "AddNotification");
                message << (id + "-" + QString::number(m_due.toSecsSinceEpoch()))
                        << QVariantMap{{"title", title}, {"default-action", QString("app.event")},
                                       {"default-action-target", id}};
                QDBusConnection::sessionBus().asyncCall(message);
            } else {
                auto message = QDBusMessage::createMethodCall(notifications, "/org/freedesktop/Notifications",
                                                             notifications, "Notify");
                message << QString("YoungLion Calendar") << uint(0) << QString(appId)
                        << title.toHtmlEscaped() << QString()
                        << QStringList{"default", tr("Open event")} << QVariantMap{} << int(-1);
                const auto reply = QDBusConnection::sessionBus().call(message, QDBus::Block, 1000);
                if (!reply.arguments().isEmpty())
                    m_notificationEvents.insert(reply.arguments().first().toUInt(), id);
            }
        }
    }
    m_due = {};
    m_dueEvents.clear();
    if (!m_helper && background)
        return;

    for (const auto &item : m_database->records()) {
        const auto event = item.toMap();
        const auto start = QDate::fromString(event.value("dateKey").toString(), Qt::ISODate);
        auto zone = QTimeZone(event.value("timeZone").toString().toUtf8());
        if (!zone.isValid() || event.value("allDay").toBool())
            zone = QTimeZone::systemTimeZone();
        const auto currentDay = now.toTimeZone(zone).date();
        const auto reminders = event.value("reminders", QVariantList{event.value("reminder", -1)}).toList();
        for (const auto &reminder : reminders) {
            const int minutesBefore = reminder.toInt();
            if (minutesBefore < 0 || minutesBefore > 525600)
                continue;
            const auto first = qMax(start, currentDay.addDays(minutesBefore / 1440 - 1));
            const auto last = event.value("repeat") == "none" ? first : first.addYears(4).addDays(1);
            for (auto date = first; date <= last; date = date.addDays(1)) {
                if (!occurs(event, date, start))
                    continue;
                const auto time = QTime(0, 0).addSecs(event.value("startMinute").toInt() * 60);
                const auto alarm = QDateTime(date, time, zone).addSecs(-60 * minutesBefore).toUTC();
                if (alarm <= now)
                    continue;
                if (!m_due.isValid() || alarm < m_due) {
                    m_due = alarm;
                    m_dueEvents.clear();
                }
                if (alarm == m_due && !m_dueEvents.contains(event))
                    m_dueEvents.append(event);
                break;
            }
        }
    }
    if (m_due.isValid())
        m_timer.start(int(std::clamp<qint64>(now.msecsTo(m_due), 1, 86400000)));
#elif defined(Q_OS_ANDROID)
    QVariantList reminderRecords;
    for (const auto &value : m_database->records()) {
        const auto record = value.toMap();
        if (record.value("reminder", -1).toInt() < 0 && record.value("reminders").toList().isEmpty())
            continue;
        QVariantMap compact;
        for (const auto *field : {"id", "title", "dateKey", "startMinute", "allDay", "repeat",
                                  "repeatUntil", "weekdays", "excludedDates", "timeZone", "reminders", "reminder"})
            if (record.contains(field))
                compact.insert(field, record.value(field));
        reminderRecords.append(compact);
    }
    const auto records = QJniObject::fromString(QString::fromUtf8(QJsonDocument::fromVariant(reminderRecords).toJson(QJsonDocument::Compact)));
    QNativeInterface::QAndroidApplication::context().callMethod<void>("remindersChanged", records.object<jstring>());
#endif
}

void DesktopSession::actionInvoked(uint id, const QString &action)
{
    if (action != "default" || !m_notificationEvents.contains(id))
        return;
    const auto target = "event:" + m_notificationEvents.take(id);
    if (m_helper)
        QProcess::startDetached(QCoreApplication::applicationFilePath(), {target});
    else
        open(target);
}

#ifdef YOUNGLION_DESKTOP_DBUS
#include "DesktopSession.moc"
#endif
