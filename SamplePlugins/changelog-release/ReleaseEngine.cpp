#include "ReleaseEngine.h"

#include <QDate>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QPointer>
#include <QProcess>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>

#include <functional>

namespace {

// ── git command line ─────────────────────────────────────────────────────────────────────────

QString gitExecutable()
{
    static const QString cached = [] {
        QString path = QStandardPaths::findExecutable("git");
#ifdef Q_OS_WIN
        if (path.isEmpty()) {
            for (const QString &candidate : { QStringLiteral("C:/Program Files/Git/cmd/git.exe"),
                                              QStringLiteral("C:/Program Files (x86)/Git/cmd/git.exe") }) {
                if (QFileInfo::exists(candidate)) {
                    path = candidate;
                    break;
                }
            }
        }
#endif
        return path;
    }();
    return cached;
}

struct GitOutput
{
    int        exitCode = -1;
    QString    out;
    QString    err;
    bool       ok() const { return exitCode == 0; }
};

GitOutput runGit(const QString &repoPath, const QStringList &args, int timeoutMs = 30000)
{
    GitOutput result;
    const QString git = gitExecutable();
    if (git.isEmpty()) {
        result.err = QStringLiteral("git was not found on PATH");
        return result;
    }

    QProcess process;
    process.setWorkingDirectory(repoPath);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("GIT_TERMINAL_PROMPT"), QStringLiteral("0"));
    env.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    process.setProcessEnvironment(env);

    process.start(git, QStringList{ QStringLiteral("-c"), QStringLiteral("core.quotepath=off") } + args);
    if (!process.waitForStarted(5000)) {
        result.err = QStringLiteral("Could not start git");
        return result;
    }
    process.closeWriteChannel();

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(1000);
        result.err = QStringLiteral("git timed out");
        return result;
    }

    result.out = QString::fromUtf8(process.readAllStandardOutput());
    result.err = QString::fromUtf8(process.readAllStandardError());
    result.exitCode = process.exitStatus() == QProcess::NormalExit ? process.exitCode() : -1;
    return result;
}

// ── Semantic versions ────────────────────────────────────────────────────────────────────────

const QRegularExpression &semverPattern()
{
    static const QRegularExpression re(
        QStringLiteral(R"(^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$)"));
    return re;
}

struct SemVer
{
    int     major = 0;
    int     minor = 0;
    int     patch = 0;
    QString pre;
    bool    valid = false;

    static SemVer parse(const QString &text)
    {
        SemVer v;
        const auto m = semverPattern().match(text);
        if (!m.hasMatch())
            return v;
        v.major = m.captured(1).toInt();
        v.minor = m.captured(2).toInt();
        v.patch = m.captured(3).toInt();
        v.pre   = m.captured(4);
        v.valid = true;
        return v;
    }

    QString toString() const
    {
        QString s = QStringLiteral("%1.%2.%3").arg(major).arg(minor).arg(patch);
        if (!pre.isEmpty())
            s += QLatin1Char('-') + pre;
        return s;
    }
};

int comparePre(const QString &a, const QString &b)
{
    if (a == b)
        return 0;
    if (a.isEmpty())
        return 1;       // a release ranks above its pre-releases
    if (b.isEmpty())
        return -1;

    const QStringList pa = a.split(QLatin1Char('.'));
    const QStringList pb = b.split(QLatin1Char('.'));
    for (int i = 0; i < qMin(pa.size(), pb.size()); ++i) {
        bool na = false, nb = false;
        const qlonglong ia = pa[i].toLongLong(&na);
        const qlonglong ib = pb[i].toLongLong(&nb);
        if (na && nb) {
            if (ia != ib)
                return ia < ib ? -1 : 1;
        } else if (na != nb) {
            return na ? -1 : 1;
        } else if (pa[i] != pb[i]) {
            return pa[i] < pb[i] ? -1 : 1;
        }
    }
    return pa.size() == pb.size() ? 0 : (pa.size() < pb.size() ? -1 : 1);
}

int compare(const SemVer &a, const SemVer &b)
{
    if (a.major != b.major) return a.major < b.major ? -1 : 1;
    if (a.minor != b.minor) return a.minor < b.minor ? -1 : 1;
    if (a.patch != b.patch) return a.patch < b.patch ? -1 : 1;
    return comparePre(a.pre, b.pre);
}

