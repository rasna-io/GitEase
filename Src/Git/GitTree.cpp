#include "GitTree.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>

GitTree::GitTree(QObject *parent)
    : IGitController(parent)
{
}

GitResult GitTree::getFileTree(const QString &sha)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    QString errorMessage;
    git_tree *rootTree = lookupCommitTree(sha, errorMessage);
    if (!rootTree)
        return GitResult(false, QVariant(), errorMessage);

    QVariantList entries;
    bool ok = appendTreeEntries(rootTree, "", 0, entries);
    git_tree_free(rootTree);

    if (!ok)
        return GitResult(false, QVariant(), "Failed to walk the commit tree");

    return GitResult(true, entries);
}

GitResult GitTree::getFileContent(const QString &sha, const QString &path)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    QString errorMessage;
    git_blob *blob = lookupBlob(sha, path, errorMessage);
    if (!blob)
        return GitResult(false, QVariant(), errorMessage);

    bool isBinary = git_blob_is_binary(blob) != 0;
    git_object_size_t size = git_blob_rawsize(blob);

    QVariantMap fileMap;
    fileMap["path"]         = path;
    fileMap["isBinary"]     = isBinary;
    fileMap["size"]         = static_cast<qulonglong>(size);
    fileMap["content"]      = isBinary
            ? QString()
            : QString::fromUtf8(static_cast<const char*>(git_blob_rawcontent(blob)),
                                static_cast<int>(size));

    git_blob_free(blob);

    return GitResult(true, fileMap);
}

GitResult GitTree::saveFileContent(const QString &sha, const QString &path, const QString &targetPath)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    if (targetPath.isEmpty())
        return GitResult(false, QVariant(), "Target path is empty");

    QString errorMessage;
    git_blob *blob = lookupBlob(sha, path, errorMessage);
    if (!blob)
        return GitResult(false, QVariant(), errorMessage);

    QFile file(targetPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        git_blob_free(blob);
        return GitResult(false, QVariant(), "Cannot write to " + targetPath);
    }

    file.write(static_cast<const char*>(git_blob_rawcontent(blob)),
               static_cast<qint64>(git_blob_rawsize(blob)));
    file.close();

    git_blob_free(blob);

    return GitResult(true, targetPath);
}

git_tree* GitTree::lookupCommitTree(const QString &sha, QString &errorMessage)
{
    QString revision = sha + "^{commit}";

    git_object *commitObj = nullptr;
    if (git_revparse_single(&commitObj, activeRepo(), revision.toUtf8().constData()) < 0) {
        errorMessage = "Commit not found: " + sha;
        return nullptr;
    }

    git_tree *tree = nullptr;
    int error = git_commit_tree(&tree, reinterpret_cast<git_commit*>(commitObj));
    git_object_free(commitObj);

    if (error < 0) {
        errorMessage = "Failed to read tree of commit " + sha;
        return nullptr;
    }

    return tree;
}

git_blob* GitTree::lookupBlob(const QString &sha, const QString &path, QString &errorMessage)
{
    git_tree *rootTree = lookupCommitTree(sha, errorMessage);
    if (!rootTree)
        return nullptr;

    git_tree_entry *entry = nullptr;
    int error = git_tree_entry_bypath(&entry, rootTree, path.toUtf8().constData());
    git_tree_free(rootTree);

    if (error < 0) {
        errorMessage = "File not found at this commit: " + path;
        return nullptr;
    }

    if (git_tree_entry_type(entry) != GIT_OBJECT_BLOB) {
        git_tree_entry_free(entry);
        errorMessage = "Path is not a file: " + path;
        return nullptr;
    }

    git_blob *blob = nullptr;
    error = git_blob_lookup(&blob, activeRepo(), git_tree_entry_id(entry));
    git_tree_entry_free(entry);

    if (error < 0) {
        errorMessage = "Failed to read file content: " + path;
        return nullptr;
    }

    return blob;
}

bool GitTree::appendTreeEntries(git_tree *tree, const QString &basePath, int depth, QVariantList &entries)
{
    struct ChildEntry {
        QString name;
        const git_tree_entry *entry;
    };

    QList<ChildEntry> folders;
    QList<ChildEntry> files;

    size_t count = git_tree_entrycount(tree);
    for (size_t i = 0; i < count; ++i) {
        const git_tree_entry *entry = git_tree_entry_byindex(tree, i);
        if (!entry)
            continue;

        QString name = QString::fromUtf8(git_tree_entry_name(entry));

        if (git_tree_entry_type(entry) == GIT_OBJECT_TREE)
            folders.append({name, entry});
        else if (git_tree_entry_type(entry) == GIT_OBJECT_BLOB)
            files.append({name, entry});
    }

    auto byName = [](const ChildEntry &a, const ChildEntry &b) {
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    };
    std::sort(folders.begin(), folders.end(), byName);
    std::sort(files.begin(), files.end(), byName);

    for (const ChildEntry &folder : folders) {
        QString fullPath = basePath.isEmpty() ? folder.name : basePath + "/" + folder.name;

        QVariantMap entryMap;
        entryMap["name"]        = folder.name;
        entryMap["path"]        = fullPath;
        entryMap["type"]        = "tree";
        entryMap["depth"]       = depth;
        entryMap["parentPath"]  = basePath;
        entries.append(entryMap);

        git_tree *subTree = nullptr;
        if (git_tree_lookup(&subTree, activeRepo(), git_tree_entry_id(folder.entry)) < 0)
            return false;

        bool ok = appendTreeEntries(subTree, fullPath, depth + 1, entries);
        git_tree_free(subTree);

        if (!ok)
            return false;
    }

    for (const ChildEntry &file : files) {
        QString fullPath = basePath.isEmpty() ? file.name : basePath + "/" + file.name;

        QVariantMap entryMap;
        entryMap["name"]        = file.name;
        entryMap["path"]        = fullPath;
        entryMap["type"]        = "blob";
        entryMap["depth"]       = depth;
        entryMap["parentPath"]  = basePath;
        entries.append(entryMap);
    }

    return true;
}
