#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

/*!
 * \brief QML-facing facade over the scan model, the root .gitignore and the templates.
 *
 * Everything that needs git (status, ignored files, the rule behind an ignored path, taking files
 * out of the index) is done by the host's IgnoreController, which the page owns; this class never
 * starts git. It turns the host's status into the page model on a worker thread, edits the root
 * .gitignore and manages the templates. Only the .gitignore in the repository root is ever written.
 *
 * A scan is a round trip through QML: beginScan(), the host's scan(), then finishScan().
 */
class GitignoreEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString repoPath READ repoPath WRITE setRepoPath NOTIFY repoPathChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit GitignoreEngine(QObject *parent = nullptr);

    QString repoPath() const;
    void setRepoPath(const QString &path);

    bool busy() const;

    // -- Repository ----------------------------------------------------------------------------

    //! Marks a scan as started and returns its generation. A newer scan supersedes older ones.
    Q_INVOKABLE int beginScan();

    /*!
     * Builds the page model from the data of IgnoreController.scan() and reads .gitignore.
     * Emits scanned() when done; ignored when  generation is no longer the current scan.
     */
    Q_INVOKABLE void finishScan(int generation, const QVariantMap &hostScan);

    //! Reports a failed scan through scanned().
    Q_INVOKABLE void failScan(int generation, const QString &message);

    //! Drops a scan the host reported as stale, without reporting anything.
    Q_INVOKABLE void cancelScan(int generation);

    // -- Rules ---------------------------------------------------------------------------------

    /*!
     * Rules that would ignore \a entries ({ path, isDir } maps).
     * \a mode: "exact" (/dir/file.txt), "name" (file.txt), "extension" (*.txt) or "folder" (/dir/).
     */
    Q_INVOKABLE QStringList patternsFor(const QVariantList &entries, const QString &mode) const;

    //! Appends \a patterns that are not already in the file. Keys: success, errorMessage, added, skipped.
    Q_INVOKABLE QVariantMap addPatterns(const QStringList &patterns);

    /*!
     * Groups the rules that ignore \a paths. \a hits is the data of IgnoreController.checkIgnore().
     * Keys: success, rules, unresolved.
     */
    Q_INVOKABLE QVariantMap planUnignore(const QStringList &paths, const QVariantList &hits) const;

    //! Deletes rules ({ line, pattern }). Refuses when the file changed since planning.
    Q_INVOKABLE QVariantMap removeRules(const QVariantList &rules);

    // -- The file ------------------------------------------------------------------------------

    //! Creates .gitignore from \a templateIds (may be empty). Fails when it already exists.
    Q_INVOKABLE QVariantMap createGitignore(const QStringList &templateIds);

    //! Replaces the whole file (the editor's Save).
    Q_INVOKABLE QVariantMap saveGitignore(const QString &content);

    // -- Templates -----------------------------------------------------------------------------

    //! Bundled and custom templates: { id, name, category, description, rules, custom, customized }.
    Q_INVOKABLE QVariantList templates() const;

    //! Text of the template \a id as it is used (customized copy included); empty when unknown.
    Q_INVOKABLE QString templateContent(const QString &id) const;

    //! The text a bundled template ships with, ignoring any customization.
    Q_INVOKABLE QString defaultTemplateContent(const QString &id) const;

    //! Appends the templates as marked sections; patterns already present are skipped.
    Q_INVOKABLE QVariantMap applyTemplates(const QStringList &templateIds);

    //! Stores a custom template under "My templates". Keys: success, errorMessage, id.
    Q_INVOKABLE QVariantMap saveUserTemplate(const QString &name, const QString &content);

    //! Deletes the custom template \a id (as returned by templates(), "user:" + name).
    Q_INVOKABLE QVariantMap deleteUserTemplate(const QString &id);

    /*!
     * Keeps \a content as the customized copy of the bundled template \a id. Saving the original
     * text again drops the customization.
     */
    Q_INVOKABLE QVariantMap saveTemplateOverride(const QString &id, const QString &content);

    //! Drops the customization of the bundled template \a id.
    Q_INVOKABLE QVariantMap resetTemplateOverride(const QString &id);

signals:
    void repoPathChanged();
    void busyChanged();
    void scanned(const QVariantMap &result);

private:
    void setBusy(bool busy);

    //! Root of the open repository; empty when none is open.
    QString currentRoot() const;

    QString m_repoPath;
    bool    m_busy       = false;
    int     m_generation = 0;
};
