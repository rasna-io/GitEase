#include "GitDiff.h"

GitDiff::GitDiff()
{}

GitDiff::DiffType GitDiff::type() const
{
    return m_type;
}

int GitDiff::oldLine() const
{
    return m_oldLine;
}

int GitDiff::newLine() const
{
    return m_newLine;
}

QString GitDiff::content() const
{
    return m_content;
}

GitDiff::GitDiff(GitDiff::DiffType type, int oldLine, int newLine,
                 const QString &content) : m_type(type),
    m_oldLine(oldLine),
    m_newLine(newLine),
    m_content(content)
{}

QString GitDiff::newContent() const
{
    return m_newContent;
}

GitDiff::GitDiff(GitDiff::DiffType type, int oldLine, int newLine, const QString &content, const QString &newContent) : m_type(type),
    m_oldLine(oldLine),
    m_newLine(newLine),
    m_content(content),
    m_newContent(newContent)
{}
