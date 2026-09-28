#pragma once

#include "GitResult.h"
#include "RuleSupport.h"
#include <QJsonArray>

class IPluginContext;
class QNetworkAccessManager;
class QObject;

/*!
 * @brief Applies the Notification rules to the violations of one git action and turns them
 * into the action's GitResult.
 *
 * A notification rule with severity Error only reports blocking violations; Warning reports all.
 * Blocking violations are returned as the failure message (the host shows it where the action
 * was started), so only warnings go to the notification center.
 */
class ViolationReporter
{
public:
    explicit ViolationReporter(QObject *owner);

    void setContext(IPluginContext *context);
    void setRules(const QJsonArray &newRules);

    GitResult report(const QString &repoPath, const QString &action, const RuleViolations &violations);

private:
    void appendToLog(const QString &path, const QString &action, const RuleViolations &violations) const;
    void postWebhook(const QString &url, const QString &repoPath, const QString &action,
                     const RuleViolations &violations);

    QObject               *m_owner = nullptr;
    IPluginContext        *m_context = nullptr;
    QNetworkAccessManager *m_network = nullptr;
    QJsonArray             m_rules;
};
