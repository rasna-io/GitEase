#pragma once

#include <QObject>
#include <QVariant>
#include <QQmlEngine>

class GitResult
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(bool success READ success  CONSTANT FINAL)
    Q_PROPERTY(QString errorMessage READ errorMessage CONSTANT FINAL)
    Q_PROPERTY(QVariant data READ data CONSTANT FINAL)

public:
    explicit GitResult();
    GitResult(bool success, const QVariant &data = QVariant(),
              const QString &errorMessage = "");

    bool success() const;

    QString errorMessage() const;

    QVariant data() const;


private:
    bool m_success;
    QString m_errorMessage;
    QVariant m_data;
};


