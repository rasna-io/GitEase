#include "GitStatus.h"
#include "GitDiff.h"
#include "GitFileStatus.h"
#include <QDir>
#include <QFile>
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

    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    // Get the HEAD commit to use as the reset source
    git_object *head_obj = nullptr;
    int error = git_revparse_single(&head_obj, m_currentRepo->repo, "HEAD");
    if (error != GIT_OK) {
        // If there is no HEAD (empty repo), we just remove the path from the index
        return addToIndex(filePath, true);
    }

    QByteArray pathUtf8 = filePath.toUtf8();
    char* paths[] = { pathUtf8.data() };
    git_strarray array = { paths, 1 };

    // Reset the Index entry for this path to match the HEAD version
    error = git_reset_default(m_currentRepo->repo, head_obj, &array);
    git_object_free(head_obj);

    if (error != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to reset index for file.");
    }

    return GitResult(true, filePath, "File unstaged successfully.");
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

GitResult GitStatus::getDiffView(const QString &filePath)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    // old/index text
    uint32_t mode = 0;
    auto indexBlob = getIndexBlob(m_currentRepo->repo, filePath, &mode);
    QString oldText;
    if (indexBlob) {
        oldText = joinLines(readBlobLines(indexBlob.get()));
    } else {
        oldText = "";
    }

    // new/workdir text
    QString newText = joinLines(readWorkdirLines(m_currentRepo->repo, filePath));

    // diff lines (existing)
    GitResult diffRes = getDiff(filePath);
    if (!diffRes.success())
        return diffRes;

    QVariantMap out;
    out["oldText"] = oldText;
    out["newText"] = newText;
    out["lines"] = diffRes.data();

    return GitResult(true, out);
}
GitResult GitStatus::stageSelectedLines(const QString &filePath, int startLine, int endLine, int mode)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    const git_delta_t type = static_cast<git_delta_t>(mode);
    uint32_t baseMode = 0;
    auto indexBlob = getIndexBlob(m_currentRepo->repo, filePath, &baseMode);

    if (!indexBlob) {
        return GitResult(false, QVariant(), "File does not exist in the index.");
    }

    const auto indexLines = readBlobLines(indexBlob.get());

    git_diff* diffRaw = nullptr;
    git_diff_options diffOpts = GIT_DIFF_OPTIONS_INIT;
    diffOpts.flags |= (GIT_DIFF_PATIENCE | GIT_DIFF_MINIMAL);

    // If the file is physically gone (DELETED), we need a diff that represents the
    // total removal, so we can pick which "removals" to stage.
    if (type == GIT_DELTA_DELETED) {
        git_tree* headTree = nullptr;
        git_diff_index_to_workdir(&diffRaw, m_currentRepo->repo, nullptr, &diffOpts);
    } else {
        QByteArray pathUtf8 = filePath.toUtf8();
        char* path = const_cast<char*>(pathUtf8.constData());
        diffOpts.pathspec.strings = &path;
        diffOpts.pathspec.count = 1;
        git_diff_index_to_workdir(&diffRaw, m_currentRepo->repo, nullptr, &diffOpts);
    }

    UniqueDiff diff(diffRaw);
    git_patch* patchRaw = nullptr;
    if (git_patch_from_diff(&patchRaw, diff.get(), 0) != GIT_OK)
        return GitResult(false, QVariant(), "Could not generate patch for selection.");

    UniquePatch patch(patchRaw);

    const auto stagedLines = applySelectedFromPatch(indexLines, patch.get(), startLine, endLine);
    const QString stagedText = joinLines(stagedLines);

    return writeIndexFromBuffer(m_currentRepo->repo, filePath, stagedText.toUtf8(), baseMode);
}