//! Splits "v1.2.3" into prefix "v" and version "1.2.3". Returns false when it is not a version tag.
bool splitTag(const QString &tag, QString *prefix, SemVer *version)
{
    static const QRegularExpression re(QStringLiteral(R"(^([A-Za-z_\-/]*)(\d+\.\d+\.\d+.*)$)"));
    const auto m = re.match(tag);
    if (!m.hasMatch())
        return false;
    const SemVer v = SemVer::parse(m.captured(2));
    if (!v.valid)
        return false;
    *prefix = m.captured(1);
    *version = v;
    return true;
}

// ── Conventional commits ─────────────────────────────────────────────────────────────────────

QVariantMap parseCommit(const QStringList &fields)
{
    static const QRegularExpression header(
        QStringLiteral(R"(^([A-Za-z]+)(?:\(([^()]*)\))?(!)?:\s+(.+)$)"));
    static const QRegularExpression revertHeader(QStringLiteral(R"re(^Revert "(.+)"$)re"));
    static const QRegularExpression breakingNote(
        QStringLiteral(R"(^BREAKING[ -]CHANGE:\s*(.+)$)"), QRegularExpression::MultilineOption);

    const QString subject = fields.value(4).trimmed();
    const QString body    = fields.value(5).trimmed();

    QVariantMap commit;
    commit["hash"]      = fields.value(0);
    commit["shortHash"] = fields.value(1);
    commit["author"]    = fields.value(2);
    commit["date"]      = fields.value(3);
    commit["header"]    = subject;
    commit["body"]      = body;

    QString type, scope, description = subject;
    bool breaking = false;

    const auto m = header.match(subject);
    if (m.hasMatch()) {
        type        = m.captured(1).toLower();
        scope       = m.captured(2).trimmed();
        breaking    = !m.captured(3).isEmpty();
        description = m.captured(4).trimmed();
    } else if (const auto r = revertHeader.match(subject); r.hasMatch()) {
        type        = QStringLiteral("revert");
        description = r.captured(1);
    }

    const auto note = breakingNote.match(body);
    if (note.hasMatch()) {
        breaking = true;
        commit["breakingNote"] = note.captured(1).trimmed();
    }

    commit["type"]        = type;
    commit["scope"]       = scope;
    commit["subject"]     = description;
    commit["breaking"]    = breaking;
    commit["conventional"] = !type.isEmpty();
    return commit;
}

// ── Remote URLs ──────────────────────────────────────────────────────────────────────────────

//! Converts a remote URL into the web URL of the project, e.g. git@github.com:o/r.git -> https://github.com/o/r
QString webUrlFromRemote(const QString &remote)
{
    QString url = remote.trimmed();
    if (url.isEmpty())
        return {};

    static const QRegularExpression scp(QStringLiteral(R"(^[\w.-]+@([^:/]+):(.+)$)"));
    static const QRegularExpression full(QStringLiteral(R"(^(?:https?|ssh|git)://(?:[^@/]+@)?([^/:]+)(?::\d+)?/(.+)$)"));

    QString host, path;
    if (const auto m = full.match(url); m.hasMatch()) {
        host = m.captured(1);
        path = m.captured(2);
    } else if (const auto s = scp.match(url); s.hasMatch()) {
        host = s.captured(1);
        path = s.captured(2);
    } else {
        return {};
    }

    if (path.endsWith(QLatin1Char('/')))
        path.chop(1);
    if (path.endsWith(QStringLiteral(".git")))
        path.chop(4);
    return QStringLiteral("https://%1/%2").arg(host, path);
}

QString providerFromUrl(const QString &webUrl)
{
    const QString host = QUrl(webUrl).host().toLower();
    if (host.contains(QStringLiteral("github")))
        return QStringLiteral("github");
    if (host.contains(QStringLiteral("gitlab")))
        return QStringLiteral("gitlab");
    if (host == QStringLiteral("bitbucket.org"))
        return QStringLiteral("bitbucket");
    return {};
}

// ── Rendering ────────────────────────────────────────────────────────────────────────────────

struct Section
{
    QString type;
    QString title;
};

