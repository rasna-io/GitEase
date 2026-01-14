#pragma once

#include <QObject>
#include <QQmlEngine>

class GitDiff
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(DiffType type READ type CONSTANT FINAL)
    Q_PROPERTY(int oldLine READ oldLine CONSTANT FINAL)
    Q_PROPERTY(int newLine READ newLine CONSTANT FINAL)
    Q_PROPERTY(QString content READ content CONSTANT FINAL)
    Q_PROPERTY(QString newContent READ newContent CONSTANT FINAL)

public:
    enum DiffType {
        Context = 0,
        Added = 1,
        Deleted = 2,
        Modified = 3
    };
    Q_ENUM(DiffType)

    explicit GitDiff();
    GitDiff(DiffType type, int oldLine, int newLine, const QString &content);
    GitDiff(DiffType type, int oldLine, int newLine, const QString &content, const QString &newContent);


    DiffType type() const;

    int oldLine() const;

    int newLine() const;

    QString content() const;

    QString newContent() const;


private:
    DiffType m_type;
    int m_oldLine;
    int m_newLine;
    QString m_content;
    QString m_newContent;
};