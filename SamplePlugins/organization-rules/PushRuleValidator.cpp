#include "PushRuleValidator.h"

#include <QJsonObject>
#include <QRegularExpression>

#include <algorithm>

using namespace RuleSupport;

namespace {

struct OutgoingCommit
{
    QString hash;
    QString signature;   // git's %G? code, "N" means unsigned
    QString subject;
};

QStringList outgoingRange(const QString &remote, const QString &branch)
{
    return { "refs/heads/" + branch, "--not", "--remotes=" + remote };
}

//! A remote without any tracking refs has never been fetched or pushed; every commit would look new.
bool remoteHasTrackingRefs(const QString &repoPath, const QString &remote)
{
    QByteArray output;
    const int code = GitCli::run(repoPath, { "for-each-ref", "--count=1", "--format=%(refname)",
                                             "refs/remotes/" + remote + "/" }, &output);
    return code == 0 && !output.trimmed().isEmpty();
}

QList<OutgoingCommit> outgoingCommits(const QString &repoPath, const QStringList &range, bool withSignatures)
{
    QList<OutgoingCommit> commits;
    const QString format = withSignatures ? "--format=%H%x09%G?%x09%s" : "--format=%H%x09-%x09%s";

    QByteArray output;
    if (GitCli::run(repoPath, QStringList{ "log", format } + range, &output, {}, 60000) != 0)
        return commits;

    for (const QByteArray &raw : output.split('\n')) {
        const QList<QByteArray> parts = raw.split('\t');
        if (parts.size() < 3)
            continue;
        commits.append({ QString::fromUtf8(parts[0]),
                         QString::fromUtf8(parts[1]),
                         QString::fromUtf8(raw.mid(parts[0].size() + parts[1].size() + 2)) });
    }
    return commits;
}

QString shortHash(const QString &hash)
{
    return hash.left(8);
}

} // namespace

RuleViolations PushRuleValidator::validatePush(const QString &repoPath,
                                               const QString &remote,
                                               const QString &branch,
                                               bool force) const
{
    RuleViolations violations;
    if (repoPath.isEmpty() || branch.isEmpty())
        return violations;

    const QStringList range = outgoingRange(remote, branch);
    bool rangeLoaded = false;
    bool hasTrackingRefs = false;
    bool signaturesLoaded = false;
    QList<OutgoingCommit> commits;

    auto ensureCommits = [&](bool withSignatures) {
        if (!rangeLoaded) {
            hasTrackingRefs = remoteHasTrackingRefs(repoPath, remote);
            rangeLoaded = true;
        }
        if (hasTrackingRefs && (commits.isEmpty() || (withSignatures && !signaturesLoaded))) {
            commits = outgoingCommits(repoPath, range, withSignatures);
            signaturesLoaded = signaturesLoaded || withSignatures;
        }
        return hasTrackingRefs;
    };

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        auto report = [&](const QString &text) { violations << violation(rule, text); };

        if (force && matchesAnyGlob(branch, splitList(rule["blockForcePushPatterns"]))) {
            report(QString("Force push to '%1' is not allowed").arg(branch));
            continue;
        }

        const bool needGpg = rule["requireGpgSignature"].toBool();
        const bool needWip = rule["blockWipCommits"].toBool();
        const bool needMarkers = rule["blockConflictMarkers"].toBool();
        const int maxCommits = intValue(rule, "maxCommitsPerPush");

        if (!needGpg && !needWip && !needMarkers && maxCommits <= 0)
            continue;

        if (!ensureCommits(needGpg) || commits.isEmpty())
            continue;

        if (maxCommits > 0 && commits.size() > maxCommits) {
            report(QString("Pushing %1 commits, more than the allowed %2")
                       .arg(commits.size()).arg(maxCommits));
            continue;
        }

        if (needGpg) {
            auto unsigned_ = std::find_if(commits.begin(), commits.end(), [](const OutgoingCommit &c) {
                return c.signature == "N";
            });
            if (unsigned_ != commits.end()) {
                report(QString("Commit %1 \"%2\" is not GPG signed")
                           .arg(shortHash(unsigned_->hash), unsigned_->subject));
                continue;
            }
        }

        if (needWip) {
            static const QRegularExpression wip("^(wip\\b|\\[wip\\]|fixup!|squash!|amend!)",
                                                QRegularExpression::CaseInsensitiveOption);
            auto wipCommit = std::find_if(commits.begin(), commits.end(), [](const OutgoingCommit &c) {
                return wip.match(c.subject.trimmed()).hasMatch();
            });
            if (wipCommit != commits.end()) {
                report(QString("Work-in-progress commit %1 \"%2\" must be squashed before pushing")
                           .arg(shortHash(wipCommit->hash), wipCommit->subject));
                continue;
            }
        }

        if (needMarkers) {
            QByteArray output;
            const QStringList args = QStringList{ "log", "-p", "-U0", "--no-color", "--no-ext-diff",
                                                  "--no-merges", "--format=commit %H" } + range;
            if (GitCli::run(repoPath, args, &output, {}, 60000) == 0) {
                static const QRegularExpression marker("^\\+(<<<<<<<|>>>>>>>)( |$)");
                QString commit;
                for (const QByteArray &raw : output.split('\n')) {
                    const QString line = QString::fromUtf8(raw);
                    if (line.startsWith("commit ")) {
                        commit = line.mid(7);
                        continue;
                    }
                    if (!line.startsWith("+++") && marker.match(line).hasMatch()) {
                        report(QString("Commit %1 contains merge conflict markers").arg(shortHash(commit)));
                        break;
                    }
                }
            }
        }
    }

    return violations;
}

void PushRuleValidator::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