const QList<Section> &sections()
{
    static const QList<Section> list = {
        { QStringLiteral("feat"),     QStringLiteral("Features") },
        { QStringLiteral("fix"),      QStringLiteral("Bug Fixes") },
        { QStringLiteral("perf"),     QStringLiteral("Performance") },
        { QStringLiteral("revert"),   QStringLiteral("Reverts") },
        { QStringLiteral("refactor"), QStringLiteral("Refactoring") },
        { QStringLiteral("docs"),     QStringLiteral("Documentation") },
        { QStringLiteral("style"),    QStringLiteral("Styles") },
        { QStringLiteral("test"),     QStringLiteral("Tests") },
        { QStringLiteral("build"),    QStringLiteral("Build System") },
        { QStringLiteral("ci"),       QStringLiteral("Continuous Integration") },
        { QStringLiteral("chore"),    QStringLiteral("Chores") },
    };
    return list;
}

QString commitUrl(const QString &webUrl, const QString &provider, const QString &hash)
{
    if (provider == QStringLiteral("github"))    return webUrl + QStringLiteral("/commit/") + hash;
    if (provider == QStringLiteral("gitlab"))    return webUrl + QStringLiteral("/-/commit/") + hash;
    if (provider == QStringLiteral("bitbucket")) return webUrl + QStringLiteral("/commits/") + hash;
    return {};
}

QString compareUrl(const QString &webUrl, const QString &provider, const QString &from, const QString &to)
{
    if (provider == QStringLiteral("github")) return QStringLiteral("%1/compare/%2...%3").arg(webUrl, from, to);
    if (provider == QStringLiteral("gitlab")) return QStringLiteral("%1/-/compare/%2...%3").arg(webUrl, from, to);
    return {};
}

//! Reads the non-merge commits in \a range into \a result (commits, counts, truncated). Returns an error message on failure.
QString readCommits(const QString &repoPath, const QString &range, QVariantMap *result)
{
    constexpr int maxCommits = 1000;
    const QStringList logArgs = { "log", "--no-merges", QStringLiteral("-n%1").arg(maxCommits + 1),
                                  "--date=short", "--format=%H%x1f%h%x1f%an%x1f%ad%x1f%s%x1f%b%x1e", range };

    const GitOutput log = runGit(repoPath, logArgs, 60000);
    if (!log.ok())
        return log.err.trimmed().isEmpty() ? QStringLiteral("Could not read the commit history") : log.err.trimmed();

    QVariantList commits;
    int features = 0, fixes = 0, breaking = 0, other = 0;
    const QStringList records = log.out.split(QChar(0x1e), Qt::SkipEmptyParts);
    for (const QString &record : records) {
        const QString trimmed = record.trimmed();
        if (trimmed.isEmpty())
            continue;
        if (commits.size() >= maxCommits) {
            (*result)["truncated"] = true;
            break;
        }

        const QVariantMap commit = parseCommit(trimmed.split(QChar(0x1f)));
        const QString type = commit["type"].toString();
        if (commit["breaking"].toBool())        ++breaking;
        if (type == QStringLiteral("feat"))     ++features;
        else if (type == QStringLiteral("fix")) ++fixes;
        else                                    ++other;
        commits.append(commit);
    }

    QVariantMap counts;
    counts["total"]    = commits.size();
    counts["features"] = features;
    counts["fixes"]    = fixes;
    counts["breaking"] = breaking;
    counts["other"]    = other;
    (*result)["commits"] = commits;
    (*result)["counts"]  = counts;
    return {};
}

QString linkIssues(QString text, const QString &webUrl, const QString &provider)
{
    QString base;
    if (provider == QStringLiteral("github"))
        base = webUrl + QStringLiteral("/issues/");
    else if (provider == QStringLiteral("gitlab"))
        base = webUrl + QStringLiteral("/-/issues/");
    if (base.isEmpty())
        return text;

    static const QRegularExpression issue(QStringLiteral(R"((^|[\s(])#(\d+)\b)"));
    return text.replace(issue, QStringLiteral("\\1[#\\2](") + base + QStringLiteral("\\2)"));
}

} // namespace

// ─────────────────────────────────────────────────────────────────────────────────────────────

ReleaseEngine::ReleaseEngine(QObject *parent)
    : QObject(parent)
{
}

void ReleaseEngine::setRepoPath(const QString &path)
{
    if (m_repoPath == path)
        return;
    m_repoPath = path;
    ++m_generation;
    emit repoPathChanged();
}

