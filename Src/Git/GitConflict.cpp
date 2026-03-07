#include "GitConflict.h"
#include <git2.h>
#include <QFile>
#include <QDir>
#include <QFileInfo>

GitConflict::GitConflict(QObject* parent)
    : IGitController(parent)
{
}

GitResult GitConflict::getMergeConflicts()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to read repository index.");

    QVariantList conflicts;

    if (git_index_has_conflicts(index)) {

        git_index_conflict_iterator* iter = nullptr;

        if (git_index_conflict_iterator_new(&iter, index) == 0) {

            const git_index_entry* ancestor = nullptr;
            const git_index_entry* ours = nullptr;
            const git_index_entry* theirs = nullptr;

            while (git_index_conflict_next(&ancestor, &ours, &theirs, iter) == 0) {

                QString path;

                if (ours && ours->path)
                    path = QString::fromUtf8(ours->path);
                else if (theirs && theirs->path)
                    path = QString::fromUtf8(theirs->path);
                else if (ancestor && ancestor->path)
                    path = QString::fromUtf8(ancestor->path);

                if (path.isEmpty())
                    continue;

                QVariantMap entry;

                entry["path"] = path;
                entry["baseContent"] = readBlobContent(ancestor);
                entry["ourContent"] = readBlobContent(ours);
                entry["theirContent"] = readBlobContent(theirs);

                conflicts.append(entry);
            }

            git_index_conflict_iterator_free(iter);
        }
    }

    git_index_free(index);

    return GitResult(true, conflicts);
}

GitResult GitConflict::acceptConflictOurs(const QString& filePath)
{
    return writeConflictFromStage(filePath, 2); // stage 2 = ours
}

GitResult GitConflict::acceptConflictTheirs(const QString& filePath)
{
    return writeConflictFromStage(filePath, 3); // stage 3 = theirs
}

GitResult GitConflict::writeConflictFromStage(const QString& filePath, int stage)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    if (filePath.isEmpty())
        return GitResult(false, QVariant(), "File path cannot be empty.");

    // Get the working directory path
    const char* workdir = git_repository_workdir(m_currentRepo->repo);
    if (!workdir)
        return GitResult(false, QVariant(), "Cannot modify file in a bare repository.");

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to open repository index.");

    // Retrieve the index entry for the requested stage
    const git_index_entry* entry = git_index_get_bypath(index,
                                                        filePath.toUtf8().constData(),
                                                        stage);
    if (!entry) {
        git_index_free(index);
        return GitResult(false, QVariant(), QString("No entry found for stage %1.").arg(stage));
    }

    // Read blob content
    git_blob* blob = nullptr;
    if (git_blob_lookup(&blob, m_currentRepo->repo, &entry->id) != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to read blob content.");
    }

    QByteArray content(reinterpret_cast<const char*>(git_blob_rawcontent(blob)),
                       static_cast<int>(git_blob_rawsize(blob)));
    git_blob_free(blob);

    // Construct absolute file path
    QString fullPath = QString::fromUtf8(workdir) + QDir::separator() + filePath;
    QFileInfo fileInfo(fullPath);
    // Ensure directory exists
    fileInfo.dir().mkpath(".");

    QFile file(fullPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to write file to working directory.");
    }
    file.write(content);
    file.close();

    // Stage the resolved file (this removes conflict markers in the index)
    if (git_index_add_bypath(index, filePath.toUtf8().constData()) != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to stage the resolved file.");
    }

    if (git_index_write(index) != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to write index.");
    }

    git_index_free(index);

    // Emit command for logging
    QString flag = (stage == 2) ? "--ours" : "--theirs";
    emitGitCommand(QString("git checkout %1 %2").arg(flag, quoteCommandArg(filePath)));

    return GitResult(true, QVariant(), QString("Applied '%1' version for %2.")
                                           .arg(stage == 2 ? "ours" : "theirs", filePath));
}

QString GitConflict::readBlobContent(const git_index_entry* entry) const
{
    if (!entry || !m_currentRepo || !m_currentRepo->repo)
        return QString();

    git_blob* blob = nullptr;
    if (git_blob_lookup(&blob, m_currentRepo->repo, &entry->id) != GIT_OK)
        return QString();

    QString content = QString::fromUtf8(reinterpret_cast<const char*>(git_blob_rawcontent(blob)),
                                        static_cast<int>(git_blob_rawsize(blob)));
    git_blob_free(blob);
    return content;
}
