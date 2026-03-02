#include <QtTest/QtTest>

#include "Git/GitBranch.h"

class TestGitBranch : public QObject
{
    Q_OBJECT

private slots:
    void returnsFailureWithoutRepository()
    {
        GitBranch branch;
        GitResult result = branch.createBranch("feature");
        QVERIFY(!result.success());
        QCOMPARE(branch.getBranches().size(), 0);
    }
};

QTEST_MAIN(TestGitBranch)
#include "TestGitBranch.moc"
