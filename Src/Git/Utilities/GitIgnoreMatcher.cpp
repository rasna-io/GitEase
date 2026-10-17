#include "GitIgnoreMatcher.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

namespace {

//! Translates a gitignore glob (without the trailing slash) into a regular expression.
QString globToRegex(const QString &glob)
{
    QString re;
    const int size = glob.size();

    for (int i = 0; i < size;) {
        const QChar c = glob.at(i);

        if (c == QLatin1Char('*')) {
            if (i + 1 < size && glob.at(i + 1) == QLatin1Char('*')) {
                const bool atSegmentStart = i == 0 || glob.at(i - 1) == QLatin1Char('/');
                const int next = i + 2;

                if (atSegmentStart && next < size && glob.at(next) == QLatin1Char('/')) {
                    re += QStringLiteral("(?:.*/)?");
                    i = next + 1;
                    continue;
                }

                if (atSegmentStart && next >= size) {
                    re += QStringLiteral(".*");
                    i = next;
                    continue;
                }

                re += QStringLiteral("[^/]*");
                i = next;
                continue;
            }

            re += QStringLiteral("[^/]*");
            ++i;
            continue;
        }

        if (c == QLatin1Char('?')) {
            re += QStringLiteral("[^/]");
            ++i;
            continue;
        }

        if (c == QLatin1Char('[')) {
            int close = i + 1;
            if (close < size && (glob.at(close) == QLatin1Char('!') || glob.at(close) == QLatin1Char('^'))) {
                ++close;
            }
            // A closing bracket right after the opening one is a member of the class.
            if (close < size && glob.at(close) == QLatin1Char(']')) {
                ++close;
            }
            close = glob.indexOf(QLatin1Char(']'), close);

            if (close > i) {
                QString body = glob.mid(i + 1, close - i - 1);
                if (body.startsWith(QLatin1Char('!'))) {
                    body[0] = QLatin1Char('^');
                }
                body.replace(QStringLiteral("\\"), QStringLiteral("\\\\"));
                re += QLatin1Char('[') + body + QLatin1Char(']');
                i = close + 1;
                continue;
            }
        }

        if (c == QLatin1Char('\\') && i + 1 < size) {
            re += QRegularExpression::escape(glob.at(i + 1));
            i += 2;
            continue;
        }

        re += QRegularExpression::escape(c);
        ++i;
    }

    return re;
}

QString expandHome(const QString &path)
{
    if (path.startsWith(QLatin1String("~/")) || path == QLatin1String("~")) {
        return QDir::homePath() + path.mid(1);
    }

    return path;
}

} // namespace

GitIgnoreMatcher::GitIgnoreMatcher(const Settings &settings)
    : m_root(settings.root)
    , m_infoExcludePath(settings.infoExcludePath)
    , m_ignoreCase(settings.ignoreCase)
{
    if (!settings.globalExcludesPath.isEmpty()) {
        m_globalPath = expandHome(settings.globalExcludesPath);
        return;
    }

    // git's default when core.excludesfile is not set.
    const QString configHome = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = configHome.isEmpty() ? QDir::homePath() + QStringLiteral("/.config") : configHome;
    m_globalPath = base + QStringLiteral("/git/ignore");
}

bool GitIgnoreMatcher::parseRule(const QString &raw, int lineNumber, Rule *rule) const
{
    QString text = raw;
    if (text.endsWith(QLatin1Char('\r'))) {
        text.chop(1);
    }

    // Trailing spaces are dropped unless they are escaped with a backslash.
    while (text.endsWith(QLatin1Char(' '))
           && !(text.size() >= 2 && text.at(text.size() - 2) == QLatin1Char('\\'))) {
        text.chop(1);
    }

    if (text.isEmpty() || text.startsWith(QLatin1Char('#'))) {
        return false;
    }

    rule->text = text;
    rule->line = lineNumber;
    rule->negated = text.startsWith(QLatin1Char('!'));

    QString glob = rule->negated ? text.mid(1) : text;

    rule->dirOnly = glob.endsWith(QLatin1Char('/'));
    if (rule->dirOnly) {
        glob.chop(1);
    }

    if (glob.isEmpty()) {
        return false;
    }

    rule->anchored = glob.contains(QLatin1Char('/'));
    if (glob.startsWith(QLatin1Char('/'))) {
        glob.remove(0, 1);
    }

    const QRegularExpression::PatternOptions options = m_ignoreCase
        ? QRegularExpression::CaseInsensitiveOption
        : QRegularExpression::NoPatternOption;
    rule->regex = QRegularExpression(QLatin1Char('^') + globToRegex(glob) + QLatin1Char('$'), options);

    return rule->regex.isValid();
}

