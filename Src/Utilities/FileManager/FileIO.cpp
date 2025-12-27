#include "FileIO.hpp"

#include <QDebug>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

#include <thread>


FileIO::FileIO(QObject *parent) : QObject(parent),
    m_configFilePath { QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) }
{

}

QString FileIO::fileName() const
{
    return m_fileName;
}

QString FileIO::fileContent() const
{
    return m_fileContent;
}

void FileIO::setFileName(QString filename)
{
    if(m_fileName != filename)
    {
        setFileContent("");
        m_fileName = filename;
        emit fileNameChanged(m_fileName);
    }
}

void FileIO::setFileContent(QString fileContent)
{
    if(m_fileContent != fileContent)
    {
        m_fileContent = fileContent;
        emit fileContentChanged(m_fileContent);
    }
}

QString FileIO::pathNormalizer(const QString &path)
{
    QString normalizedPath = path;
    if (path.startsWith("file:///")) {
        normalizedPath = normalizedPath.replace("file:///", "");
    }

    if (normalizedPath.startsWith("/") ||
        normalizedPath.contains("//") ||
        normalizedPath.indexOf('/') == 0)
    {
        return QString();
    }

    return normalizedPath;
}

void FileIO::read(bool async)
{
    if(m_fileName.isEmpty())
    {
        qDebug() << tr("[FileIO][readFile]: Trying to read the file but no file path is specified!");
        emit readingFailed(tr("Trying to read the file but no file path is specified!"));
        return;
    }
    
    auto readTask {[this]()
                  {
                      QFile file{m_fileName};

                      if(!file.open(QIODevice::ReadOnly))
                      {
                          qDebug() << tr("[FileIO][readFile]: Could not open the following file for reading:\n%1").arg(m_fileName);
                          emit readingFailed(tr("Could not open the following file for reading:\n%1").arg(m_fileName));
                          return;
                      }

                      bool success {true};

                      {
                          QTextStream stream{&file};
                          m_fileContent = stream.readAll();

                          if(stream.status() != QTextStream::Ok)
                          {
                              qDebug() << tr("[FileIO][readFile]: Something went wrong, while trying to read from the following file:\n%1").arg(m_fileName);
                              emit readingFailed(tr("Something went wrong, while trying to read from the following file:\n%1").arg(m_fileName));
                              success = false;
                          }
                      }

                      if(success)
                          emit fileContentChanged(m_fileContent);
                  }};

    if(async)
        std::thread{readTask}.detach();

    else
        readTask();
}

void FileIO::write(bool async)
{
    if(m_fileName.isEmpty())
    {
        qDebug() << tr("[FileIO][readFile]: Trying to write to a file, but no file path is specified!");
        emit writeOpResult(false, tr("Trying to write to a file, but no file path is specified!"));
        return;
    }
    
    auto writeTask {[this]()
        {
            QFile file{m_fileName};

            if(!file.open(QIODevice::WriteOnly))
            {
                qDebug() << tr("[FileIO][readFile]: Could not open the following file for writing:\n%1").arg(m_fileName);
                emit writeOpResult(false, tr("Could not open the following file for writing:\n%1").arg(m_fileName));
                return;
            }

            {
                QTextStream stream{&file};
                stream << m_fileContent;

                if(stream.status() != QTextStream::Ok)
                {
                    qDebug() << tr("[FileIO][readFile]: Something went wrong, while trying to write into the following file:\n%1").arg(m_fileName);
                    emit writeOpResult(false, tr("Something went wrong, while trying to write into the following file:\n%1").arg(m_fileName));
                    return;
                }
            }

            emit writeOpResult(true);
        }
    };

    if(async)
        std::thread{writeTask}.detach();

    else
        writeTask();
}

bool FileIO::createDir(QString path)
{
    path = pathNormalizer(path);
    QDir dir;
    if (!dir.exists(path)) {
        if (dir.mkpath(path)) {
            qDebug() << "[FileIO][CreateDir]: Dirctory Created:" << path;
            return true;
        } else {
            qDebug() << "[FileIO][CreateDir]: Failed to create dirctory!: " << path;
            return false;
        }
    } else {
        return false;
    }
}

bool FileIO::isFileExist(const QString &path)
{
    return QFile::exists(path);
}
