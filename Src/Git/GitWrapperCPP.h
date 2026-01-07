    /*! ***********************************************************************************************
 * GitWrapperCPP : C++ wrapper for libgit2 operations, exposed to QML.
 *                 Follows the UML design as QML_Service layer.
 * ************************************************************************************************/
#ifndef GITWRAPPERCPP_H
#define GITWRAPPERCPP_H

#include "GitResult.h"
#include <QObject>
#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>
#include <QDir>
#include <QRegularExpression>

extern "C" {
#include <git2.h>
}



struct DiffLineData {
    int type; // 0: Context, 1: Add, 2: Del, 3: Modified
    int oldLine;
    int newLine;
    QString content;
    QString contentNew;
};

/**
 * This class implements all Git operations required by the multi-page dockable Git client.
 * It follows the UML design exactly, exposing all methods as Q_INVOKABLE for QML access.
 *
 * \endcode
 */
class GitWrapperCPP : public QObject
{
    Q_OBJECT
    QML_ELEMENT

private:
    git_repository* m_currentRepo = nullptr;    ///< Currently opened repository handle
    QString m_currentRepoPath;                  ///< Path of currently open repository
    QString m_lastError;                        ///< Last error message for debugging


    /* ============================================================
     * End of Commit Operation Helper Functions
     * ============================================================ */

    /* Internal Test Function */
    void unitTest();

    /**
     * \brief Run comprehensive tests for commit operations
     * Tests complete workflow: clone -> create files -> stage -> commit -> push
     */
    void unitTestForGitWorkflow();

public:
    /**
     * \brief Constructor - initializes libgit2 library
     * \param parent Parent QObject (optional)
     */
    explicit GitWrapperCPP(QObject *parent = nullptr);

    /**
     * \brief Destructor - shuts down libgit2 and cleans up
     */
    ~GitWrapperCPP();



public slots:




};

#endif // GITWRAPPERCPP_H
