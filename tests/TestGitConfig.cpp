#include <QtTest/QtTest>

#include "Git/GitConfig.h"
#include "Git/Models/Config.h"

class TestGitConfig : public QObject
{
    Q_OBJECT

private slots:
    void localConfigRequiresRepository()
    {
        GitConfig config;
        const int localLevel = static_cast<int>(Config::ConfigLevel::Local);
        GitResult result = config.getConfig(localLevel);
        QVERIFY(!result.success());
    }

    void invalidLevelIsRejected()
    {
        GitConfig config;
        GitResult result = config.setValue(99, "user.name", "tester");
        QVERIFY(!result.success());
    }
};

QTEST_MAIN(TestGitConfig)
#include "TestGitConfig.moc"
