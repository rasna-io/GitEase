#pragma once

#include "GitResult.h"
#include "IGitController.h"

#include <QObject>
#include <QQmlEngine>

class GitBundle : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

    // Resource management
    struct BundleContext {
        QString bundlePath;
        QString commitSha;
        QString branchName;
        QString refName;
        bool verified = false;
    };

public:

    explicit GitBundle(QObject *parent = nullptr);

    Q_INVOKABLE GitResult buildCompleteBundle(const QString &resolvedBranchName,
                                  const QString &refBranchName,
                                  const QString &path);

    Q_INVOKABLE GitResult buildDiffBundle(const QString &baseRef,
                              const QString &targetRef,
                              const QString &refBranchName,
                              const QString &path);

    Q_INVOKABLE GitResult unbundleWithCli(const QString &bundlePath);
private:

    GitResult writeBundleFile(git_packbuilder *packbuilder, const BundleContext &context);


    void cleanupBundleResources(git_reference *ref, git_object *object, git_revwalk *walker, git_packbuilder *packbuilder);

    GitResult setupCompletePackbuilder(const git_oid *targetOid, git_packbuilder *&packbuilder, git_revwalk *&walker);

    QPair<const git_oid* , QString> getReferenceCommit(const QString &ref);


    GitResult setupDiffPackbuilder(const git_oid *baseOid,
                                   const git_oid *targetOid,
                                   git_packbuilder *&packbuilder,
                                   git_revwalk *&walker,
                                   int &commitCount,
                                   QStringList &newCommitShas);

    bool verifyBundle(const QString &bundlePath);
};
