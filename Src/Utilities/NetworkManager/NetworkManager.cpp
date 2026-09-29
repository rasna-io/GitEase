#include "NetworkManager.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkProxy>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QStringConverter>
#include <QTimer>

#define REQUEST_TIMEOUT 5000
// Downloads can legitimately take minutes; only give up when no bytes arrive for this long.
#define DOWNLOAD_STALL_TIMEOUT 30000

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
{
}

void NetworkManager::sendRequest(
    const QString &requestKey,
    const QString &url,
    HttpMethod method,
    const QJsonObject &body,
    const QVariantMap &headers)
{
    QNetworkRequest request((QUrl(url)));

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    setHeaders(request, headers);

    QNetworkReply *reply = nullptr;

    if(method == GET) {
        reply = m_manager.get(request);
    } else if(method == POST) {
        QJsonDocument doc(body);
        reply = m_manager.post(request, doc.toJson());
    }

    QTimer *timer = trackReply(requestKey, reply, REQUEST_TIMEOUT, false);

    connect(reply, &QNetworkReply::finished, this, [=]() {
        timer->stop();

        if(reply->error() != QNetworkReply::NoError)
        {
            emit requestError(requestKey, reply->error(), reply->errorString());
            releaseReply(requestKey, reply);
            return;
        }

        QByteArray data = reply->readAll();

        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

        if(parseError.error != QJsonParseError::NoError)
        {
            emit requestError(requestKey, -1, parseError.errorString());
        }
        else
        {
            QJsonObject wrapper;
            if(doc.isObject())
            {
                wrapper["data"] = doc.object();
            }
            else if(doc.isArray())
            {
                wrapper["data"] = doc.array();
            }
            emit requestFinished(requestKey, wrapper);
        }

        releaseReply(requestKey, reply);
    });
}

void NetworkManager::downloadRequest(
    const QString &requestKey,
    const QString &url,
    const QVariantMap &headers)
{
    QNetworkRequest request((QUrl(url)));
    setHeaders(request, headers);

    QNetworkReply *reply = m_manager.get(request);

    QTimer *timer = trackReply(requestKey, reply, DOWNLOAD_STALL_TIMEOUT, true);

    connect(reply, &QNetworkReply::finished, this, [=]() {
        timer->stop();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestError(requestKey, reply->error(), reply->errorString());
            releaseReply(requestKey, reply);
            return;
        }

        QByteArray dataBytes = reply->readAll();

        QJsonObject wrapper;
        QJsonObject data;
        data["file_data_base64"] = QString::fromLatin1(dataBytes.toBase64());
        wrapper["data"] = data;
        emit requestFinished(requestKey, wrapper);

        releaseReply(requestKey, reply);
    });
}

void NetworkManager::downloadToFile(
    const QString &requestKey,
    const QString &url,
    const QString &filePath,
    const QVariantMap &headers)
{
    QNetworkRequest request((QUrl(url)));
    setHeaders(request, headers);

    QNetworkReply *reply = m_manager.get(request);

    // Parented to the reply so an aborted transfer discards the partial file automatically.
    QSaveFile *file = new QSaveFile(filePath, reply);
    if (!file->open(QIODevice::WriteOnly)) {
        reply->disconnect(this);
        reply->abort();
        reply->deleteLater();
        emit requestError(requestKey, -1, tr("Could not open download file for writing."));
        return;
    }

    QTimer *timer = trackReply(requestKey, reply, DOWNLOAD_STALL_TIMEOUT, true);

    connect(reply, &QNetworkReply::readyRead, this, [=]() {
        if (file->write(reply->readAll()) < 0) {
            timer->stop();
            reply->disconnect(this);
            reply->abort();
            emit requestError(requestKey, -1, tr("Could not write downloaded data to disk."));
            releaseReply(requestKey, reply);
        }
    });

    connect(reply, &QNetworkReply::finished, this, [=]() {
        timer->stop();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestError(requestKey, reply->error(), reply->errorString());
            releaseReply(requestKey, reply);
            return;
        }

        file->write(reply->readAll());
        const qint64 sizeBytes = file->size();

        if (!file->commit()) {
            emit requestError(requestKey, -1, tr("Could not save downloaded file."));
            releaseReply(requestKey, reply);
            return;
        }

        QJsonObject data;
        data["file_path"] = filePath;
        data["size_bytes"] = static_cast<double>(sizeBytes);

        QJsonObject wrapper;
        wrapper["data"] = data;
        emit requestFinished(requestKey, wrapper);

        releaseReply(requestKey, reply);
    });
}

void NetworkManager::cancelRequest(const QString &requestKey)
{
    QPointer<QNetworkReply> reply = m_activeReplies.take(requestKey);
    if (!reply)
        return;

    reply->disconnect(this);
    reply->abort();
    reply->deleteLater();
}

QTimer *NetworkManager::trackReply(const QString &requestKey, QNetworkReply *reply,
                                   int timeoutMs, bool isDownload)
{
    m_activeReplies.insert(requestKey, reply);

    QTimer *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->start(timeoutMs);

    connect(timer, &QTimer::timeout, this, [=]() {
        // Detach first: abort() emits finished synchronously, which would otherwise report a
        // second "Operation canceled" error for a request we already reported as timed out.
        reply->disconnect(this);
        reply->abort();
        emit timeout(requestKey);
        releaseReply(requestKey, reply);
    });

    if (isDownload) {
        connect(reply, &QNetworkReply::downloadProgress, this,
                [=](qint64 bytesReceived, qint64 bytesTotal) {
            timer->start(timeoutMs);
            emit downloadProgress(requestKey, bytesReceived, bytesTotal);
        });
    }

    return timer;
}

void NetworkManager::releaseReply(const QString &requestKey, QNetworkReply *reply)
{
    auto it = m_activeReplies.find(requestKey);
    if (it != m_activeReplies.end() && it.value() == reply)
        m_activeReplies.erase(it);

    reply->deleteLater();
}

void NetworkManager::setHeaders(QNetworkRequest &request, const QVariantMap &headers)
{
    for(auto it = headers.begin(); it != headers.end(); ++it)
    {
        request.setRawHeader(it.key().toUtf8(), it.value().toString().toUtf8());
    }
}
