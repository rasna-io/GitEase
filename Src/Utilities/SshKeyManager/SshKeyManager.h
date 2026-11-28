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
 *
 * Key generation and fingerprinting run in-process (statically linked
 * OpenSSL + Qt), so no OpenSSH / ssh-keygen installation is required.
 * Generated keys are Ed25519 in OpenSSH format, accepted by GitHub and GitLab.
 */
class SshKeyManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList allKeys      READ allKeys        NOTIFY keysChanged        FINAL)
    Q_PROPERTY(bool         isGenerating READ isGenerating   NOTIFY isGeneratingChanged FINAL)
    Q_PROPERTY(QString      activeKeyName READ activeKeyName NOTIFY activeKeyChanged     FINAL)

public:
    explicit SshKeyManager(QObject *parent = nullptr);

    /**
     * @brief Get list of all available SSH keys in ~/.ssh
     * @return QVariantList of maps containing {name, fingerprint, publicKey, privatePath, publicPath}
     */
    QVariantList allKeys() const;

    bool isGenerating() const;

    /**
     * @brief Name of the key GitEase uses for SSH operations ("" if none).
     *
     * This is the key chosen with setActiveKey(), or, if none was chosen (or
     * its files are gone), the first of id_ed25519, id_rsa, id_ecdsa, then any
     * other key in ~/.ssh that has a private file.
     */
    QString activeKeyName() const;

    /** Resolve the active key name without needing an instance. */
    static QString resolveActiveKeyName();

    /** Absolute path of the active key's private file, or "" if there is none. */
    static QString activePrivateKeyPath();

    /** Choose which key GitEase uses for SSH operations (persisted). */
    Q_INVOKABLE GitResult setActiveKey(const QString &keyName);

    /**
     * @brief Assign a key to a Git host provider ("github" or "gitlab").
     *
     * Remotes on that provider then use this key instead of the default one.
     * An empty @p keyName removes the assignment.
     */
    Q_INVOKABLE GitResult setProviderKey(const QString &provider, const QString &keyName);

    /** Key assigned to @p provider ("github"/"gitlab"), or "" if none (or its files are gone). */
    static QString assignedKeyName(const QString &provider);

    /** "github", "gitlab" or "" for a remote URL (https, ssh:// or scp-style). */
    static QString providerForUrl(const QString &url);

    /**
     * @brief Private key file to use for @p remoteUrl.
     *
     * The key assigned to the URL's provider if there is one, otherwise the
     * default key (see activePrivateKeyPath()). Empty if no key exists.
     */
    static QString privateKeyPathForUrl(const QString &remoteUrl);

    /**
     * @brief Generate a new Ed25519 SSH key (via OpenSSL, no ssh-keygen).
     *
     * Uses @p keyName if given (see keyNameError()), otherwise an auto-generated unique name.
     *
     * Generates a key without passphrase protection.
     * If @p keyComment is empty, a default comment is used.
     * Emits keysChanged signal when complete.
     */
    Q_INVOKABLE GitResult generateKey(const QString &keyComment = QString(),
                                      const QString &keyName = QString());

    /** Next free auto-generated name (e.g. "gitease_key_3"), offered as a suggestion in the UI. */
    Q_INVOKABLE QString suggestedKeyName() const;

    /**
     * @brief Check a prospective key name.
     * @return "" if @p keyName is usable, otherwise a user-facing reason
     *         (empty, bad characters, or already taken).
     */
    Q_INVOKABLE QString keyNameError(const QString &keyName) const;

    /**
     * @brief Delete an SSH key by name (both private and public files).
     *
     * @param keyName Name of the key (e.g., "id_ed25519", "gitease_ed25519")
     */
    Q_INVOKABLE GitResult deleteKeyByName(const QString &keyName);

    /**
     * @brief Rename a key (both private and public files).
     *
     * @p newName may contain letters, digits, '.', '_' and '-' only, and must
     * not collide with an existing file in ~/.ssh.
     */
    Q_INVOKABLE GitResult renameKey(const QString &oldName, const QString &newName);

    /**
     * @brief Import an existing private key into ~/.ssh under @p keyName.
     *
     * @param sourcePath Path or file:// URL of the private key file.
     * @param keyName    Name for the imported key (see keyNameError()).
     *
     * The public key is taken from "<source>.pub" if present, otherwise derived
     * from the file (possible for the modern "OPENSSH PRIVATE KEY" format, even
     * when passphrase-protected). Legacy PEM keys need their .pub next to them.
     *
     * On success, data() is a map {name, encrypted}; passphrase-protected keys
     * can only be used through an ssh-agent.
     */
    Q_INVOKABLE GitResult importKey(const QString &sourcePath, const QString &keyName);

    /** Suggested, valid and unused key name for importing @p sourcePath (based on its file name). */
    Q_INVOKABLE QString suggestedImportName(const QString &sourcePath) const;

    /**
     * @brief Export a key into the folder @p destDir (path or file:// URL).
     *
     * Always writes "<name>.pub"; also writes "<name>" (the private key) when
     * @p includePrivate is true. Never overwrites existing files.
     * On success, data() is the destination folder path.
     */
    Q_INVOKABLE GitResult exportKey(const QString &keyName, const QString &destDir, bool includePrivate);

    /** Re-read key files from disk and emit keysChanged. */
    Q_INVOKABLE void refresh();

signals:
    void keysChanged();
    void isGeneratingChanged();
    void activeKeyChanged();

private:
    struct SshKeyInfo {
        QString name;           // e.g., "id_ed25519"
        QString fingerprint;    
        QString publicKeyPath;  
        QString privateKeyPath;
        QString publicKeyContent;
    };

    static QString sshDirPath();
    QString sshDir()                 const;
    QString generateUniqueKeyName()  const;
    QString computeFingerprint(const QString &publicKeyContent) const;

    void scanAllKeys();
    SshKeyInfo loadSingleKeyInfo(const QString &keyName) const;

    // All available keys
    QVector<SshKeyInfo> m_allKeys;
    bool m_isGenerating = false;
};
