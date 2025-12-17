#ifndef GITWRAPPERCPP_H
#define GITWRAPPERCPP_H

#include <QObject>
#include <QString>
#include <QMap>


// Include git2.h from our MinGW installation
extern "C" {
#include <git2.h>
}
class GitWrapperCPP : public QObject
{
    Q_OBJECT


private:
    struct GitRepo;
    GitRepo* m_repo = nullptr;
    QString m_lastError;

    // Callback for clone progress
    static int cloneProgressCallback(const git_transfer_progress *stats, void *payload);

    // Private helper methods for testing
    bool testLocalRepo();
    bool testCloneRepo();
public:
    explicit GitWrapperCPP(QObject *parent = nullptr);
    ~GitWrapperCPP();

    // Local repository operations
    bool initRepo(const QString& path);
    bool openRepo(const QString& path);
    void closeRepo();
    bool isRepoOpen() const;

    // Remote operations
    bool cloneRepo(const QString& url, const QString& localPath,
                   const QMap<QString, QString>& options = {});
    bool fetch(const QString& remote = "origin");
    bool pull(const QString& remote = "origin");
    bool push(const QString& remote = "origin");

    // Repository information
    QString repoPath() const;
    QString workDir() const;
    QString lastError() const;

    // Utility
    static bool isGitUrl(const QString& url);
    static QString getRepoNameFromUrl(const QString& url);

    static bool runTests();

signals:
    void progressUpdated(const QString& message, int percentage);
    void cloneCompleted(bool success, const QString& message);
};

#endif // GITWRAPPERCPP_H
