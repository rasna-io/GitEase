#include "BranchNameValidator.h"

#include <QJsonObject>
#include <QRegularExpression>

using namespace RuleSupport;

RuleViolations BranchNameValidator::validateBranchName(const QString &branchName) const
{
    RuleViolations violations;

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        auto report = [&](const QString &text) { violations << violation(rule, text); };

        if (rule["forbidSpaces"].toBool() && branchName.contains(QRegularExpression("\\s"))) {
            report("Branch name must not contain spaces");
            continue;
        }

        if (rule["forbidUppercase"].toBool() && branchName != branchName.toLower()) {
            report("Branch name must be lowercase");
            continue;
        }

        static const QRegularExpression allowedChars("^[A-Za-z0-9/._-]+$");
        if (rule["forbidSpecialChars"].toBool() && !allowedChars.match(branchName).hasMatch()) {
            report("Branch name may only contain letters, digits, '/', '-', '_' and '.'");
            continue;
        }

        // Long-lived branches listed as protected (main, develop, release/*) skip the prefix rule.
        const QStringList prefixes = splitList(rule["allowedPrefixes"]);
        const QStringList protectedBranches = splitList(rule["protectedBranches"]);
        if (!prefixes.isEmpty() && !matchesAnyGlob(branchName, protectedBranches)) {
            bool hasPrefix = false;
            for (const QString &prefix : prefixes) {
                if (branchName.startsWith(prefix) && branchName.length() > prefix.length()) {
                    hasPrefix = true;
                    break;
                }
            }
            if (!hasPrefix) {
                report(QString("Branch name must start with one of: %1").arg(prefixes.join(", ")));
                continue;
            }
        }

        const int maxLength = intValue(rule, "maxLength");
        if (maxLength > 0 && branchName.length() > maxLength) {
            report(QString("Branch name must not exceed %1 characters").arg(maxLength));
            continue;
        }

        if (rule["requireTicketRef"].toBool()) {
            const QString pattern = rule["ticketRefPattern"].toString();
            if (!pattern.isEmpty() && !QRegularExpression(pattern).match(branchName).hasMatch())
                report(QString("Branch name must contain a ticket reference (%1)").arg(pattern));
        }
    }

    return violations;
}

RuleViolations BranchNameValidator::validateDeletion(const QString &branchName) const
{
    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        if (matchesAnyGlob(branchName, splitList(rule["protectedBranches"]))) {
            RuleViolation v = violation(rule, QString("Branch '%1' is protected and cannot be deleted")
                                                  .arg(branchName));
            v.blocking = true;
            return { v };
        }
    }
    return {};
}

bool BranchNameValidator::shouldAutoDeleteAfterMerge(const QString &branchName) const
{
    bool autoDelete = false;
    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        if (matchesAnyGlob(branchName, splitList(rule["protectedBranches"])))
            return false;

        autoDelete = autoDelete || rule["autoDeleteAfterMerge"].toBool();
    }
    return autoDelete;
}

void BranchNameValidator::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
