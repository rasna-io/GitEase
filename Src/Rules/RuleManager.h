#pragma once
#include <QObject>
#include <QQmlEngine>
#include "Repository.h"

class GitResult;

/*!
 * @brief Reads and writes a repository's git workflow rules (commit message,
 * branch naming, etc) to a JSON file on disk.
 *
 * Also supports importing rules from, and exporting rules to, a
 * user-chosen file location, independent of the active repo's own rules file.
 */

class RuleManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit RuleManager(QObject *parent = nullptr);

    /**
     * @brief Serializes and writes the given rules JSON to the active
     * repository's rules file, overwriting any existing content.
     *
     * @param jsonText The full rules document, already serialized to a JSON string.
     * @return A GitResult indicating success, or failure with an error message
     */
    Q_INVOKABLE GitResult saveRules(const QString &jsonText);

    /**
     * @brief Reads the active repository's rules file from disk.
     *
     * If no rules file exists yet for this repo, this is not treated as an
     * error — the result is successful with empty/blank data, representing
     * a fresh repo with no configured rules.
     *
     * @return A GitResult carrying the raw JSON text in data on success.
     */
    Q_INVOKABLE GitResult loadRules();

    /**
     * @brief Writes the given rules JSON to a file chosen by the user,
     * independent of the active repository's own rules file.
     *
     * @param fileUrl Destination file chosen via a save file dialog.
     * @param jsonText The full rules document, already serialized to a JSON string.
     * @return A GitResult indicating success or failure.
     */
    Q_INVOKABLE GitResult exportRules(const QUrl &fileUrl, const QString &jsonText);

    /**
     * @brief Reads rules JSON from a file chosen by the user.
     *
     * Does not modify the active repository's own rules file or apply the
     * imported rules in any way — callers are responsible for parsing the
     * returned JSON and persisting it via saveRules() if desired.
     *
     * @param fileUrl Source file, typically chosen via an open file dialog.
     * @return A GitResult carrying the raw JSON text in data on success.
     */
    Q_INVOKABLE GitResult importRules(const QUrl &fileUrl);

    /**
     * @brief Returns the repository this manager currently reads/writes rules for.
     */
    Repository *currentRepo() const;

    /**
     * @brief Sets the active repository. Rules operations will target this
     * repo's rules file until changed again.
     */
    Q_INVOKABLE void setCurrentRepo(Repository *newCurrentRepo);

signals:
    /**
     * @brief Emitted when the active repository changes.
     */
    void currentRepoChanged();

private:
    /**
     * @brief Builds the absolute path to the active repository's rules file
     * (inside its working directory). Returns an empty string if no
     * repository is currently set.
     */
    QString rulesFilePath();

    Repository *m_currentRepo = nullptr;
};