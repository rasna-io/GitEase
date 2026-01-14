#include "GitStatus.h"
#include "GitDiff.h"
#include "GitFileStatus.h"
#include <git2.h>

GitStatus::GitStatus(QObject *parent)
    : IGitController{parent}
{}

GitResult GitStatus::stageFile(const QString &filePath)
{
    if (filePath.isEmpty())
        return GitResult(false, QVariant(), "File path cannot be empty");

    return addToIndex(filePath);  // Stage the file
}


GitResult GitStatus::unstageFile(const QString &filePath)
{
    if (filePath.isEmpty())
        return GitResult(false, QVariant(), "File path cannot be empty");

    return addToIndex(filePath, true);  // Unstage the file
}

GitResult GitStatus::stageAll(bool includeUntrackedFiles)
{

    GitResult statusResult = status();
    if (!statusResult.success()) {
        return GitResult(false, QVariant(), statusResult.errorMessage());
    }

    int stagedCount = 0;
    QStringList stagedFiles;
    QList<GitFileStatus> files = statusResult.data().value<QList<GitFileStatus>>();

    // Stage all unstaged files
    for (const GitFileStatus& file : files) {
        if (file.isUnstaged()) {
            GitResult result = addToIndex(file.path());  // Stage the unstaged file
            if (result.success()) {
                stagedCount++;
                stagedFiles.append(file.path());
            }
        }
    }

    if (includeUntrackedFiles) {
        // Stage all untracked files
        for (const GitFileStatus& file : files) {
            if (file.isUntracked()) {
                GitResult result = addToIndex(file.path());  // Stage the untracked file
                if (result.success()) {
                    stagedCount++;
                    stagedFiles.append(file.path());
                }
            }
        }
    }

    QVariantMap resultData;
    resultData["count"] = stagedCount;
    resultData["files"] = stagedFiles;

    return GitResult(true, resultData, "All files staged successfully.");
}


GitResult GitStatus::status()
{
    // Get repository handle - SIMPLIFIED
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available. Please open a repository first.");


    QVariantMap statusData;
    QList<GitFileStatus> fileInfos;

    // Configure status options
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;      //Index vs HEAD
    opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED;

    git_status_list *status_list = nullptr;
    int gitResult = git_status_list_new(&status_list,  m_currentRepo->repo, &opts);

    if (gitResult == 0) {
        size_t count = git_status_list_entrycount(status_list);

        // Process each status entry
        for (size_t i = 0; i < count; i++) {
            const git_status_entry *entry = git_status_byindex(status_list, i);
            if (!entry) continue;

            GitFileStatus fileInfo = GitFileStatus(entry);
            fileInfos.append(fileInfo);
        }

        // Clean up status list
        git_status_list_free(status_list);
    }

    return GitResult(true, QVariant::fromValue(fileInfos));
}


GitResult GitStatus::unstageAll()
{

    GitResult statusResult = status();
    if (!statusResult.success()) {
        return GitResult(false, QVariant(), statusResult.errorMessage());
    }

    QList<GitFileStatus> files = statusResult.data().value<QList<GitFileStatus>>();

    int unstagedCount = 0;
    QStringList unstagedFiles;

    for (const GitFileStatus& file : files) {

        if (file.isStaged()) {
            GitResult result = addToIndex(file.path(), true);
            if (result.success()) {
                unstagedCount++;
                unstagedFiles.append(file.path());
            }
        }
    }

    QVariantMap resultData;
    resultData["count"] = unstagedCount;
    resultData["files"] = unstagedFiles;

    return GitResult(true, resultData, "All files unstaged successfully.");
}

GitResult GitStatus::getStagedFiles()
{
    GitResult statusResult = status();
    if (!statusResult.success()) {
        return GitResult(false, QVariant(), statusResult.errorMessage());
    }

    int stagedCount = 0;
    QList<GitFileStatus> files = statusResult.data().value<QList<GitFileStatus>>();
    QList<GitFileStatus> stagedFiles;

    for (const GitFileStatus& file : files) {
        if (file.isStaged()) {
            stagedFiles.append(file);
        }
    }
    return GitResult(true, QVariant::fromValue(stagedFiles), "All files unstaged successfully.");
}