void ReleaseEngine::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void ReleaseEngine::setPushing(bool pushing)
{
    if (m_pushing == pushing)
        return;
    m_pushing = pushing;
    emit pushingChanged();
}

void ReleaseEngine::analyze()
{
    const int generation = ++m_generation;
    const QString repoPath = m_repoPath;
    setBusy(true);

    auto *watcher = new QFutureWatcher<QVariantMap>(this);
    QPointer<ReleaseEngine> self(this);
    connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [self, watcher, generation]() {
        const QVariantMap result = watcher->result();
        watcher->deleteLater();
        if (!self || generation != self->m_generation)
            return;
        self->setBusy(false);
        emit self->analyzed(result);
    });
    watcher->setFuture(QtConcurrent::run(&ReleaseEngine::analyzeRepository, repoPath));
}

QVariantMap ReleaseEngine::analyzeRepository(const QString &repoPath)
{
    QVariantMap result;
    auto fail = [&result](const QString &message) {
        result["success"] = false;
        result["errorMessage"] = message;
        return result;
    };

    if (repoPath.isEmpty() || !QDir(repoPath).exists())
        return fail(QStringLiteral("No repository is open"));

    if (!runGit(repoPath, { "rev-parse", "--verify", "--quiet", "HEAD" }).ok())
        return fail(QStringLiteral("This repository has no commits yet"));

    result["headHash"] = runGit(repoPath, { "rev-parse", "HEAD" }).out.trimmed();
    result["branch"]   = runGit(repoPath, { "rev-parse", "--abbrev-ref", "HEAD" }).out.trimmed();

    // Tags
    QStringList allTags = runGit(repoPath, { "tag", "--list" }).out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (QString &tag : allTags)
        tag = tag.trimmed();
    result["existingTags"] = allTags;

    QString lastTag, tagPrefix = QStringLiteral("v");
    SemVer lastVersion;
    QString lastTagDate;
    QList<QPair<SemVer, QVariantMap>> releases;
    const QStringList merged = runGit(repoPath, { "for-each-ref", "--merged", "HEAD",
                                                  "--format=%(refname:short)%1f%(creatordate:short)%1f%(objecttype)%1f%(subject)",
                                                  "refs/tags" }).out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &line : merged) {
        const QStringList fields = line.trimmed().split(QChar(0x1f));
        const QString tag = fields.value(0);
        QString prefix;
        SemVer version;
        if (!splitTag(tag, &prefix, &version))
            continue;

        QVariantMap release;
        release["tag"]        = tag;
        release["version"]    = version.toString();
        release["date"]       = fields.value(1);
        release["annotated"]  = fields.value(2) == QStringLiteral("tag");
        release["subject"]    = fields.value(3);
        release["prerelease"] = !version.pre.isEmpty();
        releases.append({ version, release });

        if (!lastVersion.valid || compare(version, lastVersion) > 0) {
            lastVersion = version;
            lastTag = tag;
            lastTagDate = fields.value(1);
            tagPrefix = prefix;
        }
    }

    std::sort(releases.begin(), releases.end(), [](const auto &a, const auto &b) {
        return compare(a.first, b.first) > 0;
    });
    constexpr int maxReleases = 100;
    QVariantList releaseList;
    for (int i = 0; i < releases.size() && i < maxReleases; ++i)
        releaseList.append(releases[i].second);

    result["lastTag"]      = lastTag;
    result["lastVersion"]  = lastVersion.valid ? lastVersion.toString() : QStringLiteral("0.0.0");
    result["tagPrefix"]    = tagPrefix;
    result["releaseCount"] = releases.size();
    result["releases"]     = releaseList;
    if (!lastTag.isEmpty())
        result["lastTagDate"] = lastTagDate;

    // Commits since the last release
    const QString logError = readCommits(repoPath, lastTag.isEmpty() ? QStringLiteral("HEAD") : lastTag + QStringLiteral("..HEAD"), &result);
    if (!logError.isEmpty())
        return fail(logError);

    const QVariantMap counts = result["counts"].toMap();
    const int breaking = counts["breaking"].toInt();
    const int features = counts["features"].toInt();

    // Suggested next version
    QString bump = QStringLiteral("patch");
    if (breaking > 0)
        bump = lastVersion.valid && lastVersion.major == 0 ? QStringLiteral("minor") : QStringLiteral("major");
    else if (features > 0)
        bump = QStringLiteral("minor");
    result["suggestedBump"] = bump;

    QString suggested;
    if (!lastVersion.valid) {
        suggested = breaking > 0 ? QStringLiteral("1.0.0") : QStringLiteral("0.1.0");
    } else {
        SemVer next = lastVersion;
        if (!next.pre.isEmpty()) {
            next.pre.clear();       // 1.3.0-beta.2 is released as 1.3.0
        } else if (bump == QStringLiteral("major")) {
            ++next.major; next.minor = 0; next.patch = 0;
        } else if (bump == QStringLiteral("minor")) {
            ++next.minor; next.patch = 0;
        } else {
            ++next.patch;
        }
        suggested = next.toString();
    }
    result["suggestedVersion"] = suggested;

    // Working tree
    result["stagedFiles"] = runGit(repoPath, { "diff", "--cached", "--name-only" }).out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    // Remote
    const GitOutput origin = runGit(repoPath, { "remote", "get-url", "origin" });
    result["hasOrigin"] = origin.ok();
    const QString webUrl = origin.ok() ? webUrlFromRemote(origin.out) : QString();
    result["webUrl"]   = webUrl;
    result["provider"] = providerFromUrl(webUrl);

    result["success"] = true;
    return result;
}

