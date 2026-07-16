#pragma once

#include <QObject>
#include <QVariant>
#include <QQmlEngine>

class GitResult
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(bool success READ success CONSTANT FINAL)
    Q_PROPERTY(QString errorMessage READ errorMessage CONSTANT FINAL)
    Q_PROPERTY(QVariant data READ data CONSTANT FINAL)

public:
    GitResult()
        : m_success(true)
    {
    }

    GitResult(bool success,
              const QVariant& data = {},
              const QString& errorMessage = {})
        : m_success(success)
        , m_errorMessage(errorMessage)
        , m_data(data)
    {
    }

    bool success() const
    {
        return m_success;
    }

    QString errorMessage() const
    {
        return m_errorMessage;
    }

    QVariant data() const
    {
        return m_data;
    }

private:
    bool m_success = true;
    QString m_errorMessage;
    QVariant m_data;
};