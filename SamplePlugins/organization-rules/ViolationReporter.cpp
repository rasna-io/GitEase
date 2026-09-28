#include "ViolationReporter.h"
#include "IPluginContext.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

using namespace RuleSupport;

ViolationReporter::ViolationReporter(QObject *owner)
    : m_owner(owner)
{
}

void ViolationReporter::setContext(IPluginContext *context)
{
    m_context = context;
}

void ViolationReporter::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}

GitResult ViolationReporter::report(const QString &repoPath,
                                    const QString &action,
                                    const RuleViolations &violations)
{
    if (violations.isEmpty())
        return GitResult(true);

    RuleViolations blocking;
    RuleViolations warnings;
    for (const RuleViolation &v : violations)
        (v.blocking ? blocking : warnings) << v;

    bool anyNotificationRule = false;
    bool showWarnings = false;

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;
        anyNotificationRule = true;

        const bool includeWarnings = !isBlocking(rule);
        const RuleViolations reported = includeWarnings ? violations : blocking;
        if (reported.isEmpty())
            continue;

        showWarnings = showWarnings || (includeWarnings && rule["showInNotificationCenter"].toBool());

        if (rule["logViolationsToFile"].toBool()) {
            const QString logPath = rule["logFilePath"].toString().trimmed();
            appendToLog(resolveRepoPath(repoPath, logPath.isEmpty() ? ".gitease/violations.log" : logPath),
                        action, reported);
        }

        const QString channel = rule["notifyChannel"].toString().trimmed();
        if (channel.startsWith("http://") || channel.startsWith("https://"))
            postWebhook(channel, repoPath, action, reported);
        else if (!channel.isEmpty())
            qWarning() << "[OrganizationRules] Unsupported notify channel (use a webhook URL):" << channel;
    }

    if (!anyNotificationRule)
        showWarnings = true;

    if (showWarnings && m_context && !warnings.isEmpty()) {
        QStringList lines;
        for (const RuleViolation &v : warnings)
            lines << v.text();
        m_context->notify(lines.join('\n'), QStringLiteral("warning"));
    }

    if (blocking.isEmpty())
        return GitResult(true);

    QStringList lines;
    for (const RuleViolation &v : blocking)
        lines << v.text();
    return GitResult(false, {}, lines.join('\n'));
}

void ViolationReporter::appendToLog(const QString &path,
                                    const QString &action,
                                    const RuleViolations &violations) const
{
    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if (!file.open(QIODevice::Append | QIODevice::Text)) {
        qWarning() << "[OrganizationRules] Cannot open violation log:" << path;
        return;
    }

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    for (const RuleViolation &v : violations) {
        file.write(QString("%1  %2  %3  %4\n")
                       .arg(timestamp, v.blocking ? "BLOCKED" : "WARNING", action, v.text())
                       .toUtf8());
    }
}

void ViolationReporter::postWebhook(const QString &url,
                                    const QString &repoPath,
                                    const QString &action,
                                    const RuleViolations &violations)
{
    if (!m_network)
        m_network = new QNetworkAccessManager(m_owner);

    QStringList lines;
    for (const RuleViolation &v : violations)
        lines << QString("%1 %2").arg(v.blocking ? "[blocked]" : "[warning]", v.text());

    const QString text = QString("GitEase rule violation on %1 in %2\n%3")
                             .arg(action, QFileInfo(repoPath).fileName(), lines.join('\n'));

    // "text" is read by Slack / Teams / Mattermost, "content" by Discord.
    QJsonObject payload;
    payload["text"] = text;
    payload["content"] = text;

    QNetworkRequest request{ QUrl(url) };
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    QNetworkReply *reply = m_network->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    QObject::connect(reply, &QNetworkReply::finished, reply, [reply]() {
        if (reply->error() != QNetworkReply::NoError)
            qWarning() << "[OrganizationRules] Webhook failed:" << reply->errorString();
        reply->deleteLater();
    });
}
