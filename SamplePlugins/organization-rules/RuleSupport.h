#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QList>
#include <QString>
#include <QStringList>

/*!
 * @brief One broken rule. Blocking violations abort the git action; the rest are warnings.
 */
struct RuleViolation
{
    QString ruleName;
    QString message;
    bool    blocking = true;

    QString text() const
    {
        return ruleName.isEmpty() ? message : QString("%1: %2").arg(ruleName, message);
    }
};

using RuleViolations = QList<RuleViolation>;

namespace RuleSupport {

//! Splits a comma separated rule field ("feat,fix, docs") into trimmed, non-empty items.
QStringList splitList(const QJsonValue &value);

//! The editor saves "enabled"; older rule files only carry "isActive".
bool isRuleEnabled(const QJsonObject &rule);

//! Severity 0 (Error) blocks the action, 1 (Warning) only reports it.
bool isBlocking(const QJsonObject &rule);

//! Numeric fields are stored either as JSON numbers or as strings.
int intValue(const QJsonObject &rule, const QString &key, int defaultValue = 0);

bool matchesAnyGlob(const QString &text, const QStringList &patterns);

RuleViolation violation(const QJsonObject &rule, const QString &message);

//! Resolves a path relative to the repository root.
QString resolveRepoPath(const QString &repoPath, const QString &path);

} // namespace RuleSupport

/*!
 * @brief Minimal git CLI runner used for checks libgit2 state is not exposed for
 * (staged diff, unpushed commits, signatures).
 */
namespace GitCli {

QString gitExecutable();

//! Git for Windows' sh.exe next to git, or the system sh elsewhere. Empty when none is found.
QString shellExecutable();

/*!
 * @brief Runs git in @p repoPath.
 * @return The process exit code, or -1 when git could not be started or timed out.
 */
int run(const QString &repoPath,
        const QStringList &args,
        QByteArray *output = nullptr,
        const QByteArray &input = {},
        int timeoutMs = 20000);

} // namespace GitCli
