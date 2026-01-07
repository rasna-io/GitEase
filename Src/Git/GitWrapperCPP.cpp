#include "GitWrapperCPP.h"
#include "GitResult.h"

#include <string.h>

#include <QDebug>
#include <QDir>
#include <QDateTime>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QFuture>
#include <qtconcurrentrun.h>
#include <QFutureWatcher>
#include <QRegularExpression>

#include <git2/commit.h>
#include <git2/signature.h>
#include <git2/tree.h>
#include <git2/index.h>
#include <git2/revparse.h>
#include <git2/branch.h>
#include <git2/refs.h>
#include <git2/object.h>


GitWrapperCPP::GitWrapperCPP(QObject *parent)
    : QObject(parent)
{
    git_libgit2_init();
    qDebug() << "GitWrapperCPP: libgit2 initialized";

    // unitTest();
    // unitTestForGitWorkflow();
}

GitWrapperCPP::~GitWrapperCPP()
{
    // Free current repository if open
    if (m_currentRepo)
    {
        git_repository_free(m_currentRepo);
        m_currentRepo = nullptr;
    }

    git_libgit2_shutdown();
    qDebug() << "GitWrapperCPP: libgit2 shutdown";
}

/* Repository Operations Implementation */

