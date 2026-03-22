#include <QtTest/QtTest>

#include "Git/Utilities/GitProtocolDetector.h"

class TestGitProtocolDetector : public QObject
{
    Q_OBJECT

private slots:
    void detectProtocol_data();
    void detectProtocol();
    void isProtocolHelpers();
    void extractRepositoryName_data();
    void extractRepositoryName();
};

void TestGitProtocolDetector::detectProtocol_data()
{
    QTest::addColumn<QString>("url");
    QTest::addColumn<int>("expected");

    QTest::newRow("ssh-scp") << "git@github.com:owner/repo.git"
                             << static_cast<int>(GitProtocolDetector::GitProtocol::SSH);
    QTest::newRow("ssh-url") << "ssh://git@github.com/owner/repo.git"
                             << static_cast<int>(GitProtocolDetector::GitProtocol::SSH);
    QTest::newRow("https") << "https://github.com/owner/repo.git"
                           << static_cast<int>(GitProtocolDetector::GitProtocol::HTTPS);
    QTest::newRow("http") << "http://github.com/owner/repo.git"
                          << static_cast<int>(GitProtocolDetector::GitProtocol::HTTP);
    QTest::newRow("unknown") << "github.com/owner/repo.git"
                             << static_cast<int>(GitProtocolDetector::GitProtocol::Unknown);
    QTest::newRow("empty") << ""
                           << static_cast<int>(GitProtocolDetector::GitProtocol::Unknown);
}

void TestGitProtocolDetector::detectProtocol()
{
    QFETCH(QString, url);
    QFETCH(int, expected);

    const auto protocol = GitProtocolDetector::detectProtocol(url);
    QCOMPARE(static_cast<int>(protocol), expected);
}

void TestGitProtocolDetector::isProtocolHelpers()
{
    QVERIFY(GitProtocolDetector::isSshUrl("git@github.com:owner/repo.git"));
    QVERIFY(GitProtocolDetector::isHttpsUrl("https://github.com/owner/repo.git"));
    QVERIFY(GitProtocolDetector::isHttpUrl("http://github.com/owner/repo.git"));
    QVERIFY(!GitProtocolDetector::isSshUrl("https://github.com/owner/repo.git"));
}

void TestGitProtocolDetector::extractRepositoryName_data()
{
    QTest::addColumn<QString>("url");
    QTest::addColumn<QString>("expected");

    QTest::newRow("ssh-scp") << "git@github.com:owner/repo.git" << "repo";
    QTest::newRow("https") << "https://github.com/owner/repo.git" << "repo";
    QTest::newRow("without-git") << "https://github.com/owner/repo" << "repo";
    QTest::newRow("empty") << "" << "";
}

void TestGitProtocolDetector::extractRepositoryName()
{
    QFETCH(QString, url);
    QFETCH(QString, expected);

    QCOMPARE(GitProtocolDetector::extractRepositoryName(url), expected);
}

QTEST_MAIN(TestGitProtocolDetector)
#include "TestGitProtocolDetector.moc"
