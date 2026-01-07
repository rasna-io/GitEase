#pragma once

#include <QObject>
#include <QQmlEngine>

class Remote
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(QString name READ name CONSTANT FINAL)
    Q_PROPERTY(QString url READ url WRITE setUrl CONSTANT FINAL)
    Q_PROPERTY(QString fetchURL READ fetchURL CONSTANT FINAL)
    Q_PROPERTY(QString pushURL READ pushURL CONSTANT FINAL)
public:
    explicit Remote();
    Remote(const QString &name, const QString &url, const QString &fetchURL, const QString &pushURL);


    QString name() const;
    void setName(const QString &newName);

    QString url() const;
    void setUrl(const QString &newUrl);

    QString fetchURL() const;
    void setFetchURL(const QString &newFetchURL);

    QString pushURL() const;
    void setPushURL(const QString &newPushURL);


private:
    QString m_name;
    QString m_url;
    QString m_fetchURL;
    QString m_pushURL;
};

Q_DECLARE_METATYPE(Remote)

