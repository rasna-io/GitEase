#include "GitConflict.h"
#include <git2.h>
#include <QFile>
#include <QDir>
#include <QTextStream>

GitConflict::GitConflict(QObject* parent)
    : IGitController(parent)
{
}

GitResult GitConflict::getConflicts()
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository is not open.");

    git_index* index = nullptr;
    if (git_repository_index(&index, activeRepo()) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to read repository index.");

    QVariantList conflicts;

    if (git_index_has_conflicts(index)) {
        git_index_conflict_iterator* iter = nullptr;
        if (git_index_conflict_iterator_new(&iter, index) == 0) {
            const git_index_entry *ancestor, *ours, *theirs;
            while (git_index_conflict_next(&ancestor, &ours, &theirs, iter) == 0) {
                // Determine file path
                QString path;
                if (ours && ours->path)
                    path = QString::fromUtf8(ours->path);
                else if (theirs && theirs->path)
                    path = QString::fromUtf8(theirs->path);
                else if (ancestor && ancestor->path)
                    path = QString::fromUtf8(ancestor->path);

                if (path.isEmpty())
                    continue;

                // Read working file lines
                QStringList lines = readWorkdirLines(path);
                if (lines.isEmpty())
                    continue; // Should not happen, but skip if file missing

                // Parse conflict blocks
                QVariantList blocks = parseConflictBlocks(lines);

                QVariantMap entry;
                entry["path"] = path;
                entry["lines"] = lines;
                entry["blocks"] = blocks;
                conflicts.append(entry);
            }
            git_index_conflict_iterator_free(iter);
        }
    }

    git_index_free(index);
    return GitResult(true, conflicts);
}

GitResult GitConflict::writeWorkingFile(const QString& filePath, const QString& content)
{
    if (!writeFile(filePath, content))
        return GitResult(false, QVariant(), "Failed to write file.");
    return GitResult(true);
}

QStringList GitConflict::readWorkdirLines(const QString& filePath) const
{
    const char* workdir = git_repository_workdir(activeRepo());
    if (!workdir)
        return QStringList();

    QString fullPath = QDir(QString::fromUtf8(workdir)).filePath(filePath);
    QFile file(fullPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return QStringList();

    QTextStream stream(&file);
    QString content = stream.readAll();
    file.close();

    // Normalize line endings
    content.replace("\r\n", "\n");
    content.replace('\r', '\n');
    return content.split('\n', Qt::KeepEmptyParts);
}

QVariantList GitConflict::parseConflictBlocks(const QStringList& lines) const
{
    QVariantList blocks;
    enum State
    {
        Neutral, InOurs, InTheirs
    } state = Neutral;

    int blockIndex = 0;         // unique conflict id
    int startLine = 0;          // where conflict begins
    QStringList oursLines, theirsLines;  // collected HEAD lines // collected incoming lines
    QVariantList blockLines; // for debug/display

    for (int i = 0; i < lines.size(); ++i) {
        const QString& line = lines[i];
        int lineNumber = i + 1;

        if (line.startsWith("<<<<<<<")) {
            // Start of a new conflict block
            if (state != Neutral) {
                // Malformed, skip
            }
            state = InOurs;
            startLine = lineNumber;
            blockIndex++;
            oursLines.clear();
            theirsLines.clear();
            blockLines.clear();
            blockLines.append(QVariantMap{{"number", lineNumber}, {"text", line}, {"role", "marker-start"}});
            continue;
        }

        if (line.startsWith("=======")) {
            if (state == InOurs) {
                state = InTheirs;
                blockLines.append(QVariantMap{{"number", lineNumber}, {"text", line}, {"role", "separator"}});
            } else {
                // Malformed, reset
                state = Neutral;
            }
            continue;
        }

        if (line.startsWith(">>>>>>>")) {
            if (state == InTheirs) {
                // End of block
                blockLines.append(QVariantMap{{"number", lineNumber}, {"text", line}, {"role", "marker-end"}});

                QVariantMap block;
                block["index"] = blockIndex;
                block["startLine"] = startLine;
                block["endLine"] = lineNumber;
                block["currentText"] = oursLines.join("\n");
                block["incomingText"] = theirsLines.join("\n");
                block["lines"] = blockLines;
                blocks.append(block);

                state = Neutral;
            } else {
                state = Neutral;
            }
            continue;
        }

        if (state == InOurs) {
            oursLines.append(line);
            blockLines.append(QVariantMap{{"number", lineNumber}, {"text", line}, {"role", "ours"}});
        } else if (state == InTheirs) {
            theirsLines.append(line);
            blockLines.append(QVariantMap{{"number", lineNumber}, {"text", line}, {"role", "theirs"}});
        }
        // else: context lines; they are handled by the UI via the full lines list
    }

    return blocks;
}

GitResult GitConflict::acceptBlockOurs(const QString& filePath, int blockIndex)
{
    return replaceBlock(filePath, blockIndex, true, false, false);
}

GitResult GitConflict::acceptBlockTheirs(const QString& filePath, int blockIndex)
{
    return replaceBlock(filePath, blockIndex, false, true, false);
}

GitResult GitConflict::acceptBlockBoth(const QString& filePath, int blockIndex)
{
    return replaceBlock(filePath, blockIndex, false, false, true);
}

GitResult GitConflict::replaceBlock(const QString& filePath, int blockIndex,
                                    bool useOurs, bool useTheirs, bool useBoth)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open.");

    // Read current file
    QStringList lines = readWorkdirLines(filePath);
    if (lines.isEmpty())
        return GitResult(false, QVariant(), "Failed to read file.");

    // Re-parse blocks to get accurate positions (in case file was edited)
    QVariantList blocks = parseConflictBlocks(lines);
    QVariantMap targetBlock;
    for (const QVariant& b : blocks) {
        QVariantMap block = b.toMap();
        if (block.value("index").toInt() == blockIndex) {
            targetBlock = block;
            break;
        }
    }
    if (targetBlock.isEmpty())
        return GitResult(false, QVariant(), "Block not found.");

    int startLine = targetBlock.value("startLine").toInt();
    int endLine = targetBlock.value("endLine").toInt();

    QString replacement;
    if (useOurs)
        replacement = targetBlock.value("currentText").toString();
    else if (useTheirs)
        replacement = targetBlock.value("incomingText").toString();
    else if (useBoth) {
        QString ours = targetBlock.value("currentText").toString();
        QString theirs = targetBlock.value("incomingText").toString();
        if (!ours.isEmpty() && !theirs.isEmpty())
            replacement = ours + "\n" + theirs;
        else if (!ours.isEmpty())
            replacement = ours;
        else
            replacement = theirs;
    }

    // Build new file content
    QStringList prefix = lines.mid(0, startLine - 1);
    QStringList suffix = lines.mid(endLine); // lines after the block
    QStringList replacementLines;
    if (!replacement.isEmpty())
        replacementLines = replacement.split('\n', Qt::KeepEmptyParts);

    QStringList newLines = prefix + replacementLines + suffix;
    QString newContent = newLines.join('\n');

    // Write to working directory
    if (!writeFile(filePath, newContent))
        return GitResult(false, QVariant(), "Failed to write file.");

    return GitResult(true);
}

bool GitConflict::writeFile(const QString& filePath, const QString& content) const
{
    const char* workdir = git_repository_workdir(activeRepo());
    if (!workdir)
        return false;

    QString fullPath = QDir(QString::fromUtf8(workdir)).filePath(filePath);
    QFile file(fullPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;

    QByteArray data = content.toUtf8();
    file.write(data);
    file.close();
    return true;
}
