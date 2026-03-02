#include <QtTest/QtTest>

#include "Git/GitCommit.h"

class TestGitCommit : public QObject
{
    Q_OBJECT

private slots:
    void validateRejectsEmptyMessage()
    {
        GitCommit commit;
        QVERIFY(!commit.validateCommitMessage(QString()));
    }

    void validateRejectsTrailingWhitespace()
    {
        GitCommit commit;
        QVERIFY(!commit.validateCommitMessage("message "));
    }

    void validateAcceptsSimpleMessage()
    {
        GitCommit commit;
        QVERIFY(commit.validateCommitMessage("Fix issue"));
    }
};

QTEST_MAIN(TestGitCommit)
#include "TestGitCommit.moc"
