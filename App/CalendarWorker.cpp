// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#include "CalendarWorker.h"

#include <QFile>
#include <QJSEngine>
#include <QJsonDocument>

CalendarWorker::CalendarWorker(QObject *parent)
    : QObject(parent), m_target(new QObject)
{
    m_thread.setObjectName("Calendar projection");
    m_thread.setStackSize(2 * 1024 * 1024);
    m_target->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, m_target, &QObject::deleteLater);
    connect(&m_thread, &QThread::started, m_target, [this] {
        QFile code(":/qt/qml/CalendarWorkers/MonthCacheWorker.js");
        if (!code.open(QIODevice::ReadOnly)) {
            qCritical("Cannot open the calendar projection script.");
            return;
        }
        m_engine = new QJSEngine(m_target);
        const auto setup = m_engine->evaluate(QStringLiteral(R"js(
            var projectionReply = null;
            var WorkerScript = {
                sendMessage: function (value) { projectionReply = value; }
            };
            function projectMessage(json) {
                projectionReply = null;
                WorkerScript.onMessage(JSON.parse(json));
                return projectionReply;
            }
        )js") + QString::fromUtf8(code.readAll()), code.fileName());
        if (setup.isError()) {
            qCritical().noquote() << setup.toString();
            return;
        }
        QMetaObject::invokeMethod(this, [this] {
            m_ready = true;
            emit readyChanged();
        }, Qt::QueuedConnection);
    });
    m_thread.start();
}

CalendarWorker::~CalendarWorker()
{
    m_thread.quit();
    m_thread.wait();
}

void CalendarWorker::sendMessage(const QVariantMap &request)
{
    if (!m_ready)
        return;
    const auto json = QString::fromUtf8(QJsonDocument::fromVariant(request).toJson(QJsonDocument::Compact));
    QMetaObject::invokeMethod(m_target, [this, request, json] {
        const auto function = m_engine->globalObject().property("projectMessage");
        const auto result = function.call({QJSValue(json)});
        if (result.isError()) {
            qWarning().noquote() << result.toString() << result.property("stack").toString();
            if (request.contains("projectionRequest"))
                emit message({{"projectionRequest", request.value("projectionRequest")}, {"segments", QVariantList{}}});
            else if (request.contains("period"))
                emit message({{"period", request.value("period")}, {"revision", request.value("revision")}, {"days", QVariant()}});
        } else if (result.isObject()) {
            emit message(result.toVariant().toMap());
        }
    }, Qt::QueuedConnection);
}