QString ReleaseEngine::bumpVersion(const QString &version, const QString &bump) const
{
    SemVer v = SemVer::parse(version);
    if (!v.valid)
        return {};

    // A pre-release is promoted to its own release when that already satisfies the bump,
    // e.g. 2.0.0-rc.1 -> 2.0.0 for major and 1.3.0-beta.2 -> 1.3.0 for minor or patch.
    const bool pre = !v.pre.isEmpty();
    v.pre.clear();

    if (bump == QStringLiteral("major")) {
        if (!(pre && v.minor == 0 && v.patch == 0)) {
            ++v.major; v.minor = 0; v.patch = 0;
        }
    } else if (bump == QStringLiteral("minor")) {
        if (!(pre && v.patch == 0)) {
            ++v.minor; v.patch = 0;
        }
    } else if (!pre) {
        ++v.patch;
    }
    return v.toString();
}

bool ReleaseEngine::isValidVersion(const QString &version) const
{
    return SemVer::parse(version.trimmed()).valid;
}

QString ReleaseEngine::renderNotes(const QVariantMap &release) const
{
    const QString version     = release.value("version").toString();
    const QString tagName     = release.value("tagName").toString();
    const QString previousTag = release.value("previousTag").toString();
    const QString webUrl      = release.value("webUrl").toString();
    const QString provider    = release.value("provider").toString();
    const bool includeAuthors = release.value("includeAuthors").toBool();
    const bool linkCommits    = release.value("linkCommits", true).toBool();
    const QString date        = release.value("date").toString().isEmpty()
                                    ? QDate::currentDate().toString(Qt::ISODate)
                                    : release.value("date").toString();
    const QVariantList commits = release.value("commits").toList();

    QStringList lines;

    const QString compare = previousTag.isEmpty() || !linkCommits
                                ? QString()
                                : compareUrl(webUrl, provider, previousTag, tagName);
    lines << (compare.isEmpty() ? QStringLiteral("## %1 - %2").arg(version, date)
                                : QStringLiteral("## [%1](%2) - %3").arg(version, compare, date));

    auto entry = [&](const QVariantMap &commit, const QString &text) {
        QString line = QStringLiteral("- ");
        const QString scope = commit["scope"].toString();
        if (!scope.isEmpty())
            line += QStringLiteral("**%1:** ").arg(scope);
        line += linkCommits ? linkIssues(text, webUrl, provider) : text;

        const QString hash = commit["hash"].toString();
        const QString url  = linkCommits ? commitUrl(webUrl, provider, hash) : QString();
        const QString shortHash = commit["shortHash"].toString();
        line += url.isEmpty() ? QStringLiteral(" (%1)").arg(shortHash)
                              : QStringLiteral(" ([%1](%2))").arg(shortHash, url);
        if (includeAuthors)
            line += QStringLiteral(" by %1").arg(commit["author"].toString());
        return line;
    };

    QStringList breakingLines;
    for (const QVariant &value : commits) {
        const QVariantMap commit = value.toMap();
        if (!commit["breaking"].toBool())
            continue;
        const QString note = commit["breakingNote"].toString();
        breakingLines << entry(commit, note.isEmpty() ? commit["subject"].toString() : note);
    }
    if (!breakingLines.isEmpty()) {
        lines << QString() << QStringLiteral("### Breaking Changes") << QString();
        lines << breakingLines;
    }

    auto emitSection = [&](const QString &title, const std::function<bool(const QVariantMap &)> &matches) {
        QStringList entries;
        for (const QVariant &value : commits) {
            const QVariantMap commit = value.toMap();
            if (matches(commit))
                entries << entry(commit, commit["subject"].toString());
        }
        if (entries.isEmpty())
            return;
        lines << QString() << QStringLiteral("### ") + title << QString();
        lines << entries;
    };

    QStringList knownTypes;
    for (const Section &section : sections()) {
        knownTypes << section.type;
        emitSection(section.title, [&section](const QVariantMap &c) { return c["type"].toString() == section.type; });
    }
    emitSection(QStringLiteral("Other Changes"), [&knownTypes](const QVariantMap &c) {
        return !knownTypes.contains(c["type"].toString());
    });

    if (commits.isEmpty())
        lines << QString() << QStringLiteral("No notable changes.");

    return lines.join(QLatin1Char('\n')) + QLatin1Char('\n');
}

