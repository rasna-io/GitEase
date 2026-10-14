#pragma once

#include <QSet>
#include <QString>
#include <QStringList>

/*!
 * The .gitignore in the root of a repository, held as a list of lines so rules can be added or
 * removed without disturbing the rest. The original line ending (LF or CRLF) is kept on save.
 */
struct IgnoreFile
{
    bool        exists = false;
    QString     eol    = QStringLiteral("\n");
    QStringList lines;

    //! Reads <root>/.gitignore; \a exists stays false when there is none.
    static IgnoreFile read(const QString &root);

    //! Path of the file inside \a root.
    static QString filePath(const QString &root);

    //! Writes the lines back with the original line ending. Fills \a error on failure.
    bool save(const QString &root, QString *error) const;

    //! The trimmed rules of the file, without comments and blank lines.
    QSet<QString> patterns() const;
};

//! True for a rule: not blank and not a comment.
bool isPattern(const QString &line);
