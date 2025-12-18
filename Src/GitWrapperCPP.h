/*! ***********************************************************************************************
 * GitWrapperCPP : Simple Git wrapper for testing basic operations
 * ************************************************************************************************/
#ifndef GITWRAPPERCPP_H
#define GITWRAPPERCPP_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QQmlEngine>

extern "C" {
#include <git2.h>
}

class GitWrapperCPP : public QObject
{
    Q_OBJECT
    // QML_ELEMENT

    /* Simple properties for QML */
    Q_PROPERTY(QString repoPath READ repoPath NOTIFY repoChanged)
    Q_PROPERTY(bool isOpen READ isOpen NOTIFY repoChanged)
    Q_PROPERTY(QString currentBranch READ currentBranch NOTIFY repoChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorOccurred)

public:
    explicit GitWrapperCPP(QObject *parent = nullptr);
    ~GitWrapperCPP();

    /* Property getters */
    QString repoPath() const { return m_repoPath; }
    bool isOpen() const { return m_repo != nullptr; }
    QString currentBranch() const { return m_currentBranch; }
    QString lastError() const { return m_lastError; }

public slots:
    /* Basic Git operations - called from QML */
    bool openLocalRepo(const QString &path);
    bool cloneRemoteRepo(const QString &url, const QString &localPath);
    void closeRepo();

    /* Simple Git status - returns basic info */
    QVariantList getBasicInfo();

    /* Commit and push */
    bool commit(const QString &message);
    bool push(const QString &remote = "origin");

signals:
    /* Simple signals for QML */
    void repoChanged();
    void errorOccurred(const QString &error);
    void operationDone(const QString &result);

private:
    /* Private helpers */
    void updateBasicInfo();
    void handleGitError(int errorCode);

    git_repository *m_repo = nullptr;
    QString m_repoPath;
    QString m_currentBranch;
    QString m_lastError;
};

#endif // GITWRAPPERCPP_H
