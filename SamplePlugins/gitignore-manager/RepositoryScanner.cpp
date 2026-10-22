#include "RepositoryScanner.h"

#include "IgnoreFile.h"
#include "OperationResult.h"
#include "TemplateStore.h"

#include <QHash>
#include <QStringView>

#include <algorithm>
#include <vector>

namespace RepositoryScanner {

namespace {

//! Longest file list handed to the UI; the status counts still cover everything.
constexpr int kMaxFiles = 20000;

struct Entry
{
    QString path;
    QString status         = QStringLiteral("committed");
    bool    staged         = false;
    bool    isDir          = false;
    bool    ignored        = false;
    bool    trackedIgnored = false;
};

bool isHiddenPath(const QString &path)
{
    const QList<QStringView> parts = QStringView(path).split(QLatin1Char('/'), Qt::SkipEmptyParts);

    for (const QStringView part : parts) {
        if (part.startsWith(QLatin1Char('.'))) {
            return true;
        }
    }

    return false;
}

QVariantMap toVariant(const Entry &entry)
{
    QString trimmed = entry.path;
    if (trimmed.endsWith(QLatin1Char('/'))) {
        trimmed.chop(1);
    }

    const int slash = trimmed.lastIndexOf(QLatin1Char('/'));

    QVariantMap map;
    map[QStringLiteral("path")] = entry.path;
    map[QStringLiteral("name")] = slash < 0 ? trimmed : trimmed.mid(slash + 1);
    map[QStringLiteral("dir")] = slash < 0 ? QString() : trimmed.left(slash);
    map[QStringLiteral("status")] = entry.status;
    map[QStringLiteral("staged")] = entry.staged;
    map[QStringLiteral("isDir")] = entry.isDir;
    map[QStringLiteral("ignored")] = entry.ignored;
    map[QStringLiteral("trackedIgnored")] = entry.trackedIgnored;
    map[QStringLiteral("hidden")] = isHiddenPath(entry.path);
    return map;
}

//! Counts per status, plus "trackedIgnored", "hidden" and "total". Covers every entry.
QVariantMap countEntries(const QHash<QString, Entry> &entries)
{
    QVariantMap counts;

    const QStringList statuses = {
        QStringLiteral("committed"), QStringLiteral("modified"), QStringLiteral("staged"),
        QStringLiteral("added"), QStringLiteral("deleted"), QStringLiteral("renamed"),
        QStringLiteral("conflicted"), QStringLiteral("untracked"), QStringLiteral("ignored")
    };
    for (const QString &status : statuses) {
        counts[status] = 0;
    }

    int trackedIgnored = 0;
    int hidden = 0;

    for (const Entry &entry : entries) {
        counts[entry.status] = counts.value(entry.status).toInt() + 1;

        if (entry.trackedIgnored) {
            ++trackedIgnored;
        }

        if (isHiddenPath(entry.path)) {
            ++hidden;
        }
    }

    counts[QStringLiteral("trackedIgnored")] = trackedIgnored;
    counts[QStringLiteral("hidden")] = hidden;
    counts[QStringLiteral("total")] = int(entries.size());
    return counts;
}

//! The list handed to the UI: files that need attention first, then clean ones up to the cap.
std::vector<Entry> selectForDisplay(const QHash<QString, Entry> &entries, bool *truncated)
{
    std::vector<Entry> attention;
    std::vector<Entry> clean;

    for (const Entry &entry : entries) {
        const bool isClean = entry.status == QLatin1String("committed") && !entry.trackedIgnored;

        if (isClean) {
            clean.push_back(entry);
        } else {
            attention.push_back(entry);
        }
    }

    const auto byPath = [](const Entry &a, const Entry &b) {
        return QString::compare(a.path, b.path, Qt::CaseInsensitive) < 0;
    };
    std::sort(clean.begin(), clean.end(), byPath);

    std::vector<Entry> shown = std::move(attention);
    *truncated = false;

    for (const Entry &entry : clean) {
        if (int(shown.size()) >= kMaxFiles) {
            *truncated = true;
            break;
        }

        shown.push_back(entry);
    }

    std::sort(shown.begin(), shown.end(), byPath);
    return shown;
}

} // namespace

QVariantMap analyze(const QVariantMap &hostScan)
{
    const QString root = hostScan.value(QStringLiteral("root")).toString();
    if (root.isEmpty()) {
        return OperationResult::failure(QStringLiteral("This folder is not a Git repository"));
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("root")] = root;
    result[QStringLiteral("branch")] = hostScan.value(QStringLiteral("branch"), QStringLiteral("HEAD"));

    QHash<QString, Entry> entries;

    const QVariantList raw = hostScan.value(QStringLiteral("entries")).toList();
    entries.reserve(raw.size());

    for (const QVariant &value : raw) {
        const QVariantMap map = value.toMap();

        Entry entry;
        entry.path = map.value(QStringLiteral("path")).toString();
        if (entry.path.isEmpty()) {
            continue;
        }

        entry.status = map.value(QStringLiteral("status")).toString();
        entry.staged = map.value(QStringLiteral("staged")).toBool();
        entry.isDir = map.value(QStringLiteral("isDir")).toBool();
        entry.ignored = map.value(QStringLiteral("ignored")).toBool();
        entry.trackedIgnored = map.value(QStringLiteral("trackedIgnored")).toBool();
        entries.insert(entry.path, entry);
    }

    bool truncated = false;
    const std::vector<Entry> shown = selectForDisplay(entries, &truncated);

    QVariantList files;
    files.reserve(int(shown.size()));
    for (const Entry &entry : shown) {
        files << toVariant(entry);
    }

    result[QStringLiteral("files")] = files;
    result[QStringLiteral("counts")] = countEntries(entries);
    result[QStringLiteral("truncated")] = truncated;

    const IgnoreFile ignoreFile = IgnoreFile::read(root);
    result[QStringLiteral("hasGitignore")] = ignoreFile.exists;
    result[QStringLiteral("gitignoreContent")] = ignoreFile.lines.join(QLatin1Char('\n'));
    result[QStringLiteral("eol")] = ignoreFile.eol == QLatin1String("\r\n") ? QStringLiteral("CRLF")
                                                                           : QStringLiteral("LF");
    result[QStringLiteral("appliedTemplates")] = TemplateStore::appliedIds(ignoreFile.lines);

    return result;
}

} // namespace RepositoryScanner