GitResult GitStatus::writeIndexFromBuffer(git_repository* repo,
                                          const QString& filePath,
                                          const QByteArray& contentUtf8,
                                          uint32_t modeIfKnown)
{
    git_index* idxRaw = nullptr;
    if (git_repository_index(&idxRaw, repo) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to open index");

    UniqueIndex idx(idxRaw);

    git_index_entry entry;
    std::memset(&entry, 0, sizeof(entry));

    QByteArray p = filePath.toUtf8();
    entry.path = p.constData();

    // Use existing mode if available; default to 0100644 for a normal file.
    entry.mode = (modeIfKnown != 0) ? modeIfKnown : 0100644;

    const int rc = git_index_add_frombuffer(idx.get(), &entry,
                                            contentUtf8.constData(),
                                            (size_t)contentUtf8.size());
    if (rc != GIT_OK)
        return GitResult(false, QVariant(), "git_index_add_frombuffer failed");

    if (git_index_write(idx.get()) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to write index");

    return GitResult(true, QVariant(), "Selected lines staged into index");
}

std::vector<QString> GitStatus::readWorkdirLines(git_repository* repo, const QString& filePath)
{
    const char* wd = git_repository_workdir(repo);
    if (!wd) return {};

    const QString absPath = QDir(QString::fromUtf8(wd)).filePath(filePath);
    QFile f(absPath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    QTextStream in(&f);
    QString raw = in.readAll();
    return splitLines(raw);
}

std::vector<QString> GitStatus::applySelectedFromPatch(const std::vector<QString> &indexLines,
                                                       git_patch *patch,
                                                       int startLine,
                                                       int endLine)
{
    std::vector<QString> out;
    out.reserve(indexLines.size() + 64);

    size_t hunkCount = git_patch_num_hunks(patch);
    int basePos = 1; // Current line in the Index (old file)

    for (size_t h = 0; h < hunkCount; ++h) {
        const git_diff_hunk* hunk = nullptr;
        size_t linesInHunk = 0;
        if (git_patch_get_hunk(&hunk, &linesInHunk, patch, h) != GIT_OK) continue;

        // Copy context lines from Index that appear before this hunk
        while (basePos < (int)hunk->old_start && basePos <= (int)indexLines.size()) {
            out.push_back(indexLines[basePos - 1]);
            basePos++;
        }

        bool lastLineWasStagedDeletion = false;

        for (size_t li = 0; li < linesInHunk; ++li) {
            const git_diff_line* line = nullptr;
            git_patch_get_line_in_hunk(&line, patch, h, li);
            char origin = (char)line->origin;

            if (origin == GIT_DIFF_LINE_CONTEXT) {
                if (basePos <= (int)indexLines.size()) {
                    out.push_back(indexLines[basePos - 1]);
                }
                basePos++;
                lastLineWasStagedDeletion = false; // Reset tracking
            }
            else if (origin == GIT_DIFF_LINE_DELETION) {
                // Check if the user selected this line (using Old Line Number)
                bool stageDelete = (line->old_lineno >= startLine && line->old_lineno <= endLine);

                if (stageDelete) {
                    // Stage the deletion: skip the index line (remove it)
                    basePos++;
                    lastLineWasStagedDeletion = true;
                } else {
                    // Don't stage: Keep the original index line
                    if (basePos <= (int)indexLines.size()) {
                        out.push_back(indexLines[basePos - 1]);
                    }
                    basePos++;
                    lastLineWasStagedDeletion = false;
                }
            }
            else if (origin == GIT_DIFF_LINE_ADDITION) {
                bool stageAdd = (line->new_lineno >= startLine && line->new_lineno <= endLine) ||
                                (lastLineWasStagedDeletion);

                if (stageAdd) {
                    QString add = QString::fromUtf8(line->content, (int)line->content_len);
                    add.remove('\n').remove('\r');
                    out.push_back(add);
                }
            }
        }
    }

    // Copy remaining lines after all hunks
    while (basePos <= (int)indexLines.size()) {
        out.push_back(indexLines[basePos - 1]);
        basePos++;
    }

    return out;
}

std::vector<QString> GitStatus::readBlobLines(git_blob *blob)
{
    if (!blob) return {};
    const char* content = static_cast<const char*>(git_blob_rawcontent(blob));
    const size_t size   = git_blob_rawsize(blob);
    const QString raw   = QString::fromUtf8(content, (int)size);
    return splitLines(raw);
}

std::vector<QString> GitStatus::splitLines(const QString& raw)
{
    QString s = raw;
    s.replace("\r\n", "\n").replace('\r', '\n');
    const QStringList ql = s.split('\n', Qt::KeepEmptyParts);

    std::vector<QString> out;
    out.reserve(ql.size());
    for (const auto& x : ql) out.push_back(x);
    return out;
}

QString GitStatus::joinLines(const std::vector<QString>& lines)
{
    QString out;
    out.reserve(4096);
    for (int i = 0; i < (int)lines.size(); ++i) {
        out += lines[(size_t)i];
        if (i + 1 < (int)lines.size()) out += '\n';
    }
    return out;
}

UniqueBlob GitStatus::getIndexBlob(git_repository* repo, const QString& filePath, uint32_t* outMode)
{
    git_index* idxRaw = nullptr;
    if (git_repository_index(&idxRaw, repo) != GIT_OK)
        return UniqueBlob(nullptr);

    UniqueIndex idx(idxRaw);

    QByteArray p = filePath.toUtf8();
    const git_index_entry* ent = git_index_get_bypath(idx.get(), p.constData(), 0);
    if (!ent) return UniqueBlob(nullptr);

    if (outMode) *outMode = ent->mode;

    git_blob* blob = nullptr;
    if (git_blob_lookup(&blob, repo, &ent->id) != GIT_OK)
        return UniqueBlob(nullptr);

    return UniqueBlob(blob);
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

GitResult GitStatus::revertFile(const QString &filePath)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    // Configure checkout options
    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;

    // GIT_CHECKOUT_FORCE ensures we overwrite local workdir changes.
    // GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH prevents accidental glob expansion.
    opts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH;

    // Convert QString path to the format required by git_strarray
    QByteArray pathUtf8 = filePath.toUtf8();
    char* path = pathUtf8.data();
    opts.paths.strings = &path;
    opts.paths.count = 1;

    // Perform checkout from the index to the working directory
    int error = git_checkout_index(m_currentRepo->repo, nullptr, &opts);

    if (error != GIT_OK) {
        const git_error *e = git_error_last();
        QString errorMsg = e ? QString::fromUtf8(e->message) : "Unknown error during checkout";
        return GitResult(false, QVariant(), "Failed to revert file: " + errorMsg);
    }

    return GitResult(true, filePath, "File reverted successfully to index state.");
}

GitResult GitStatus::revertSelectedLines(const QString &filePath, int startLine, int endLine, int mode)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    // Get the "Source of Truth" (The Index/Staged version)
    uint32_t baseMode = 0;
    auto indexBlob = getIndexBlob(m_currentRepo->repo, filePath, &baseMode);
    if (!indexBlob)
        return GitResult(false, QVariant(), "File not found in index.");

    const auto indexLines = readBlobLines(indexBlob.get());

    // Generate the patch (Index -> Workdir)
    git_diff* diffRaw = nullptr;
    git_diff_options diffOpts = GIT_DIFF_OPTIONS_INIT;
    QByteArray pathUtf8 = filePath.toUtf8();
    char* path = pathUtf8.data();
    diffOpts.pathspec.strings = &path;
    diffOpts.pathspec.count = 1;
    diffOpts.flags |= (GIT_DIFF_PATIENCE | GIT_DIFF_MINIMAL);

    git_diff_index_to_workdir(&diffRaw, m_currentRepo->repo, nullptr, &diffOpts);
    UniqueDiff diff(diffRaw);

    git_patch* patchRaw = nullptr;
    if (git_patch_from_diff(&patchRaw, diff.get(), 0) != GIT_OK)
        return GitResult(false, QVariant(), "No changes to revert.");
    UniquePatch patch(patchRaw);


    std::vector<QString> out;
    int basePos = 1; // Index line pointer
    bool lastLineWasReverted = false;
    size_t hunkCount = git_patch_num_hunks(patch.get());

    for (size_t h = 0; h < hunkCount; ++h) {
        const git_diff_hunk* hunk = nullptr;
        size_t linesInHunk = 0;
        git_patch_get_hunk(&hunk, &linesInHunk, patch.get(), h);

        // Copy context/unaffected lines before the hunk
        while (basePos < (int)hunk->old_start && basePos <= (int)indexLines.size()) {
            out.push_back(indexLines[basePos - 1]);
            basePos++;
        }

        for (size_t li = 0; li < linesInHunk; ++li) {
            const git_diff_line* line = nullptr;
            git_patch_get_line_in_hunk(&line, patch.get(), h, li);
            char origin = (char)line->origin;

            if (origin == GIT_DIFF_LINE_CONTEXT) {
                if (basePos <= (int)indexLines.size()) out.push_back(indexLines[basePos - 1]);
                basePos++;
                lastLineWasReverted = false;
            }
            else if (origin == GIT_DIFF_LINE_DELETION) {
                // To revert a deletion, we MUST keep the line from the index
                bool isSelected = (line->old_lineno >= startLine && line->old_lineno <= endLine);

                if (isSelected) {
                    // REVERT: Keep the index line (don't "delete" it)
                    if (basePos <= (int)indexLines.size()) out.push_back(indexLines[basePos - 1]);
                    basePos++;
                    lastLineWasReverted = true;
                } else {
                    // DISCARD REVERT: Follow the workdir (skip the line)
                    basePos++;
                    lastLineWasReverted = false;
                }
            }
            else if (origin == GIT_DIFF_LINE_ADDITION) {
                // To revert an addition, we OMIT the line from the workdir
                bool isSelected = (line->new_lineno >= startLine && line->new_lineno <= endLine) || lastLineWasReverted;

                if (isSelected) {
                    // REVERT: Do nothing (don't add the workdir line)
                } else {
                    // DISCARD REVERT: Keep the addition from the workdir
                    QString content = QString::fromUtf8(line->content, (int)line->content_len);
                    content.remove('\n').remove('\r');
                    out.push_back(content);
                }
            }
        }
    }

    // Copy remaining lines
    while (basePos <= (int)indexLines.size()) {
        out.push_back(indexLines[basePos - 1]);
        basePos++;
    }

    // WRITE TO DISK (Physical File)
    const char* wd = git_repository_workdir(m_currentRepo->repo);
    QString absPath = QDir(QString::fromUtf8(wd)).filePath(filePath);
    QFile f(absPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        f.write(joinLines(out).toUtf8());
        f.close();
        return GitResult(true, filePath, "Selected lines reverted.");
    }

    return GitResult(false, QVariant(), "Failed to write file to disk.");
}

GitResult GitStatus::revertAll()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "No repository available.");

    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;

    // FORCE: Overwrite all local changes
    // RECREATE_MISSING: Restore files that were deleted in workdir
    opts.checkout_strategy = GIT_CHECKOUT_FORCE |
                             GIT_CHECKOUT_RECREATE_MISSING |
                             GIT_CHECKOUT_DONT_UPDATE_INDEX;

    // Passing NULL to the second parameter tells libgit2 to use HEAD
    int error = git_checkout_head(m_currentRepo->repo, &opts);

    if (error != GIT_OK) {
        const git_error *e = git_error_last();
        return GitResult(false, QVariant(),
                         QString("Failed to revert all changes: %1").arg(e ? e->message : "Unknown error"));
    }

    return GitResult(true, QVariant(), "All changes discarded.");
}
