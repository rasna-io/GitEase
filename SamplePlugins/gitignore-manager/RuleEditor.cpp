#include "RuleEditor.h"

#include "IgnoreFile.h"
#include "OperationResult.h"

#include <QDir>
#include <QHash>
#include <QSet>

#include <algorithm>
#include <functional>

namespace RuleEditor {

namespace {

//! Paths without trailing slashes and without empty entries.
QStringList cleanPaths(const QStringList &paths)
{
    QStringList result;

    for (QString path : paths) {
        while (path.endsWith(QLatin1Char('/'))) {
            path.chop(1);
        }

        if (!path.isEmpty()) {
            result << path;
        }
    }

    return result;
}

} // namespace

QVariantMap addPatterns(const QString &root, const QStringList &patterns)
{
    IgnoreFile file = IgnoreFile::read(root);
    QSet<QString> present = file.patterns();

    int added = 0;
    int skipped = 0;

    for (const QString &pattern : patterns) {
        const QString trimmed = pattern.trimmed();

        if (trimmed.isEmpty() || trimmed.contains(QLatin1Char('\n'))) {
            continue;
        }

        if (present.contains(trimmed)) {
            ++skipped;
            continue;
        }

        present.insert(trimmed);
        file.lines << trimmed;
        ++added;
    }

    if (added > 0) {
        QString error;
        if (!file.save(root, &error)) {
            return OperationResult::failure(error);
        }
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("added")] = added;
    result[QStringLiteral("skipped")] = skipped;
    return result;
}

QVariantMap planUnignore(const QStringList &paths, const QVariantList &hits)
{
    const QStringList queries = cleanPaths(paths);

    // Keyed by source and line, so one rule that covers many files is listed once.
    QHash<QString, QVariantMap> rules;
    QStringList order;
    QSet<QString> matched;

    for (const QVariant &value : hits) {
        const QVariantMap hit = value.toMap();

        const QString source = QDir::fromNativeSeparators(hit.value(QStringLiteral("source")).toString());
        const int line = hit.value(QStringLiteral("line")).toInt();
        const QString pattern = hit.value(QStringLiteral("pattern")).toString();
        QString path = hit.value(QStringLiteral("path")).toString();
        while (path.endsWith(QLatin1Char('/'))) {
            path.chop(1);
        }

        // A negation is the rule that un-ignores; there is nothing to remove.
        if (pattern.startsWith(QLatin1Char('!'))) {
            continue;
        }

        matched.insert(path);

        const QString key = source + QLatin1Char(':') + QString::number(line);
        QVariantMap rule = rules.value(key);

        if (rule.isEmpty()) {
            rule[QStringLiteral("line")] = line;
            rule[QStringLiteral("pattern")] = pattern;
            rule[QStringLiteral("source")] = source;
            rule[QStringLiteral("editable")] = source == QLatin1String(".gitignore");
            rule[QStringLiteral("paths")] = QStringList();
            order << key;
        }

        QStringList covered = rule.value(QStringLiteral("paths")).toStringList();
        covered << path;
        rule[QStringLiteral("paths")] = covered;
        rules.insert(key, rule);
    }

    QVariantList ruleList;
    for (const QString &key : std::as_const(order)) {
        ruleList << rules.value(key);
    }

    QStringList unresolved;
    for (const QString &path : queries) {
        if (!matched.contains(path)) {
            unresolved << path;
        }
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("rules")] = ruleList;
    result[QStringLiteral("unresolved")] = unresolved;
    return result;
}

QVariantMap removeRules(const QString &root, const QVariantList &rules)
{
    IgnoreFile file = IgnoreFile::read(root);
    if (!file.exists) {
        return OperationResult::failure(QStringLiteral(".gitignore does not exist"));
    }

    QList<int> indexes;

    for (const QVariant &value : rules) {
        const QVariantMap rule = value.toMap();
        const int index = rule.value(QStringLiteral("line")).toInt() - 1;
        const QString pattern = rule.value(QStringLiteral("pattern")).toString().trimmed();

        const bool inRange = index >= 0 && index < file.lines.size();
        if (!inRange || file.lines.at(index).trimmed() != pattern) {
            return OperationResult::failure(
                QStringLiteral(".gitignore changed since it was read. Refresh and try again."));
        }

        if (!indexes.contains(index)) {
            indexes << index;
        }
    }

    // Remove from the bottom so the remaining indexes stay valid.
    std::sort(indexes.begin(), indexes.end(), std::greater<int>());
    for (int index : std::as_const(indexes)) {
        file.lines.removeAt(index);
    }

    QString error;
    if (!file.save(root, &error)) {
        return OperationResult::failure(error);
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("removed")] = int(indexes.size());
    return result;
}

} // namespace RuleEditor