GitResult GitStatus::addToIndex(const QString& filePath, bool isRemove)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository found");

    git_index *index = nullptr;
    int result = git_repository_index(&index,  m_currentRepo->repo);
    if (result != GIT_OK)
        return GitResult(false, QVariant(), "Failed to get repository index");

    QByteArray filePathUtf8 = filePath.toUtf8();
    result = isRemove ? git_index_remove_bypath(index, filePathUtf8.constData())
                      : git_index_add_bypath(index, filePathUtf8.constData());

    if (result != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), QString("Failed to update index for file: %1").arg(filePath));
    }

    result = git_index_write(index);
    git_index_free(index);

    if (result != GIT_OK)
        return GitResult(false, QVariant(), "Failed to write changes to disk");

    return GitResult(true, filePath, "File staged/unstaged successfully");
}

GitResult GitStatus::getDiff(const QString &filePath)
{
    QList<GitDiff> result;

    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available. Please open a repository first.");


    git_diff* diff = nullptr;
    git_diff_options opts = GIT_DIFF_OPTIONS_INIT;

    opts.flags |= GIT_DIFF_PATIENCE | GIT_DIFF_INDENT_HEURISTIC | GIT_DIFF_MINIMAL;

    // every single line of the file that isn't changed as a 'Context' line.
    opts.context_lines = 100000;
    opts.interhunk_lines = 100000;

    QByteArray pathBytes = filePath.toUtf8();
    char* path = const_cast<char*>(pathBytes.constData());
    opts.pathspec.strings = &path;
    opts.pathspec.count = 1;

    // This compares the Staging Area (Index) to the Local File (Workdir)
    int error = git_diff_index_to_workdir(&diff, m_currentRepo->repo, nullptr, &opts);

    if (error == 0) {
        struct RawLine { char origin; int old_no; int new_no; QString content; };
        std::vector<RawLine> rawLines;

        git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, [](
                                                        const git_diff_delta*, const git_diff_hunk*, const git_diff_line *line, void *payload) -> int {
            auto *vec = static_cast<std::vector<RawLine>*>(payload);

            if (line->origin == GIT_DIFF_LINE_CONTEXT ||
                line->origin == GIT_DIFF_LINE_ADDITION ||
                line->origin == GIT_DIFF_LINE_DELETION) {

                QString content = QString::fromUtf8(line->content, line->content_len);
                content.remove('\n').remove('\r');
                vec->push_back({line->origin, line->old_lineno, line->new_lineno, content});
            }
            return 0;
        }, &rawLines);

        for (size_t i = 0; i < rawLines.size(); ++i) {

            if (rawLines[i].origin == GIT_DIFF_LINE_DELETION &&
                (i + 1) < rawLines.size() &&
                rawLines[i+1].origin == GIT_DIFF_LINE_ADDITION) {

                result.append(GitDiff(GitDiff::Modified, rawLines[i].old_no, rawLines[i+1].new_no,
                                      rawLines[i].content, rawLines[i+1].content));
                i++;
            }
            else if (rawLines[i].origin == GIT_DIFF_LINE_DELETION) {
                result.append(GitDiff(GitDiff::Deleted, rawLines[i].old_no, -1, rawLines[i].content));
            }
            else if (rawLines[i].origin == GIT_DIFF_LINE_ADDITION) {
                result.append(GitDiff(GitDiff::Added, -1, rawLines[i].new_no, rawLines[i].content));
            }
            else {
                result.append(GitDiff(GitDiff::Context, rawLines[i].old_no, rawLines[i].new_no, rawLines[i].content));
            }
        }
    }

    if (diff)
        git_diff_free(diff);

    return GitResult(true, QVariant::fromValue(result));
}

