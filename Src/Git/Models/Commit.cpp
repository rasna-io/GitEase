#include "Commit.h"

#include <git2/deprecated.h>

#include <QDateTime>

Commit::Commit()
{}

Commit::Commit(const QString &message, const QString &hash, const QString &shortHash,
               const QString &summary, const QString &author, const QString &authorEmail,
               const QString &authorDate) : m_message(message),
    m_hash(hash),
    m_shortHash(shortHash),
    m_summary(summary),
    m_author(author),
    m_authorEmail(authorEmail),
    m_authorDate(authorDate)
{}

Commit::Commit(const git_commit *gitCommit)
{

    if (!gitCommit)
        return;

    // Get commit hash
    char hash[GIT_OID_HEXSZ + 1];
    git_oid_tostr(hash, sizeof(hash), git_commit_id(gitCommit));

    m_hash = QString::fromUtf8(hash);
    m_shortHash = QString::fromUtf8(hash).left(7);

    // Get commit message
    m_message = QString::fromUtf8(git_commit_message(gitCommit));

    // Get summary (first line of message)
    QString fullMessage = m_message;
    QStringList lines = fullMessage.split("\n");
    m_summary = lines.first();

    // Get author information
    const git_signature *author = git_commit_author(gitCommit);
    if (author) {
        m_author= QString::fromUtf8(author->name);
        m_authorEmail = QString::fromUtf8(author->email);
        QDateTime authorDate = QDateTime::fromSecsSinceEpoch(author->when.time);
        m_authorDate = authorDate.toString(Qt::ISODate);
    }
}

QString Commit::message() const
{
    return m_message;
}

QString Commit::hash() const
{
    return m_hash;
}


QString Commit::shortHash() const
{
    return m_shortHash;
}

QString Commit::summary() const
{
    return m_summary;
}


QString Commit::author() const
{
    return m_author;
}

QString Commit::authorEmail() const
{
    return m_authorEmail;
}

QString Commit::authorDate() const
{
    return m_authorDate;
}

QStringList Commit::parentHashes() const
{
    return m_parentHashes;
}

void Commit::setparentHashes(const QStringList &newParentHashes)
{
    m_parentHashes = newParentHashes;
}

QString Commit::treeHash() const
{
    return m_treeHash;
}

void Commit::setTreeHash(const QString &newTreeHash)
{
    m_treeHash = newTreeHash;
}
