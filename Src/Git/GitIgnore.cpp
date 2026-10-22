#include "GitIgnore.h"

#include "GitBranch.h"
#include "GitCommandText.h"
#include "GitFileStatus.h"
#include "GitIgnoreMatcher.h"
#include "GitStatus.h"
#include "GitUtils.h"

#include <QDir>
#include <QHash>
#include <git2.h>

namespace {

//! The last libgit2 error, or @p fallback when libgit2 has none.
QString lastGitError(const QString &fallback)
{
    const QString message = GitUtils::getLastError();
    return message.isEmpty() ? fallback : message;
}

// -- Status ------------------------------------------------------------------------------------

struct Entry
{
    QString path;
    QString status         = QStringLiteral("committed");
    bool    staged         = false;
    bool    isDir          = false;
    bool    ignored        = false;
    bool    trackedIgnored = false;
};

//! The status word for a libgit2 status entry. Conflicts and ignored files are not part of
//! GitFileStatus::Status, so those two are tested on the raw flags.
QString classify(const GitFileStatus &file)
{
    using FS = GitFileStatus;
    const unsigned int flags = static_cast<unsigned int>(file.status());

    if (flags & GIT_STATUS_CONFLICTED) {
        return QStringLiteral("conflicted");
    }

    if (flags & (FS::Modified | FS::TypeChange)) {
        return QStringLiteral("modified");
    }

    if (flags & (FS::Deleted | FS::StagedDeleted)) {
        return QStringLiteral("deleted");
    }

    if (flags & (FS::StagedRenamed | FS::Renamed)) {
        return QStringLiteral("renamed");
    }

    if (flags & FS::StagedNew) {
        return QStringLiteral("added");
    }

    if (flags & (FS::StagedModified | GIT_STATUS_INDEX_TYPECHANGE)) {
        return QStringLiteral("staged");
    }

    if (flags & FS::Untracked) {
        return QStringLiteral("untracked");
    }

    if (flags & GIT_STATUS_IGNORED) {
        return QStringLiteral("ignored");
    }

    return QStringLiteral("committed");
}

QVariantMap toVariant(const Entry &entry)
{
    QVariantMap map;
    map[QStringLiteral("path")] = entry.path;
    map[QStringLiteral("status")] = entry.status;
    map[QStringLiteral("staged")] = entry.staged;
    map[QStringLiteral("isDir")] = entry.isDir;
    map[QStringLiteral("ignored")] = entry.ignored;
    map[QStringLiteral("trackedIgnored")] = entry.trackedIgnored;
    return map;
}

} // namespace

GitIgnore::GitIgnore(QObject *parent)
    : IGitController(parent)
    , m_status(new GitStatus(this))
{
    // Handles are resolved per thread through activeRepo(), so the helper only needs to know
    // which repository this controller was given.
    connect(this, &IGitController::currentRepoChanged, this, [this]() {
        m_status->setCurrentRepo(currentRepo());
    });
}

GitResult GitIgnore::repositoryInfo()
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not open");
    }

    const QString root = IGitController::workdirOf(activeRepo());
    if (root.isEmpty()) {
        return GitResult(false, QVariant(), "This repository has no working directory");
    }

    QVariantMap info;
    info[QStringLiteral("root")] = root;
    info[QStringLiteral("branch")] = GitBranch::currentBranchName(activeRepo());
    return GitResult(true, info);
}