GitResult GitStatus::getDiff(const QString &oldCommitHash, const QString &newCommitHash, const QString &filePath)
{
    QList<GitDiff> result;
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available. Please open a repository first.");

    // Retrieve the commit objects for old and new commits
    git_object *oldCommitObj = nullptr;
    git_object *newCommitObj = nullptr;
    git_tree *oldTree = nullptr;
    git_tree *newTree = nullptr;
    git_diff *diff = nullptr;

    // Parse the old commit object using the commit hash
    int resultCode = git_revparse_single(&oldCommitObj,  m_currentRepo->repo, oldCommitHash.toUtf8().constData());
    if (resultCode != 0)
        return GitResult(false, QVariant(), "Failed to retrieve the old commit.");

    // Parse the new commit object using the commit hash
    resultCode = git_revparse_single(&newCommitObj,  m_currentRepo->repo, newCommitHash.toUtf8().constData());
    if (resultCode != 0) {
        git_object_free(oldCommitObj);
        return GitResult(false, QVariant(), "Failed to retrieve the new commit.");
    }

    // Retrieve the trees for both commits (i.e., the snapshots of the commit's file system)
    resultCode = git_commit_tree(&oldTree, reinterpret_cast<git_commit*>(oldCommitObj));
    resultCode |= git_commit_tree(&newTree, reinterpret_cast<git_commit*>(newCommitObj));

    if (resultCode != 0) {
        git_object_free(oldCommitObj);
        git_object_free(newCommitObj);
        return GitResult(false, QVariant(), "Failed to retrieve trees for the commits.");
    }

    // Set up diff options
    git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
    opts.flags |= GIT_DIFF_PATIENCE | GIT_DIFF_INDENT_HEURISTIC | GIT_DIFF_MINIMAL;

    QByteArray pathBytes = filePath.toUtf8();
    char* path = const_cast<char*>(pathBytes.constData());
    opts.pathspec.strings = &path;
    opts.pathspec.count = 1;

    // Create the diff between the two trees
    resultCode = git_diff_tree_to_tree(&diff,  m_currentRepo->repo, oldTree, newTree, &opts);
    if (resultCode != 0) {
        git_tree_free(oldTree);
        git_tree_free(newTree);
        git_object_free(oldCommitObj);
        git_object_free(newCommitObj);
        return GitResult(false, QVariant(), "Failed to create diff between the commits.");
    }

    // Process the diff and convert it to GitDiff objects
    std::vector<GitDiff> rawLines;
    git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, [](const git_diff_delta*, const git_diff_hunk*, const git_diff_line *line, void *payload) -> int {
        auto *vec = static_cast<std::vector<GitDiff>*>(payload);
        if (line->origin == GIT_DIFF_LINE_CONTEXT ||
            line->origin == GIT_DIFF_LINE_ADDITION ||
            line->origin == GIT_DIFF_LINE_DELETION) {

            QString content = QString::fromUtf8(line->content, line->content_len);
            content.remove('\n').remove('\r');

            GitDiff::DiffType type;
            if (line->origin == GIT_DIFF_LINE_ADDITION) {
                type = GitDiff::Added;
            } else if (line->origin == GIT_DIFF_LINE_DELETION) {
                type = GitDiff::Deleted;
            } else {
                type = GitDiff::Context;
            }

            vec->push_back(GitDiff(type, line->old_lineno, line->new_lineno, content));
        }
        return 0;
    }, &rawLines);

    // Convert the diff lines to QVariantList
    for (const auto& diffLine : rawLines) {
        result.append(diffLine);
    }

    // Clean up
    git_diff_free(diff);
    git_tree_free(oldTree);
    git_tree_free(newTree);
    git_object_free(oldCommitObj);
    git_object_free(newCommitObj);

    // Return the result with the diff lines
    return GitResult(true, QVariant::fromValue(result), "Commit diff retrieved successfully.");
}

