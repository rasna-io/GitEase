#include "GitProtocolDetector.h"
#include <QRegularExpression>

GitProtocolDetector::GitProtocol GitProtocolDetector::detectProtocol(const QString& url)
{
    if (url.isEmpty())
        return GitProtocol::Unknown;

    // SSH: git@github.com:owner/repo.git or ssh://...
    if (url.startsWith("git@") || url.startsWith("ssh://", Qt::CaseInsensitive)) {
        return GitProtocol::SSH;
    }

    // HTTPS
    if (url.startsWith("https://", Qt::CaseInsensitive)) {
        return GitProtocol::HTTPS;
    }

    // HTTP
    if (url.startsWith("http://", Qt::CaseInsensitive)) {
        return GitProtocol::HTTP;
    }

    return GitProtocol::Unknown;
}

bool GitProtocolDetector::isSshUrl(const QString& url)
{
    return detectProtocol(url) == GitProtocol::SSH;
}

bool GitProtocolDetector::isHttpsUrl(const QString& url)
{
    return detectProtocol(url) == GitProtocol::HTTPS;
}

bool GitProtocolDetector::isHttpUrl(const QString& url)
{
    return detectProtocol(url) == GitProtocol::HTTP;
}

QString GitProtocolDetector::extractRepositoryName(const QString& url)
{
    if (url.isEmpty())
        return QString();

    // Remove .git suffix if present
    QString cleanUrl = url;
    if (cleanUrl.endsWith(".git", Qt::CaseInsensitive)) {
        cleanUrl.chop(4);
    }

    // Extract the last path segment (handles both / and : separators)
    QStringList parts = cleanUrl.split(QRegularExpression("[/:]"), Qt::SkipEmptyParts);
    if (!parts.isEmpty()) {
        return parts.last();
    }

    return QString();
}
