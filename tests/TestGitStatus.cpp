#include <QtTest/QtTest>

#include "Git/GitStatus.h"

class TestGitStatus : public QObject
{
    Q_OBJECT

private slots:
    void stageFileRejectsEmptyPath()
    {
        GitStatus status;
        GitResult result = status.stageFile(QString());
        QVERIFY(!result.success());
    }

    void headHashEmptyWithoutRepo()
    {
        GitStatus status;
        QCOMPARE(status.getHeadHash(), QString());
    }
};

QTEST_MAIN(TestGitStatus)
#include "TestGitStatus.moc"