QVariantMap ReleaseEngine::writeChangelog(const QString &fileName,
                                          const QString &version,
                                          const QString &section) const
{
    QVariantMap result;
    result["success"] = false;

    const QString relative = fileName.trimmed().isEmpty() ? QStringLiteral("CHANGELOG.md") : fileName.trimmed();
    if (m_repoPath.isEmpty() || QDir::isAbsolutePath(relative) || relative.contains(QStringLiteral(".."))) {
        result["errorMessage"] = QStringLiteral("The changelog must be a file inside the repository");
        return result;
    }

    const QString path = QDir(m_repoPath).filePath(relative);
    QFile file(path);
    QString existing;
    const bool exists = file.exists();
    if (exists) {
        if (!file.open(QIODevice::ReadOnly)) {
            result["errorMessage"] = QStringLiteral("Could not read %1").arg(relative);
            return result;
        }
        existing = QString::fromUtf8(file.readAll());
        file.close();
    }

    const bool crlf = existing.contains(QStringLiteral("\r\n"));
    QString text = existing;
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));

    const QRegularExpression duplicate(
        QStringLiteral(R"(^##\s+\[?v?%1\]?(\s|\(|$))").arg(QRegularExpression::escape(version)),
        QRegularExpression::MultilineOption);
    if (duplicate.match(text).hasMatch()) {
        result["errorMessage"] = QStringLiteral("%1 already has an entry for %2").arg(relative, version);
        return result;
    }

    QString entry = section.trimmed() + QStringLiteral("\n");
    if (text.trimmed().isEmpty()) {
        text = QStringLiteral("# Changelog\n\nAll notable changes to this project are documented in this file.\n\n") + entry;
    } else {
        static const QRegularExpression firstRelease(QStringLiteral(R"(^## )"), QRegularExpression::MultilineOption);
        const auto m = firstRelease.match(text);
        if (m.hasMatch()) {
            text.insert(m.capturedStart(), entry + QStringLiteral("\n"));
        } else {
            if (!text.endsWith(QLatin1Char('\n')))
                text += QLatin1Char('\n');
            text += QStringLiteral("\n") + entry;
        }
    }

    if (crlf)
        text.replace(QStringLiteral("\n"), QStringLiteral("\r\n"));

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        result["errorMessage"] = QStringLiteral("Could not write %1").arg(relative);
        return result;
    }
    file.write(text.toUtf8());
    file.close();

    result["success"]      = true;
    result["created"]      = !exists;
    result["relativePath"] = QDir::fromNativeSeparators(relative);
    return result;
}

