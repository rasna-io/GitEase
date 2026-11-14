#pragma once

#include <QObject>
#include <QVariant>
#include <QQmlEngine>

class GitResult
{
    Q_GADGET
#ifndef GITEASE_SKIP_QML_ELEMENT
    QML_ELEMENT
#endif

    Q_PROPERTY(bool success READ success CONSTANT FINAL)
    Q_PROPERTY(QString errorMessage READ errorMessage CONSTANT FINAL)
    Q_PROPERTY(QVariant data READ data CONSTANT FINAL)
    Q_PROPERTY(QString errorCode READ errorCode CONSTANT FINAL)

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

    QString errorCode() const
    {
        return m_errorCode;
    }

    void setErrorCode(const QString& errorCode)
    {
        m_errorCode = errorCode;
    }

private:
    bool m_success = true;
    QString m_errorMessage;
    QVariant m_data;
    QString m_errorCode;
};