GitResult GitStatus::getCommitFileChanges(const QString &commitHash)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "repository not open.");

    if (commitHash.isEmpty())
        return GitResult(false, QVariant(), "Invalid commit hash.");

    // Retrieve commit object for the specified commit hash
    git_commit *commit = nullptr;
    git_object *commitObj = nullptr;
    int result = git_revparse_single(&commitObj,  m_currentRepo->repo, commitHash.toUtf8().constData());
    if (result != GIT_OK || !commitObj) {
        return GitResult(false, QVariant(), "Failed to retrieve commit.");
    }
    commit = reinterpret_cast<git_commit*>(commitObj);

    // Retrieve the commit tree (snapshot of the file system for this commit)
    git_tree *commitTree = nullptr;
    result = git_commit_tree(&commitTree, commit);
    if (result != GIT_OK || !commitTree) {
        git_object_free(commitObj);
        return GitResult(false, QVariant(), "Failed to retrieve commit tree.");
    }

    // Retrieve the parent tree if the commit has parents (i.e., it's not the initial commit)
    git_tree *parentTree = nullptr;
    if (git_commit_parentcount(commit) > 0) {
        git_commit *parent = nullptr;
        result = git_commit_parent(&parent, commit, 0);  // Get the first parent
        if (result != GIT_OK || !parent) {
            git_tree_free(commitTree);
            git_object_free(commitObj);
            return GitResult(false, QVariant(), "Failed to retrieve parent commit.");
        }
        result = git_commit_tree(&parentTree, parent);
        git_commit_free(parent);
        if (result != GIT_OK || !parentTree) {
            git_tree_free(commitTree);
            git_object_free(commitObj);
            return GitResult(false, QVariant(), "Failed to retrieve parent tree.");
        }
    }

    // Retrieve the diff between the commit and its parent
    git_diff *diff = nullptr;
    GitResult diffResult = getDiffBetweenTrees(parentTree, commitTree, diff);
    if (!diffResult.success()) {
        git_tree_free(commitTree);
        git_tree_free(parentTree);
        git_object_free(commitObj);
        return GitResult(false, QVariant(), diffResult.errorMessage());
    }

    // Process the diff result and return the file changes
    QList<GitFileStatus> fileChanges = processDiff(diff);
    git_diff_free(diff);
    git_tree_free(commitTree);
    git_tree_free(parentTree);
    git_object_free(commitObj);

    return GitResult(true, QVariant::fromValue(fileChanges), "File changes retrieved successfully.");
}


GitResult GitStatus::getDiffBetweenTrees(git_tree* oldTree, git_tree* newTree, git_diff*& diff)
{
    git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
    opts.flags |= GIT_DIFF_PATIENCE | GIT_DIFF_INDENT_HEURISTIC | GIT_DIFF_MINIMAL;

    int result = git_diff_tree_to_tree(&diff, m_currentRepo->repo, oldTree, newTree, &opts);
    if (result != GIT_OK || !diff) {
        return GitResult(false, QVariant(), "Failed to create diff between trees.");
    }
    return GitResult(true, QVariant(), "Diff created successfully.");
}

QList<GitFileStatus> GitStatus::processDiff(git_diff* diff)
{
    QList<GitFileStatus> fileList;

    size_t numDeltas = git_diff_num_deltas(diff);
    for (size_t i = 0; i < numDeltas; ++i) {
        const git_diff_delta *delta = git_diff_get_delta(diff, i);

        // Get the file patch for each delta
        git_patch *patch = nullptr;
        size_t additions = 0, deletions = 0;
        int result = git_patch_from_diff(&patch, diff, i);
        if (result == GIT_OK && patch) {
            git_patch_line_stats(nullptr, &additions, &deletions, patch);
            git_patch_free(patch);
        }

        int addCount = static_cast<int>(additions);
        int delCount = static_cast<int>(deletions);

        GitFileStatus fileInfo = GitFileStatus(delta, addCount, delCount);

        fileList.append(fileInfo);
    }

    return fileList;
}
