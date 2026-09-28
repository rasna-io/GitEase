#include "UpdateManager.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>

namespace {
    QString safeFileNameFromUrl(const QString &fileUrl)
    {
        const QUrl url(fileUrl);
        QString fileName = QFileInfo(url.path()).fileName();

        if (fileName.isEmpty())
            fileName = QStringLiteral("GitEase-update");

        #ifdef Q_OS_WIN
            if (!fileName.endsWith(QStringLiteral(".exe"), Qt::CaseInsensitive))
                fileName += QStringLiteral(".exe");
        #endif

        return fileName;
    }

    QString powershellLiteral(const QString &value)
    {
        QString escaped = QDir::toNativeSeparators(value);
        escaped.replace(QStringLiteral("'"), QStringLiteral("''"));
        return QStringLiteral("'") + escaped + QStringLiteral("'");
    }
} // namespace

UpdateManager::UpdateManager(QObject *parent)
    : QObject(parent)
{
}

QVariantMap UpdateManager::takeCompletedUpdateInfo()
{
    const QString path = markerFilePath();
    if (!QFile::exists(path))
        return {};

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    file.close();
    QFile::remove(path);

    if (!document.isObject())
        return {};

    return document.object().toVariantMap();
}

QString UpdateManager::prepareUpdateFilePath(const QString &fileUrl)
{
    QDir updateDir(updateDirectoryPath());
    if (!updateDir.exists() && !updateDir.mkpath(QStringLiteral("."))) {
        fail(tr("Could not create update directory."));
        return {};
    }

    const QString stagedFilePath = stagedUpdateFilePath(fileUrl);
    QFile::remove(stagedFilePath);
    return stagedFilePath;
}

bool UpdateManager::saveDownloadedUpdateBase64(const QString &stagedFilePath,
                                               const QString &fileDataBase64)
{
    return saveDownloadedUpdate(stagedFilePath, QByteArray::fromBase64(fileDataBase64.toLatin1()));
}

bool UpdateManager::saveDownloadedUpdate(const QString &stagedFilePath,
                                         const QByteArray &fileData)
{
    if (stagedFilePath.isEmpty()) {
        fail(tr("Downloaded update file path is not available."));
        return false;
    }

    QSaveFile file(stagedFilePath);
    if (!file.open(QIODevice::WriteOnly)) {
        fail(tr("Could not save update file."));
        return false;
    }

    file.write(fileData);

    if (!file.commit()) {
        fail(tr("Could not finalize update file."));
        return false;
    }

    return true;
}

bool UpdateManager::installDownloadedUpdate(const QString &stagedFilePath,
                                            const QString &version)
{
    if (stagedFilePath.isEmpty()) {
        fail(tr("Downloaded update file path is not available."));
        return false;
    }

    if (!QFile::exists(stagedFilePath)) {
        fail(tr("Downloaded update file does not exist."));
        return false;
    }

    return scheduleInstall(stagedFilePath, version);
}

QString UpdateManager::updateDirectoryPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/updates");
}

QString UpdateManager::markerFilePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/update-completed.json");
}

QString UpdateManager::stagedUpdateFilePath(const QString &fileUrl) const
{
    return updateDirectoryPath() + QStringLiteral("/") + safeFileNameFromUrl(fileUrl);
}

bool UpdateManager::scheduleInstall(const QString &stagedFilePath, const QString &version)
{
    const QString targetFilePath = QCoreApplication::applicationFilePath();
    const QString scriptPath = updateDirectoryPath() + QStringLiteral("/apply-update.ps1");

    // The helper script waits for GitEase to exit, swaps the binary, records the result, and relaunches it.
    if (!writeInstallerScript(scriptPath, stagedFilePath, targetFilePath, markerFilePath(), version))
        return false;

    const QStringList args {
        QStringLiteral("-NoProfile"),
        QStringLiteral("-ExecutionPolicy"),
        QStringLiteral("Bypass"),
        QStringLiteral("-File"),
        QDir::toNativeSeparators(scriptPath)
    };

    if (!QProcess::startDetached(QStringLiteral("powershell.exe"), args)) {
        fail(tr("Could not start updater process."));
        return false;
    }

    emit updateInstallScheduled(version);
    return true;
}

bool UpdateManager::writeInstallerScript(const QString &scriptPath,
                                         const QString &stagedFilePath,
                                         const QString &targetFilePath,
                                         const QString &markerFilePath,
                                         const QString &version) const
{
    QSaveFile file(scriptPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        const_cast<UpdateManager *>(this)->fail(tr("Could not create updater script."));
        return false;
    }

    QTextStream stream(&file);
    stream << "$ErrorActionPreference = 'Stop'\n";
    stream << "$source = " << powershellLiteral(stagedFilePath) << "\n";
    stream << "$target = " << powershellLiteral(targetFilePath) << "\n";
    stream << "$marker = " << powershellLiteral(markerFilePath) << "\n";
    stream << "$version = " << powershellLiteral(version) << "\n";
    stream << "$deadline = (Get-Date).AddSeconds(30)\n";
    stream << "while ((Get-Date) -lt $deadline) {\n";
    stream << "  try {\n";
    stream << "    Copy-Item -LiteralPath $source -Destination $target -Force\n";
    stream << "    $payload = @{ success = $true; version = $version; updated_at = (Get-Date).ToString('o') } | ConvertTo-Json -Compress\n";
    stream << "    Set-Content -LiteralPath $marker -Value $payload -Encoding UTF8\n";
    stream << "    Start-Process -FilePath $target\n";
    stream << "    exit 0\n";
    stream << "  } catch {\n";
    stream << "    Start-Sleep -Milliseconds 500\n";
    stream << "  }\n";
    stream << "}\n";
    stream << "$payload = @{ success = $false; version = $version; error = 'Could not replace application file.'; updated_at = (Get-Date).ToString('o') } | ConvertTo-Json -Compress\n";
    stream << "Set-Content -LiteralPath $marker -Value $payload -Encoding UTF8\n";

    if (stream.status() != QTextStream::Ok || !file.commit()) {
        const_cast<UpdateManager *>(this)->fail(tr("Could not write updater script."));
        return false;
    }

    return true;
}

void UpdateManager::fail(const QString &message)
{
    qWarning() << "[UpdateManager]" << message;
    emit updateFailed(message);
}
