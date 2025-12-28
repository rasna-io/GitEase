#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>

class FileIO : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_DISABLE_COPY(FileIO)

    Q_PROPERTY(QString fileName READ fileName WRITE setFileName NOTIFY fileNameChanged FINAL)
    Q_PROPERTY(QString fileContent READ fileContent WRITE setFileContent NOTIFY fileContentChanged FINAL)
    Q_PROPERTY(QString configFilePath  MEMBER  m_configFilePath     CONSTANT)

public:
    explicit FileIO(QObject *parent = nullptr);

    QString fileName() const;
    QString fileContent() const;

public:
    Q_INVOKABLE void read(bool async = false);
    Q_INVOKABLE void write(bool async = false);
    Q_INVOKABLE bool createDir(QString path);
    Q_INVOKABLE bool isFileExist(const QString &path);

    void setFileName(QString filename);
    void setFileContent(QString fileContent);
    Q_INVOKABLE QString pathNormalizer(const QString &path);

signals:
    void fileNameChanged(QString);
    void fileContentChanged(QString);
    void writeOpResult(bool, QString= "");
    void readingFailed(QString);

private:
    QString m_fileName;
    QString m_fileContent;
    QString m_configFilePath;
};
