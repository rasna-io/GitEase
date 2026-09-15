#include "CommitMessageValidator.h"
#include "GitResult.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>

GitResult CommitMessageValidator::validateCommitMessage(const QString &message)
{
    qDebug() << m_rules;

    for (const QJsonValue &value : m_rules) {
        QJsonObject rule = value.toObject();

        if (!rule["enabled"].toBool())
            continue;


        QString subject = message.section('\n', 0, 0);
        QString body = message.section("\n\n", 1);

        int minLength = rule["minLength"].toString().toInt();
        int maxLength = rule["maxLength"].toString().toInt();


        if (minLength > 0 && subject.length() < minLength) {
            return GitResult(false, {},
                             QString("Commit subject must be at least %1 characters")
                                 .arg(minLength));
        }


        if (maxLength > 0 && subject.length() > maxLength) {
            return GitResult(false, {},
                             QString("Commit subject must not exceed %1 characters")
                                 .arg(maxLength));
        }


        if (rule["noTrailingPeriod"].toBool() &&
            subject.endsWith('.')) {

            return GitResult(false, {},
                             "Commit subject must not end with a period");
        }


        if (rule["requirePrefix"].toBool()) {
            QStringList prefixes =
                rule["allowedPrefixes"].toString()
                    .split(',', Qt::SkipEmptyParts);

            bool valid = false;

            for (const QString &prefix : prefixes) {
                if (subject.startsWith(prefix.trimmed())) {
                    valid = true;
                    break;
                }
            }

            if (!valid) {
                return GitResult(false, {},
                                 "Commit message prefix is invalid");
            }
        }


        QStringList forbidden =
            rule["forbiddenWords"].toString()
                .split(',', Qt::SkipEmptyParts);

        for (const QString &word : forbidden) {
            if (message.contains(word.trimmed(),
                                 Qt::CaseInsensitive)) {

                return GitResult(false, {},
                                 QString("Commit message contains forbidden word: %1")
                                     .arg(word));
            }
        }


        if (rule["requireTicketRef"].toBool()) {
            QRegularExpression regex(
                rule["ticketRefPattern"].toString());

            if (!regex.match(message).hasMatch()) {
                return GitResult(false, {},
                                 "Missing ticket reference");
            }
        }


        if (rule["requireBodySeparator"].toBool() &&
            message.contains('\n') &&
            !message.contains("\n\n")) {

            return GitResult(false, {},
                             "Body must be separated by an empty line");
        }


        if (rule["bodyMinLength"].toString().toInt() > 0 &&
            body.length() <
                rule["bodyMinLength"].toString().toInt()) {

            return GitResult(false, {},
                             "Commit body is too short");
        }


        if (rule["requireSignedOffBy"].toBool() &&
            !message.contains("Signed-off-by:")) {

            return GitResult(false, {},
                             "Missing Signed-off-by");
        }


        QString customRegex = rule["customRegex"].toString();

        if (!customRegex.isEmpty()) {
            QRegularExpression regex(customRegex);

            if (!regex.match(message).hasMatch()) {
                return GitResult(false, {},
                                 rule["customErrorMessage"].toString());
            }
        }
    }

    return GitResult(true);
}

void CommitMessageValidator::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
