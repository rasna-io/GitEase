#include <QtTest/QtTest>

#include "Utilities/SshKeyManager/SshKeyManager.h"

class TestSshKeyManager : public QObject
{
    Q_OBJECT

private slots:
    void deleteKeyRequiresName()
    {
        SshKeyManager manager;
        GitResult result = manager.deleteKeyByName(QString());
        QVERIFY(!result.success());
    }

    void generatingFlagStartsFalse()
    {
        SshKeyManager manager;
        QCOMPARE(manager.isGenerating(), false);
    }
};

QTEST_MAIN(TestSshKeyManager)
#include "TestSshKeyManager.moc"
