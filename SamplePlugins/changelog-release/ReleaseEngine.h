#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

/*!
 * \brief Reads release history from a repository and produces release notes.
 *
 * History is read with the git command line so the plugin does not link libgit2; commits, tags
 * and staging that should show up in GitEase are left to the host controllers. Pushing also goes
 * through git so the user's configured credential helper is used.
 */
class ReleaseEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString repoPath READ repoPath WRITE setRepoPath NOTIFY repoPathChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool pushing READ pushing NOTIFY pushingChanged)

public:
    explicit ReleaseEngine(QObject *parent = nullptr);

    QString repoPath() const { return m_repoPath; }
    void setRepoPath(const QString &path);

    bool busy() const { return m_busy; }
    bool pushing() const { return m_pushing; }

    /*!
     * Reads the latest semantic-version tag reachable from HEAD and the commits made since.
     * Emits analyzed() with the result map.
     */
    Q_INVOKABLE void analyze();

    //! Returns \a version bumped by "major", "minor" or "patch"; empty when it is not semver.
    Q_INVOKABLE QString bumpVersion(const QString &version, const QString &bump) const;

    //! True when \a version is a valid semantic version (without prefix).
    Q_INVOKABLE bool isValidVersion(const QString &version) const;

    /*!
     * Renders a Markdown release section.
     *
     * \a release keys: version, tagName, previousTag, date, webUrl, provider, commits,
     * includeAuthors, linkCommits.
     */
    Q_INVOKABLE QString renderNotes(const QVariantMap &release) const;

    /*!
     * Inserts \a section as the newest entry of \a fileName (relative to the repository), creating
     * the file when needed. Fails when the file already has an entry for \a version.
     */
    Q_INVOKABLE QVariantMap writeChangelog(const QString &fileName,
                                           const QString &version,
                                           const QString &section) const;

    /*!
     * Sets the project version to \a version in the files the release commit must include:
     * the root CMakeLists.txt project() VERSION, and Inno Setup MyAppVersion defines.
     * Files that already say \a version are left unchanged. A file with other uncommitted
     * changes is refused, so the bump cannot be split into a follow-up commit that leaves
     * the tag behind.
     *
     * Keys: success, errorMessage, files (relative paths to stage).
     */
    Q_INVOKABLE QVariantMap writeProjectVersion(const QString &version) const;

    //! Pushes the current branch, and \a tagName when not empty, to \a remote. Emits pushFinished().
    Q_INVOKABLE void push(const QString &remote, const QString &tagName);

    /*!
     * Reads a published release: the tag message and the commits since \a previousTag.
     * Keys: success, errorMessage, annotated, tagger, date, message, commits, counts, truncated.
     */
    Q_INVOKABLE QVariantMap releaseDetails(const QString &tag, const QString &previousTag) const;

    //! Web page of the release \a tag; empty when the provider has no release pages.
    Q_INVOKABLE QString releaseLink(const QString &webUrl, const QString &provider, const QString &tag) const;

    //! Web page that compares \a from with \a to; empty when unsupported.
    Q_INVOKABLE QString compareLink(const QString &webUrl, const QString &provider,
                                    const QString &from, const QString &to) const;

    //! Web form that drafts a release for \a tag, prefilled with \a title and \a notes when they fit in a URL.
    Q_INVOKABLE QString newReleaseLink(const QString &webUrl, const QString &provider, const QString &tag,
                                       const QString &title, const QString &notes) const;

signals:
    void repoPathChanged();
    void busyChanged();
    void pushingChanged();
    void analyzed(const QVariantMap &result);
    void pushFinished(bool success, const QString &message);

private:
    static QVariantMap analyzeRepository(const QString &repoPath);

    void setBusy(bool busy);
    void setPushing(bool pushing);

    QString m_repoPath;
    bool    m_busy    = false;
    bool    m_pushing = false;
    int     m_generation = 0;
};
