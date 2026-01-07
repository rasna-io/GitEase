#pragma once

#include <QObject>
#include <git2/types.h>
#include <QQmlEngine>

class Commit
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(QString message READ message CONSTANT FINAL)
    Q_PROPERTY(QString hash READ hash CONSTANT FINAL)
    Q_PROPERTY(QString shortHash READ shortHash CONSTANT FINAL)
    Q_PROPERTY(QString summary READ summary CONSTANT FINAL)
    Q_PROPERTY(QString author READ author CONSTANT FINAL)
    Q_PROPERTY(QString authorEmail READ authorEmail CONSTANT FINAL)
    Q_PROPERTY(QString authorDate READ authorDate CONSTANT FINAL)
    Q_PROPERTY(QString treeHash READ treeHash CONSTANT FINAL)
    Q_PROPERTY(QStringList parentHashes READ parentHashes CONSTANT FINAL)
public:
    explicit Commit();

    Commit(const QString &message, const QString &hash, const QString &shortHash,
           const QString &summary, const QString &author, const QString &authorEmail,
           const QString &authorDate);

    Commit(const git_commit *gitCommit);

    QString message() const;

    QString hash() const;

    QString shortHash() const;

    QString summary() const;

    QString author() const;

    QString authorEmail() const;

    QString authorDate() const;

    QStringList parentHashes() const;
    void setparentHashes(const QStringList &newParentHashes);

    QString treeHash() const;
    void setTreeHash(const QString &newTreeHash);



private:
    QString m_message;
    QString m_hash;
    QString m_shortHash;
    QString m_summary;
    QString m_author;
    QString m_authorEmail;
    QString m_authorDate;
    QStringList m_parentHashes;
    QString m_treeHash;
};

Q_DECLARE_METATYPE(Commit)
