// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include "EventDatabase.h"
#include "DesktopSession.h"
#include "CalendarWorker.h"
#include <QFileInfo>
#include <memory>
#include <cstring>
#ifdef Q_OS_ANDROID
#include <QJniObject>
#endif

#include "autogen/environment.h"

int main(int argc, char *argv[])
{
    set_qt_environment();
    const bool service = argc > 1 && std::strcmp(argv[1], "--reminder-service") == 0;
    std::unique_ptr<QCoreApplication> app;
    if (service)
        app = std::make_unique<QCoreApplication>(argc, argv);
    else
        app = std::make_unique<QApplication>(argc, argv);

    QCoreApplication::setOrganizationName("YoungLion");
    QCoreApplication::setApplicationName("Calendar");
    QCoreApplication::setOrganizationDomain("younglion.xyz");
    if (!service)
        QGuiApplication::setDesktopFileName("xyz.younglion.Calendar");
    const auto arguments = app->arguments();
    QString target = arguments.value(1);
    if (!target.isEmpty() && !target.startsWith("event:") && !target.contains("://"))
        target = QUrl::fromLocalFile(QFileInfo(target).absoluteFilePath()).toString();
#ifdef Q_OS_ANDROID
    target = QNativeInterface::QAndroidApplication::context()
                 .callMethod<jstring>("activationTarget").toString();
#endif
    const auto legacy = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                        + "/YoungLion/Calendar/events.ini";
    const auto storage = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    EventDatabase backend(storage + "/events.sqlite", legacy);

    DesktopSession platform(&backend);
    if (service) {
        platform.startHelper();
        return QCoreApplication::exec();
    }
    if (!platform.acquire(target))
        return 0;

    CalendarWorker calendarWorker;
    QQmlApplicationEngine engine;
    engine.setInitialProperties({{"backend", QVariant::fromValue(&backend)},
                                 {"platform", QVariant::fromValue(&platform)},
                                 {"calendarWorker", QVariant::fromValue(&calendarWorker)}, {"startupTarget", target}});
    const QUrl url(mainQmlFile);
    QObject::connect(
                &engine, &QQmlApplicationEngine::objectCreated, app.get(),
                [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
    engine.addImportPath(":/");
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    platform.reschedule();
    return QCoreApplication::exec();
}
