#include <QtTest/QtTest>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>

#include "Utilities/FileManager/FileIO.hpp"

class TestFileIO : public QObject
{
    Q_OBJECT

private slots:
    void writeReadRoundTrip();
    void readWithoutFileNameEmitsFailure();
    void pathNormalizer();
    void createDirBehavior();
    void isFileExistBehavior();
};

void TestFileIO::writeReadRoundTrip()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    FileIO fileIo;
    const QString filePath = dir.path() + "/payload.txt";
    fileIo.setFileName(filePath);
    fileIo.setFileContent("hello from test");

    QSignalSpy writeSpy(&fileIo, SIGNAL(writeOpResult(bool,QString)));
    fileIo.write(false);
    QCOMPARE(writeSpy.count(), 1);
    QCOMPARE(writeSpy.at(0).at(0).toBool(), true);

    QSignalSpy readSpy(&fileIo, SIGNAL(fileContentChanged(QString)));
    fileIo.setFileContent("");
    fileIo.read(false);
    QVERIFY(readSpy.count() >= 1);
    QCOMPARE(fileIo.fileContent(), QString("hello from test"));
}

void TestFileIO::readWithoutFileNameEmitsFailure()
{
    FileIO fileIo;
    QSignalSpy failSpy(&fileIo, SIGNAL(readingFailed(QString)));

    fileIo.read(false);
    QCOMPARE(failSpy.count(), 1);
    QVERIFY(!failSpy.at(0).at(0).toString().isEmpty());
}

void TestFileIO::pathNormalizer()
{
    FileIO fileIo;
#ifdef Q_OS_WIN
    QCOMPARE(fileIo.pathNormalizer("file:///C:/temp/dir/../file.txt"), QString("C:/temp/file.txt"));
    QCOMPARE(fileIo.pathNormalizer("//server/share/file.txt"), QString(""));
    QCOMPARE(fileIo.pathNormalizer("relative/path.txt"), QString(""));
#else
    QCOMPARE(fileIo.pathNormalizer("tmp/dir/../file.txt"), QString("/tmp/file.txt"));
    QCOMPARE(fileIo.pathNormalizer("/var/log/../tmp/test.log"), QString("/var/tmp/test.log"));
#endif
}

void TestFileIO::createDirBehavior()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    FileIO fileIo;
    const QString newDir = dir.path() + "/nested";

    QVERIFY(fileIo.createDir(newDir));
    QVERIFY(!fileIo.createDir(newDir));
}

void TestFileIO::isFileExistBehavior()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    FileIO fileIo;
    const QString filePath = dir.path() + "/exists.txt";
    QVERIFY(!fileIo.isFileExist(filePath));

    QFile file(filePath);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("x");
    file.close();

    QVERIFY(fileIo.isFileExist(filePath));
}

QTEST_MAIN(TestFileIO)
#include "TestFileIO.moc"
