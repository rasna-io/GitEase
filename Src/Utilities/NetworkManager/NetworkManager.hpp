#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QHash>
#include <QPointer>
#include <QTimer>
#include <QVariantMap>

class NetworkManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit NetworkManager(QObject *parent = nullptr);

    enum HttpMethod {
        GET,
        POST
    };

    Q_ENUM(HttpMethod)

    Q_INVOKABLE void sendRequest(
        const QString &requestKey,
        const QString &url,
        HttpMethod method,
        const QJsonObject &body = QJsonObject(),
        const QVariantMap &headers = QVariantMap()
    );
    Q_INVOKABLE void downloadRequest(
        const QString &requestKey,
        const QString &url,
        const QVariantMap &headers = QVariantMap()
    );

    /**
     * @brief Stream a download straight to disk instead of buffering it in memory.
     *
     * On success emits requestFinished with { data: { file_path, size_bytes } }.
     * The parent directory of @p filePath must already exist.
     */
    Q_INVOKABLE void downloadToFile(
        const QString &requestKey,
        const QString &url,
        const QString &filePath,
        const QVariantMap &headers = QVariantMap()
    );

    /**
     * @brief Abort an in-flight request without emitting requestError or timeout.
     */
    Q_INVOKABLE void cancelRequest(const QString &requestKey);

signals:
    void requestFinished(QString requestKey, QJsonObject response);
    void requestError(QString requestKey, int code, QString message);
    void timeout(QString requestKey);
    void downloadProgress(QString requestKey, qint64 bytesReceived, qint64 bytesTotal);

private:
    void setHeaders(QNetworkRequest &request, const QVariantMap &headers);
    QTimer *trackReply(const QString &requestKey, QNetworkReply *reply, int timeoutMs,
                       bool isDownload);
    void releaseReply(const QString &requestKey, QNetworkReply *reply);

private:
    QNetworkAccessManager m_manager;
    QHash<QString, QPointer<QNetworkReply>> m_activeReplies;
};