GitResult GitIgnore::scan()
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not open");
    }

    git_repository *repo = activeRepo();

    const QString root = IGitController::workdirOf(repo);
    if (root.isEmpty()) {
        return GitResult(false, QVariant(), "This repository has no working directory");
    }

    QHash<QString, Entry> entries;

    // Tracked files are clean until the status says otherwise.
    git_index *index = nullptr;
    if (git_repository_index(&index, repo) != GIT_OK || !index) {
        return GitResult(false, QVariant(), lastGitError(QStringLiteral("Could not read the index")));
    }

    const size_t indexCount = git_index_entrycount(index);
    for (size_t i = 0; i < indexCount; ++i) {
        const git_index_entry *item = git_index_get_byindex(index, i);
        if (!item || !item->path) {
            continue;
        }

        Entry entry;
        entry.path = QString::fromUtf8(item->path);
        entries.insert(entry.path, entry);
    }
    git_index_free(index);

    // Changed and untracked files: the same status the Commit page shows.
    const GitResult changes = m_status->status();
    if (!changes.success()) {
        return GitResult(false, QVariant(), changes.errorMessage());
    }

    // GitFileStatus::isStaged() leaves type changes out, so the mask is spelled out.
    const unsigned int indexFlags = GitFileStatus::StagedNew | GitFileStatus::StagedModified
                                    | GitFileStatus::StagedDeleted | GitFileStatus::StagedRenamed
                                    | GIT_STATUS_INDEX_TYPECHANGE;

    const QList<GitFileStatus> files = changes.data().value<QList<GitFileStatus>>();
    for (const GitFileStatus &file : files) {
        if (file.path().isEmpty()) {
            continue;
        }

        Entry entry;
        entry.path = file.path();
        entry.status = classify(file);
        entry.staged = (static_cast<unsigned int>(file.status()) & indexFlags) != 0;
        entries.insert(entry.path, entry);
    }

    // Ignored files are the one thing GitStatus leaves out. A folder that a rule ignores is one
    // entry (it is not recursed into); a folder that is only ignored because everything in it is
    // gets listed file by file, which needs the untracked folders to be walked as well. The
    // untracked files themselves were reported above and are skipped here.
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_WORKDIR_ONLY;
    opts.flags = GIT_STATUS_OPT_INCLUDE_IGNORED
                 | GIT_STATUS_OPT_INCLUDE_UNTRACKED
                 | GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS;

    git_status_list *list = nullptr;
    if (git_status_list_new(&list, repo, &opts) != GIT_OK || !list) {
        return GitResult(false, QVariant(), lastGitError(QStringLiteral("Could not read the status")));
    }

    const size_t count = git_status_list_entrycount(list);
    for (size_t i = 0; i < count; ++i) {
        const git_status_entry *item = git_status_byindex(list, i);
        if (!item || !(item->status & GIT_STATUS_IGNORED) || !item->index_to_workdir
            || !item->index_to_workdir->new_file.path) {
            continue;
        }

        Entry entry;
        entry.path = QString::fromUtf8(item->index_to_workdir->new_file.path);
        entry.status = QStringLiteral("ignored");
        entry.ignored = true;
        entry.isDir = entry.path.endsWith(QLatin1Char('/'));
        entries.insert(entry.path, entry);
    }
    git_status_list_free(list);

    // Tracked files that a rule matches: the rule has no effect on them until they are untracked.
    for (auto it = entries.begin(); it != entries.end(); ++it) {
        Entry &entry = it.value();
        if (entry.ignored || entry.status == QLatin1String("untracked")) {
            continue;
        }

        int ignored = 0;
        const QByteArray path = entry.path.toUtf8();
        if (git_ignore_path_is_ignored(&ignored, repo, path.constData()) == GIT_OK && ignored) {
            entry.trackedIgnored = true;
        }
    }

    QVariantList entryList;
    entryList.reserve(int(entries.size()));
    for (const Entry &entry : std::as_const(entries)) {
        entryList << toVariant(entry);
    }

    QVariantMap data;
    data[QStringLiteral("root")] = root;
    data[QStringLiteral("branch")] = GitBranch::currentBranchName(repo);
    data[QStringLiteral("entries")] = entryList;

    emitGitCommand(GitCommandText::statusIgnored());

    return GitResult(true, data);
}

GitResult GitIgnore::checkIgnore(const QStringList &paths)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not open");
    }

    git_repository *repo = activeRepo();

    const QString root = IGitController::workdirOf(repo);
    if (root.isEmpty()) {
        return GitResult(false, QVariant(), "This repository has no working directory");
    }

    GitIgnoreMatcher::Settings settings;
    settings.root = root;

    if (const char *gitDir = git_repository_path(repo)) {
        settings.infoExcludePath = QDir::cleanPath(QString::fromUtf8(gitDir)) + QStringLiteral("/info/exclude");
    }

    git_config *config = nullptr;
    if (git_repository_config_snapshot(&config, repo) == GIT_OK && config) {
        int ignoreCase = 0;
        if (git_config_get_bool(&ignoreCase, config, "core.ignorecase") == GIT_OK) {
            settings.ignoreCase = ignoreCase != 0;
        }

        const char *excludes = nullptr;
        if (git_config_get_string(&excludes, config, "core.excludesfile") == GIT_OK && excludes) {
            settings.globalExcludesPath = QString::fromUtf8(excludes);
        }

        git_config_free(config);
    }

    GitIgnoreMatcher finder(settings);
    QVariantList hits;

    for (const QString &path : paths) {
        if (path.isEmpty()) {
            continue;
        }

        // libgit2 decides whether the path is ignored; the finder only names the rule.
        int ignored = 0;
        const QByteArray utf8 = path.toUtf8();
        if (git_ignore_path_is_ignored(&ignored, repo, utf8.constData()) != GIT_OK) {
            return GitResult(false, QVariant(), lastGitError(QStringLiteral("Could not check the rules")));
        }

        if (!ignored) {
            continue;
        }

        const GitIgnoreMatcher::Match match = finder.find(path);
        if (!match.found || match.negated) {
            continue;
        }

        QVariantMap hit;
        hit[QStringLiteral("path")] = path;
        hit[QStringLiteral("source")] = match.source;
        hit[QStringLiteral("line")] = match.line;
        hit[QStringLiteral("pattern")] = match.pattern;
        hits << hit;
    }

    emitGitCommand(GitCommandText::checkIgnore());

    return GitResult(true, hits);
}