const GitIgnoreMatcher::RuleFile &GitIgnoreMatcher::fileFor(const QString &key, const QString &source,
                                                            const QString &baseDir, const QString &path)
{
    const auto it = m_files.constFind(key);
    if (it != m_files.constEnd()) {
        return it.value();
    }

    RuleFile file;
    file.source = source;
    file.baseDir = baseDir;

    QFile handle(path);
    if (!path.isEmpty() && handle.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(handle.readAll()).split(QLatin1Char('\n'));

        for (int i = 0; i < lines.size(); ++i) {
            Rule rule;
            if (parseRule(lines.at(i), i + 1, &rule)) {
                file.rules.append(rule);
            }
        }
    }

    return m_files.insert(key, file).value();
}

GitIgnoreMatcher::Match GitIgnoreMatcher::matchIn(const RuleFile &file, const QString &rel, bool isDir) const
{
    const Qt::CaseSensitivity cs = m_ignoreCase ? Qt::CaseInsensitive : Qt::CaseSensitive;
    if (!file.baseDir.isEmpty() && !rel.startsWith(file.baseDir, cs)) {
        return {};
    }

    const QString below = rel.mid(file.baseDir.size());
    const int slash = below.lastIndexOf(QLatin1Char('/'));
    const QString name = slash < 0 ? below : below.mid(slash + 1);

    for (int i = file.rules.size() - 1; i >= 0; --i) {
        const Rule &rule = file.rules.at(i);

        if (rule.dirOnly && !isDir) {
            continue;
        }

        const QString &subject = rule.anchored ? below : name;
        if (!rule.regex.match(subject).hasMatch()) {
            continue;
        }

        Match match;
        match.found = true;
        match.negated = rule.negated;
        match.source = file.source;
        match.line = rule.line;
        match.pattern = rule.text;
        return match;
    }

    return {};
}

GitIgnoreMatcher::Match GitIgnoreMatcher::decide(const QString &rel, bool isDir)
{
    // .gitignore files from the folder of the path up to the root.
    QStringList dirs;
    const QStringList parts = rel.split(QLatin1Char('/'), Qt::SkipEmptyParts);
    QString dir;
    dirs << QString();
    for (int i = 0; i + 1 < parts.size(); ++i) {
        dir += parts.at(i) + QLatin1Char('/');
        dirs << dir;
    }

    for (int i = dirs.size() - 1; i >= 0; --i) {
        const QString &baseDir = dirs.at(i);
        const RuleFile &file = fileFor(QStringLiteral("dir:") + baseDir,
                                       baseDir + QStringLiteral(".gitignore"),
                                       baseDir,
                                       m_root + QLatin1Char('/') + baseDir + QStringLiteral(".gitignore"));

        const Match match = matchIn(file, rel, isDir);
        if (match.found) {
            return match;
        }
    }

    const RuleFile &info = fileFor(QStringLiteral("info"), QStringLiteral(".git/info/exclude"),
                                   QString(), m_infoExcludePath);
    const Match infoMatch = matchIn(info, rel, isDir);
    if (infoMatch.found) {
        return infoMatch;
    }

    const RuleFile &global = fileFor(QStringLiteral("global"), QDir::fromNativeSeparators(m_globalPath),
                                     QString(), m_globalPath);
    return matchIn(global, rel, isDir);
}

GitIgnoreMatcher::Match GitIgnoreMatcher::find(const QString &path)
{
    bool isDir = path.endsWith(QLatin1Char('/'));
    const QString rel = isDir ? path.left(path.size() - 1) : path;

    if (!isDir) {
        isDir = QFileInfo(m_root + QLatin1Char('/') + rel).isDir();
    }

    // A folder that is ignored takes everything below it, whatever the later rules say.
    const QStringList parts = rel.split(QLatin1Char('/'), Qt::SkipEmptyParts);
    QString ancestor;

    for (int i = 0; i + 1 < parts.size(); ++i) {
        ancestor += (i == 0 ? QString() : QStringLiteral("/")) + parts.at(i);

        const Match match = decide(ancestor, true);
        if (match.found && !match.negated) {
            return match;
        }
    }

    return decide(rel, isDir);
}
