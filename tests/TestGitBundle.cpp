#include <QtTest/QtTest>

#include "Git/GitBundle.h"

class TestGitBundle : public QObject
{
    Q_OBJECT

private slots:
    void unbundleWithMissingFileFails()
    {
        GitBundle bundle;
        GitResult result = bundle.unbundleWithCli("nonexistent.bundle");
        QVERIFY(!result.success());
    }
};

QTEST_MAIN(TestGitBundle)
#include "TestGitBundle.moc"