void ReleaseEngine::push(const QString &remote, const QString &tagName)
{
    if (m_pushing)
        return;
    setPushing(true);

    const QString repoPath = m_repoPath;
    QStringList args = { "push", remote.isEmpty() ? QStringLiteral("origin") : remote, "HEAD" };
    if (!tagName.isEmpty())
        args << QStringLiteral("refs/tags/%1").arg(tagName);

    auto *watcher = new QFutureWatcher<GitOutput>(this);
    QPointer<ReleaseEngine> self(this);
    connect(watcher, &QFutureWatcher<GitOutput>::finished, this, [self, watcher]() {
        const GitOutput output = watcher->result();
        watcher->deleteLater();
        if (!self)
            return;
        self->setPushing(false);

        QString message = (output.err + output.out).trimmed();
        if (output.ok()) {
            emit self->pushFinished(true, message.isEmpty() ? QStringLiteral("Pushed") : message);
            return;
        }
        if (message.contains(QStringLiteral("Authentication failed"), Qt::CaseInsensitive)
            || message.contains(QStringLiteral("could not read Username"), Qt::CaseInsensitive)) {
            message = QStringLiteral("Authentication failed. Configure a Git credential helper or SSH key for this remote, then push again.");
        } else if (message.contains(QStringLiteral("[rejected]")) || message.contains(QStringLiteral("non-fast-forward"))) {
            message = QStringLiteral("The remote rejected the push because it has newer commits. Pull first, then push the release.");
        }
        emit self->pushFinished(false, message.isEmpty() ? QStringLiteral("Push failed") : message);
    });
    watcher->setFuture(QtConcurrent::run([repoPath, args]() { return runGit(repoPath, args, 180000); }));
}

QVariantMap ReleaseEngine::releaseDetails(const QString &tag, const QString &previousTag) const
{
    QVariantMap result;
    result["success"] = false;
    if (m_repoPath.isEmpty() || tag.isEmpty()) {
        result["errorMessage"] = QStringLiteral("No release selected");
        return result;
    }

    const GitOutput info = runGit(m_repoPath, { "for-each-ref",
                                                "--format=%(objecttype)%1f%(taggername)%1f%(creatordate:short)%1f%(contents:body)",
                                                QStringLiteral("refs/tags/") + tag });
    const QStringList fields = info.out.split(QChar(0x1f));
    if (!info.ok() || fields.size() < 4) {
        result["errorMessage"] = QStringLiteral("Tag %1 was not found").arg(tag);
        return result;
    }

    const bool annotated = fields[0] == QStringLiteral("tag");
    result["annotated"] = annotated;
    result["tagger"]    = annotated ? fields[1].trimmed() : QString();
    result["date"]      = fields[2].trimmed();
    result["message"]   = annotated ? fields.mid(3).join(QChar(0x1f)).trimmed() : QString();

    const QString range = previousTag.isEmpty() ? tag : previousTag + QStringLiteral("..") + tag;
    const QString logError = readCommits(m_repoPath, range, &result);
    if (!logError.isEmpty()) {
        result["errorMessage"] = logError;
        return result;
    }

    result["success"] = true;
    return result;
}

QString ReleaseEngine::releaseLink(const QString &webUrl, const QString &provider, const QString &tag) const
{
    const QString encoded = QString::fromUtf8(QUrl::toPercentEncoding(tag));
    if (provider == QStringLiteral("github")) return webUrl + QStringLiteral("/releases/tag/") + encoded;
    if (provider == QStringLiteral("gitlab")) return webUrl + QStringLiteral("/-/releases/") + encoded;
    return {};
}

QString ReleaseEngine::compareLink(const QString &webUrl, const QString &provider,
                                   const QString &from, const QString &to) const
{
    return from.isEmpty() || to.isEmpty() ? QString() : compareUrl(webUrl, provider, from, to);
}

QString ReleaseEngine::newReleaseLink(const QString &webUrl, const QString &provider, const QString &tag,
                                      const QString &title, const QString &notes) const
{
    // Browsers and servers reject very long URLs; beyond this the user pastes the copied notes.
    constexpr int maxUrlLength = 7000;
    auto enc = [](const QString &s) { return QString::fromUtf8(QUrl::toPercentEncoding(s)); };

    QString base;
    if (provider == QStringLiteral("github"))
        base = QStringLiteral("%1/releases/new?tag=%2&title=%3").arg(webUrl, enc(tag), enc(title));
    else if (provider == QStringLiteral("gitlab"))
        base = QStringLiteral("%1/-/releases/new?tag_name=%2").arg(webUrl, enc(tag));
    else
        return {};

    if (provider == QStringLiteral("github") && !notes.trimmed().isEmpty()) {
        const QString withBody = base + QStringLiteral("&body=") + enc(notes.trimmed());
        if (withBody.size() <= maxUrlLength)
            return withBody;
    }
    return base;
}
