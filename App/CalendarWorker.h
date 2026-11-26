// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QThread>
#include <QVariantMap>

class QJSEngine;

class CalendarWorker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
public:
    explicit CalendarWorker(QObject *parent = nullptr);
    ~CalendarWorker() override;
    bool ready() const { return m_ready; }
    Q_INVOKABLE void sendMessage(const QVariantMap &request);

signals:
    void readyChanged();
    void message(const QVariantMap &response);

private:
    QThread m_thread;
    QObject *m_target;
    QJSEngine *m_engine = nullptr;
    bool m_ready = false;
};
