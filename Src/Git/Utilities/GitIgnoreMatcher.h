#pragma once

#include <QHash>
#include <QRegularExpression>
#include <QString>
#include <QVector>

/*!
 * @brief Names the .gitignore rule that decides whether a path is ignored.
 *
 * libgit2 can say whether a path is ignored (git_ignore_path_is_ignored) but not which rule did
 * it, which is what `git check-ignore -v` reports. This class reads the ignore files that can
 * apply to a path and finds that rule. It does not touch libgit2: the caller supplies the
 * settings, and decides separately whether the path is ignored at all.
 *
 * Precedence is git's: the .gitignore of the deepest folder first, then the ones above it, then
 * .git/info/exclude and finally the global excludes file. The last matching line of a file wins,
 * and a path below an ignored folder is ignored by that folder's rule.
 */
class GitIgnoreMatcher
{
public:
    struct Settings
    {
        //! Working directory of the repository.
        QString root;
        //! Path of .git/info/exclude; may not exist.
        QString infoExcludePath;
        //! core.excludesfile as configured (a leading ~ is expanded); empty for git's default.
        QString globalExcludesPath;
        //! core.ignorecase.
        bool    ignoreCase = false;
    };

    struct Match
    {
        bool    found   = false;
        //! The rule starts with "!": it re-includes the path instead of ignoring it.
        bool    negated = false;
        //! ".gitignore", "sub/.gitignore", ".git/info/exclude" or the global file's path.
        QString source;
        int     line    = 0;
        QString pattern;
    };

    explicit GitIgnoreMatcher(const Settings &settings);

    /*!
     * The rule that decides @p path, a path relative to the root with a trailing slash for
     * folders. found is false when no rule matches.
     */
    Match find(const QString &path);

private:
    struct Rule
    {
        QRegularExpression regex;
        QString            text;
        int                line     = 0;
        bool               negated  = false;
        bool               dirOnly  = false;
        //! Contains a slash: matched against the path below the file's folder, not the bare name.
        bool               anchored = false;
    };

    struct RuleFile
    {
        QString       source;
        //! Folder of the file relative to the root, with a trailing slash; empty for the root.
        QString       baseDir;
        QVector<Rule> rules;
    };

    bool parseRule(const QString &raw, int lineNumber, Rule *rule) const;
    const RuleFile &fileFor(const QString &key, const QString &source, const QString &baseDir,
                            const QString &path);
    Match matchIn(const RuleFile &file, const QString &rel, bool isDir) const;
    Match decide(const QString &rel, bool isDir);

    QString                  m_root;
    QString                  m_globalPath;
    QString                  m_infoExcludePath;
    bool                     m_ignoreCase = false;
    QHash<QString, RuleFile> m_files;
};
