#include "FileRuleValidator.h"

#include <QHash>
#include <QJsonObject>
#include <QRegularExpression>

#include <algorithm>

using namespace RuleSupport;

namespace {

struct AddedLine
{
    QString path;
    int     lineNumber = 0;
    QString text;
};

struct StagedSnapshot
{
    QStringList            allPaths;          // every staged path, deletions included
    QStringList            contentPaths;      // added / modified / renamed / copied
    QHash<QString, qint64> sizes;
    QList<AddedLine>       addedLines;
    QStringList            missingFinalNewline;
};

QStringList nulSeparated(const QByteArray &data)
{
    QStringList items;
    for (const QByteArray &part : data.split('\0')) {
        if (!part.isEmpty())
            items << QString::fromUtf8(part);
    }
    return items;
}

void parseDiff(const QByteArray &diff, StagedSnapshot &snapshot)
{
    static const QRegularExpression hunkHeader("^@@ -\\d+(?:,\\d+)? \\+(\\d+)(?:,\\d+)? @@");

    QString currentPath;
    int newLine = 0;
    bool lastWasAdded = false;

    for (const QByteArray &raw : diff.split('\n')) {
        QString line = QString::fromUtf8(raw);

        if (line.startsWith("+++ ")) {
            currentPath = line.mid(4);
            if (currentPath.startsWith("b/"))
                currentPath = currentPath.mid(2);
            lastWasAdded = false;
            continue;
        }
        if (line.startsWith("--- ") || line.startsWith("diff --git"))
            continue;

        const QRegularExpressionMatch hunk = hunkHeader.match(line);
        if (hunk.hasMatch()) {
            newLine = hunk.captured(1).toInt();
            lastWasAdded = false;
            continue;
        }

        if (line.startsWith('+')) {
            if (line.endsWith('\r'))
                line.chop(1);
            snapshot.addedLines.append({ currentPath, newLine, line.mid(1) });
            ++newLine;
            lastWasAdded = true;
            continue;
        }

        if (line.startsWith("\\ No newline at end of file")) {
            if (lastWasAdded && !snapshot.missingFinalNewline.contains(currentPath))
                snapshot.missingFinalNewline << currentPath;
            continue;
        }

        lastWasAdded = false;
    }
}

StagedSnapshot readStagedChanges(const QString &repoPath, bool needContent, bool needSizes)
{
    StagedSnapshot snapshot;
    QByteArray output;

    if (GitCli::run(repoPath, { "diff", "--cached", "--name-only", "-z", "--no-renames" }, &output) == 0)
        snapshot.allPaths = nulSeparated(output);

    if (GitCli::run(repoPath, { "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR" }, &output) == 0)
        snapshot.contentPaths = nulSeparated(output);

    if (needSizes && !snapshot.contentPaths.isEmpty()) {
        QByteArray request;
        for (const QString &path : snapshot.contentPaths)
            request += ':' + path.toUtf8() + '\n';

        if (GitCli::run(repoPath, { "cat-file", "--batch-check=%(objectsize)" }, &output, request) == 0) {
            const QList<QByteArray> lines = output.split('\n');
            for (int i = 0; i < snapshot.contentPaths.size() && i < lines.size(); ++i) {
                bool ok = false;
                const qint64 size = lines.at(i).trimmed().toLongLong(&ok);
                if (ok)
                    snapshot.sizes.insert(snapshot.contentPaths.at(i), size);
            }
        }
    }

    if (needContent
        && GitCli::run(repoPath, { "-c", "core.quotepath=off", "diff", "--cached", "-U0", "--no-color",
                                   "--no-ext-diff", "--diff-filter=ACMR" }, &output, {}, 60000) == 0) {
        parseDiff(output, snapshot);
    }

    return snapshot;
}

QString location(const AddedLine &line)
{
    return QString("%1:%2").arg(line.path).arg(line.lineNumber);
}

} // namespace

bool FileRuleValidator::hasEnabledRules() const
{
    for (const QJsonValue &value : m_rules) {
        if (isRuleEnabled(value.toObject()))
            return true;
    }
    return false;
}

RuleViolations FileRuleValidator::validateStagedChanges(const QString &repoPath) const
{
    RuleViolations violations;
    if (repoPath.isEmpty() || !hasEnabledRules())
        return violations;

    bool needContent = false;
    bool needSizes = false;
    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;
        needContent = needContent || rule["noTrailingWhitespace"].toBool()
                      || rule["requireFinalNewline"].toBool()
                      || !splitList(rule["secretPatterns"]).isEmpty();
        needSizes = needSizes || intValue(rule, "maxFileSizeMb") > 0;
    }

    const StagedSnapshot snapshot = readStagedChanges(repoPath, needContent, needSizes);
    if (snapshot.allPaths.isEmpty())
        return violations;

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule))
            continue;

        auto report = [&](const QString &text) { violations << violation(rule, text); };

        const QStringList lockedFiles = splitList(rule["lockedFiles"]);
        for (const QString &path : snapshot.allPaths) {
            if (matchesAnyGlob(path, lockedFiles)) {
                report(QString("'%1' is locked and cannot be changed").arg(path));
                break;
            }
        }

        const QStringList extensions = splitList(rule["forbiddenExtensions"]);
        for (const QString &path : snapshot.contentPaths) {
            const QString fileName = path.section('/', -1);
            auto extensionMatches = [&](const QString &ext) {
                return fileName.endsWith(ext.startsWith('.') ? ext : '.' + ext, Qt::CaseInsensitive)
                       || fileName.compare(ext, Qt::CaseInsensitive) == 0;
            };
            if (std::any_of(extensions.begin(), extensions.end(), extensionMatches)) {
                report(QString("Files of this type may not be committed: %1").arg(path));
                break;
            }
        }

        const int maxSizeMb = intValue(rule, "maxFileSizeMb");
        if (maxSizeMb > 0) {
            const qint64 limit = qint64(maxSizeMb) * 1024 * 1024;
            for (auto it = snapshot.sizes.constBegin(); it != snapshot.sizes.constEnd(); ++it) {
                if (it.value() > limit) {
                    report(QString("'%1' is %2 MB, larger than the %3 MB limit")
                               .arg(it.key())
                               .arg(double(it.value()) / (1024 * 1024), 0, 'f', 1)
                               .arg(maxSizeMb));
                    break;
                }
            }
        }

        if (rule["noTrailingWhitespace"].toBool()) {
            for (const AddedLine &line : snapshot.addedLines) {
                if (line.text.endsWith(' ') || line.text.endsWith('\t')) {
                    report(QString("Trailing whitespace at %1").arg(location(line)));
                    break;
                }
            }
        }

        if (rule["requireFinalNewline"].toBool() && !snapshot.missingFinalNewline.isEmpty())
            report(QString("'%1' must end with a newline").arg(snapshot.missingFinalNewline.first()));

        const QStringList secretPatterns = splitList(rule["secretPatterns"]);
        bool secretFound = false;
        for (const QString &pattern : secretPatterns) {
            const QRegularExpression regex(pattern);
            if (!regex.isValid())
                continue;
            for (const AddedLine &line : snapshot.addedLines) {
                if (regex.match(line.text).hasMatch()) {
                    report(QString("Possible secret at %1").arg(location(line)));
                    secretFound = true;
                    break;
                }
            }
            if (secretFound)
                break;
        }
    }

    return violations;
}

void FileRuleValidator::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
