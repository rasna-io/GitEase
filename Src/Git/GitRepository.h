#pragma once

#include <QObject>
#include "GitResult.h"
#include "IGitController.h"


class GitRepository : public IGitController
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit GitRepository(QObject *parent = nullptr);

    /**
     * \brief Initialize a new Git repository
     * \param path Path where to create the repository
     * \return GitResult
     *
     * Creates a new Git repository at the specified path.
     */
    Q_INVOKABLE GitResult init(const QString &path);

    /**
     * \brief Open an existing Git repository
     * \param path Path to the repository
     * \return GitResult
     */
    Q_INVOKABLE GitResult open(const QString &path);

    /**
     * \brief Close the currently open repository
     * \return QVariantMap with {"success": bool, "error": message}
     */
    Q_INVOKABLE GitResult close();

    /**
     * \brief Clone a remote repository
     * \param url Remote repository URL
     * \param localPath Local path where to clone
     * \return GitResult
     */
    Q_INVOKABLE GitResult clone(const QString &url, const QString &localPath);


signals:
    void cloneFinished(QVariantMap result);
    void cloneProgress(int progress);


private:
    QString m_currentRepoPath;
};
