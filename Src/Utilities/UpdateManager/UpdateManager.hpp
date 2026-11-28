#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QByteArray>
#include <QVariantMap>

/**
 * @brief Manages staging and installation of GitEase application updates.
 *
 * Prepares a temporary location for an installer payload, saves the downloaded
 * bytes provided by the updater flow, and schedules the final replacement step
 * that runs after the application exits.
 */
class UpdateManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit UpdateManager(QObject *parent = nullptr);

    /**
     * @brief Read and clear the last completed update result marker.
     * @return QVariantMap containing the persisted update result payload.
     */
    Q_INVOKABLE QVariantMap takeCompletedUpdateInfo();

    /**
     * @brief Prepare a staging path for a downloaded update file.
     * @param fileUrl Original installer URL, used to derive a stable file name.
     * @return Absolute file path inside the update staging directory.
     */
    Q_INVOKABLE QString prepareUpdateFilePath(const QString &fileUrl);

    /**
     * @brief Save a downloaded update payload provided as base64 text.
     *
     * This is intended for QML callers, where binary payloads are easier to
     * move around as base64 strings.
     */
    Q_INVOKABLE bool saveDownloadedUpdateBase64(const QString &stagedFilePath,
                                                const QString &fileDataBase64);

    /**
     * @brief Save a downloaded update payload to the prepared staging file.
     */
    Q_INVOKABLE bool saveDownloadedUpdate(const QString &stagedFilePath,
                                          const QByteArray &fileData);

    /**
     * @brief Schedule installation of a staged update after GitEase exits.
     *
     * @param stagedFilePath Absolute path to the downloaded installer payload.
     * @param version Version string recorded in the completion marker.
     */
    Q_INVOKABLE bool installDownloadedUpdate(const QString &stagedFilePath,
                                             const QString &version);

signals:
    void updateInstallScheduled(QString version);
    void updateFailed(QString message);

private:
    QString updateDirectoryPath() const;
    QString markerFilePath() const;
    QString stagedUpdateFilePath(const QString &fileUrl) const;

    bool scheduleInstall(const QString &stagedFilePath, const QString &version);
    bool writeInstallerScript(const QString &scriptPath,
                              const QString &stagedFilePath,
                              const QString &targetFilePath,
                              const QString &markerFilePath,
                              const QString &version) const;

    void fail(const QString &message);
};
