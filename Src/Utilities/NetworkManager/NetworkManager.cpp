#include "NetworkManager.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkProxy>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QStringConverter>
#include <QTimer>

#define REQUEST_TIMEOUT 5000

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

    QTimer *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->start(REQUEST_TIMEOUT);

    connect(timer, &QTimer::timeout, this, [=]() {
        emit timeout(requestKey);

        reply->abort();
        timer->deleteLater();
        reply->deleteLater();
    });

    connect(reply, &QNetworkReply::finished, this, [=]() {
        timer->stop();

        if(reply->error() != QNetworkReply::NoError)
        {
            emit requestError(requestKey, reply->error(), reply->errorString());

            timer->deleteLater();
            reply->deleteLater();
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

        timer->deleteLater();
        reply->deleteLater();
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

    QTimer *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->start(REQUEST_TIMEOUT);

    connect(timer, &QTimer::timeout, this, [=]() {
        emit timeout(requestKey);

        reply->abort();
        timer->deleteLater();
        reply->deleteLater();
    });

    connect(reply, &QNetworkReply::downloadProgress, this, [=](qint64 bytesReceived, qint64 bytesTotal) {
        emit downloadProgress(requestKey, bytesReceived, bytesTotal);
    });

    connect(reply, &QNetworkReply::finished, this, [=]() {
        timer->stop();

        if (reply->error() != QNetworkReply::NoError) {
            emit requestError(requestKey, reply->error(), reply->errorString());
            timer->deleteLater();
            reply->deleteLater();
            return;
        }

        QByteArray dataBytes = reply->readAll();

        QJsonObject wrapper;
        QJsonObject data;
        data["file_data_base64"] = QString::fromLatin1(dataBytes.toBase64());
        wrapper["data"] = data;
        emit requestFinished(requestKey, wrapper);

        timer->deleteLater();
        reply->deleteLater();
    });
}

void NetworkManager::setHeaders(QNetworkRequest &request, const QVariantMap &headers)
{
    for(auto it = headers.begin(); it != headers.end(); ++it)
    {
        request.setRawHeader(it.key().toUtf8(), it.value().toString().toUtf8());
    }
}
