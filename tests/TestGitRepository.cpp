#include <QtTest/QtTest>
#include <git2.h>

#include "Git/GitRepository.h"

class TestGitRepository : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QVERIFY(git_libgit2_init() >= 0);
    }

    void cleanupTestCase()
    {
        git_libgit2_shutdown();
    }

    void initFailsWithEmptyPath()
    {
        GitRepository repo;
        GitResult result = repo.init(QString());
        QVERIFY(!result.success());
    }

    void detectProtocolEmptyIsUnknown()
    {
        GitRepository repo;
        QCOMPARE(repo.detectGitProtocol(QString()), static_cast<int>(GitRepository::GitProtocol::Unknown));
    }

    void closeWithoutOpenSucceeds()
    {
        GitRepository repo;
        GitResult result = repo.close();
        QVERIFY(result.success());
    }
};

QTEST_MAIN(TestGitRepository)
#include "TestGitRepository.moc"
