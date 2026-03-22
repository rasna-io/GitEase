#include <QtTest/QtTest>

#include "Git/GitStash.h"

class TestGitStash : public QObject
{
    Q_OBJECT

private slots:
    void listFailsWithoutRepository()
    {
        GitStash stash;
        GitResult result = stash.list();
        QVERIFY(!result.success());
    }
};

QTEST_MAIN(TestGitStash)
#include "TestGitStash.moc"
