#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

#include "GitResult.h"

/**
 * @brief Manages SSH key pairs for GitEase.
 *
 * Scans the user's ~/.ssh directory for all available keys and provides
 * a unified interface to list, generate, and delete SSH key pairs.
 * All keys are treated equally - there is no distinction between
 * "managed" and "existing" keys.
 */
class SshKeyManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList allKeys      READ allKeys        NOTIFY keysChanged        FINAL)
    Q_PROPERTY(bool         isGenerating READ isGenerating   NOTIFY isGeneratingChanged FINAL)

public:
    explicit SshKeyManager(QObject *parent = nullptr);

    /**
     * @brief Get list of all available SSH keys in ~/.ssh
     * @return QVariantList of maps containing {name, fingerprint, publicKey, privatePath, publicPath}
     */
    QVariantList allKeys() const;

    bool isGenerating() const;

    /**
     * @brief Generate a new ED25519 SSH key with an auto-generated unique name.
     *
     * Generates a key without passphrase protection.
     * If @p keyComment is empty, a default comment is used.
     * Emits keysChanged signal when complete.
     */
    Q_INVOKABLE GitResult generateKey(const QString &keyComment = QString());

    /**
     * @brief Delete an SSH key by name (both private and public files).
     *
     * @param keyName Name of the key (e.g., "id_ed25519", "gitease_ed25519")
     */
    Q_INVOKABLE GitResult deleteKeyByName(const QString &keyName);

    /** Re-read key files from disk and emit keysChanged. */
    Q_INVOKABLE void refresh();

signals:
    void keysChanged();
    void isGeneratingChanged();

private:
    struct SshKeyInfo {
        QString name;           // e.g., "id_ed25519"
        QString fingerprint;    
        QString publicKeyPath;  
        QString privateKeyPath;
        QString publicKeyContent;
    };

    QString sshDir()                 const;
    QString generateUniqueKeyName()  const;
    bool    isSshKeygenAvailable()   const;
    QString runSshKeygenFingerprint(const QString &pubPath) const;

    void scanAllKeys();
    SshKeyInfo loadSingleKeyInfo(const QString &keyName) const;

    // All available keys
    QVector<SshKeyInfo> m_allKeys;
    bool m_isGenerating = false;
};
