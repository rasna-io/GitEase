#include "Remote.h"

Remote::Remote()
{}

QString Remote::name() const
{
    return m_name;
}

void Remote::setName(const QString &newName)
{
    if (m_name == newName)
        return;
    m_name = newName;
}

QString Remote::url() const
{
    return m_url;
}

void Remote::setUrl(const QString &newUrl)
{
    if (m_url == newUrl)
        return;
    m_url = newUrl;
}

QString Remote::fetchURL() const
{
    return m_fetchURL;
}

void Remote::setFetchURL(const QString &newFetchURL)
{
    if (m_fetchURL == newFetchURL)
        return;
    m_fetchURL = newFetchURL;
}

QString Remote::pushURL() const
{
    return m_pushURL;
}

void Remote::setPushURL(const QString &newPushURL)
{
    if (m_pushURL == newPushURL)
        return;
    m_pushURL = newPushURL;
}

Remote::Remote(const QString &name, const QString &url, const QString &fetchURL,
               const QString &pushURL) : m_name(name),
    m_url(url),
    m_fetchURL(fetchURL),
    m_pushURL(pushURL)
{}
