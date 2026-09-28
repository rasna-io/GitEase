#include "CommitMessageValidator.h"

#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>

using namespace RuleSupport;

namespace {

//! Words that end like a past tense, gerund or third person verb but are fine as the first word.
const QSet<QString> &imperativeExceptions()
{
    static const QSet<QString> words = {
        "embed", "feed", "seed", "need", "proceed", "exceed", "succeed", "speed", "shed", "bleed",
        "breed", "shred", "wed", "red", "bed", "bring", "string", "ring", "sing", "spring", "swing",
        "sting", "wring", "ping", "king", "thing", "process", "access", "address", "pass", "bypass",
        "compress", "express", "focus", "discuss", "dismiss", "miss", "kiss", "toss", "cross",
        "gloss", "press", "suppress", "harness", "bless", "bus", "alias", "canvas", "status",
        "redis", "this", "analysis", "css", "js", "ios", "macos", "windows", "tests", "docs",
        "deps", "ts", "yes", "is", "was", "has", "does"
    };
    return words;
}

//! "added", "adding", "adds" -> not imperative. Returns the offending word or an empty string.
QString nonImperativeFirstWord(const QString &subject)
{
    if (subject.startsWith("Merge ") || subject.startsWith("Revert "))
        return {};

    // Drop a Conventional Commits header: type(scope)!:
    static const QRegularExpression header("^[A-Za-z]+(\\([^)]*\\))?!?:\\s*");
    QString description = subject;
    description.remove(header);

    static const QRegularExpression firstWordRe("^([A-Za-z]+)");
    const QRegularExpressionMatch match = firstWordRe.match(description.trimmed());
    if (!match.hasMatch())
        return {};

    const QString word = match.captured(1).toLower();
    if (word.length() < 4 || imperativeExceptions().contains(word))
        return {};

    if (word.endsWith("ed") || word.endsWith("ing"))
        return match.captured(1);

    if (word.endsWith('s') && !word.endsWith("ss") && !word.endsWith("us") && !word.endsWith("is"))
        return match.captured(1);

    return {};
}

} // namespace

RuleViolations CommitMessageValidator::validateCommitMessage(const QString &message) const
{
    RuleViolations violations;

    const QString subject = message.section('\n', 0, 0);
    const QString body = message.section("\n\n", 1);

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        auto report = [&](const QString &text) { violations << violation(rule, text); };

        const int minLength = intValue(rule, "minLength");
        const int maxLength = intValue(rule, "maxLength");

        if (minLength > 0 && subject.length() < minLength) {
            report(QString("Commit subject must be at least %1 characters").arg(minLength));
            continue;
        }

        if (maxLength > 0 && subject.length() > maxLength) {
            report(QString("Commit subject must not exceed %1 characters").arg(maxLength));
            continue;
        }

        if (rule["noTrailingPeriod"].toBool() && subject.endsWith('.')) {
            report("Commit subject must not end with a period");
            continue;
        }

        if (rule["requirePrefix"].toBool()) {
            const QStringList prefixes = splitList(rule["allowedPrefixes"]);
            bool valid = prefixes.isEmpty();
            for (const QString &prefix : prefixes) {
                if (subject.startsWith(prefix)) {
                    valid = true;
                    break;
                }
            }
            if (!valid) {
                report(QString("Commit subject must start with one of: %1").arg(prefixes.join(", ")));
                continue;
            }
        }

        if (rule["imperativeVerb"].toBool()) {
            const QString word = nonImperativeFirstWord(subject);
            if (!word.isEmpty()) {
                report(QString("Use the imperative mood in the subject (\"add\", not \"%1\")").arg(word));
                continue;
            }
        }

        bool forbiddenFound = false;
        for (const QString &word : splitList(rule["forbiddenWords"])) {
            if (message.contains(word, Qt::CaseInsensitive)) {
                report(QString("Commit message contains forbidden word: %1").arg(word));
                forbiddenFound = true;
                break;
            }
        }
        if (forbiddenFound)
            continue;

        if (rule["requireTicketRef"].toBool()) {
            const QString pattern = rule["ticketRefPattern"].toString();
            if (!pattern.isEmpty() && !QRegularExpression(pattern).match(message).hasMatch()) {
                report(QString("Missing ticket reference (%1)").arg(pattern));
                continue;
            }
        }

        if (rule["requireBodySeparator"].toBool() && message.trimmed().contains('\n')
            && !message.contains("\n\n")) {
            report("Body must be separated from the subject by an empty line");
            continue;
        }

        const int bodyMinLength = intValue(rule, "bodyMinLength");
        if (bodyMinLength > 0 && body.trimmed().length() < bodyMinLength) {
            report(QString("Commit body must be at least %1 characters").arg(bodyMinLength));
            continue;
        }

        if (rule["requireSignedOffBy"].toBool() && !message.contains("Signed-off-by:")) {
            report("Missing Signed-off-by trailer");
            continue;
        }

        const QString customRegex = rule["customRegex"].toString();
        if (!customRegex.isEmpty() && !QRegularExpression(customRegex).match(message).hasMatch()) {
            const QString customError = rule["customErrorMessage"].toString();
            report(customError.isEmpty()
                       ? QString("Commit message does not match %1").arg(customRegex)
                       : customError);
        }
    }

    return violations;
}

void CommitMessageValidator::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
