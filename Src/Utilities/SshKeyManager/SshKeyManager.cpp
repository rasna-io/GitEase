#include "SshKeyManager.h"

#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QCryptographicHash>
#include <QRegularExpression>
#include <QSettings>
#include <QUrl>
#include <QFileInfo>

#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/crypto.h>

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

static constexpr const char* DEFAULT_KEY_COMMENT = "gitease-key";

// ---------------------------------------------------------------------------
// OpenSSH key-format helpers (no external ssh-keygen needed)
// ---------------------------------------------------------------------------

namespace {

void appendU32(QByteArray &out, quint32 v)
{
    out.append(char((v >> 24) & 0xff));
    out.append(char((v >> 16) & 0xff));
    out.append(char((v >> 8) & 0xff));
    out.append(char(v & 0xff));
}

void appendString(QByteArray &out, const QByteArray &s)
{
    appendU32(out, quint32(s.size()));
    out.append(s);
}

quint32 readU32(const QByteArray &d, qsizetype &off)
{
    if (off + 4 > d.size()) {
        off = d.size() + 1;
        return 0;
    }
    const auto *p = reinterpret_cast<const uchar *>(d.constData()) + off;
    off += 4;
    return (quint32(p[0]) << 24) | (quint32(p[1]) << 16) | (quint32(p[2]) << 8) | p[3];
}

QByteArray readString(const QByteArray &d, qsizetype &off)
{
    const quint32 len = readU32(d, off);
    if (off > d.size() || qsizetype(len) > d.size() - off) {
        off = d.size() + 1;
        return {};
    }
    const QByteArray s = d.mid(off, len);
    off += len;
    return s;
}

/// Local filesystem path from a plain path or a file:// URL.
QString toLocalPath(const QString &pathOrUrl)
{
    const QUrl url(pathOrUrl);
    return url.isLocalFile() ? url.toLocalFile() : pathOrUrl;
}

struct ParsedPrivateKey {
    bool    valid = false;
    bool    encrypted = false;
    QString publicLine;     // "type base64" derived from the file; empty if not derivable
};

/// Inspect a private key file's text. Handles the openssh-key-v1 format fully
/// (public blob is stored in the clear); legacy PEM is only checked for encryption.
ParsedPrivateKey inspectPrivateKey(const QByteArray &text)
{
    ParsedPrivateKey r;
    if (!text.contains("PRIVATE KEY-----"))
        return r;
    r.valid = true;

    if (text.contains("BEGIN OPENSSH PRIVATE KEY")) {
        QByteArray b64;
        for (const QByteArray &line : text.split('\n')) {
            const QByteArray l = line.trimmed();
            if (!l.isEmpty() && !l.startsWith("-----"))
                b64 += l;
        }
        const QByteArray body = QByteArray::fromBase64(b64);
        const QByteArray magic("openssh-key-v1", 14);
        if (!body.startsWith(magic) || body.size() <= 15)
            return ParsedPrivateKey{};

        qsizetype off = 15;   // magic + NUL
        const QByteArray cipher = readString(body, off);
        readString(body, off);                 // kdf
        readString(body, off);                 // kdf options
        const quint32 count = readU32(body, off);
        const QByteArray pubBlob = readString(body, off);
        if (off > body.size() || count < 1 || pubBlob.isEmpty())
            return ParsedPrivateKey{};

        qsizetype p = 0;
        const QByteArray type = readString(pubBlob, p);
        if (type.isEmpty() || p > pubBlob.size())
            return ParsedPrivateKey{};

        r.encrypted = cipher != "none";
        r.publicLine = QString::fromLatin1(type) + ' ' + QString::fromLatin1(pubBlob.toBase64());
    } else {
        r.encrypted = text.contains("ENCRYPTED");
    }
    return r;
}

/// "ssh-ed25519" wire blob: string type, string raw public key.
QByteArray ed25519PublicBlob(const QByteArray &rawPub)
{
    QByteArray blob;
    appendString(blob, "ssh-ed25519");
    appendString(blob, rawPub);
    return blob;
}

/// Serialise an unencrypted openssh-key-v1 private key (PEM-armoured).
QByteArray encodeOpenSshPrivateKey(const QByteArray &rawPriv,
                                   const QByteArray &rawPub,
                                   const QByteArray &comment)
{
    quint32 check = 0;
    RAND_bytes(reinterpret_cast<unsigned char *>(&check), sizeof(check));

    QByteArray priv;
    appendU32(priv, check);
    appendU32(priv, check);
    appendString(priv, "ssh-ed25519");
    appendString(priv, rawPub);
    appendString(priv, rawPriv + rawPub);   // OpenSSH stores seed||pub (64 bytes)
    appendString(priv, comment);
    for (char pad = 1; priv.size() % 8 != 0; ++pad)
        priv.append(pad);

    QByteArray body("openssh-key-v1", 14);
    body.append('\0');
    appendString(body, "none");             // cipher
    appendString(body, "none");             // kdf
    appendString(body, QByteArray());       // kdf options
    appendU32(body, 1);                     // number of keys
    appendString(body, ed25519PublicBlob(rawPub));
    appendString(body, priv);

    OPENSSL_cleanse(priv.data(), size_t(priv.size()));

    const QByteArray b64 = body.toBase64();
    QByteArray pem = "-----BEGIN OPENSSH PRIVATE KEY-----\n";
    for (qsizetype i = 0; i < b64.size(); i += 70)
        pem.append(b64.mid(i, 70)).append('\n');
    pem.append("-----END OPENSSH PRIVATE KEY-----\n");
    return pem;
}

/// Generate an Ed25519 pair with the statically linked OpenSSL.
bool generateEd25519(QByteArray &rawPriv, QByteArray &rawPub)
{
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_ED25519, nullptr);
    if (!ctx)
        return false;

    EVP_PKEY *pkey = nullptr;
    bool ok = EVP_PKEY_keygen_init(ctx) == 1 && EVP_PKEY_keygen(ctx, &pkey) == 1;
    EVP_PKEY_CTX_free(ctx);
    if (!ok || !pkey)
        return false;

    size_t privLen = 32, pubLen = 32;
    rawPriv.resize(int(privLen));
    rawPub.resize(int(pubLen));
    ok = EVP_PKEY_get_raw_private_key(pkey, reinterpret_cast<unsigned char *>(rawPriv.data()), &privLen) == 1
      && EVP_PKEY_get_raw_public_key(pkey,  reinterpret_cast<unsigned char *>(rawPub.data()),  &pubLen)  == 1
      && privLen == 32 && pubLen == 32;
    EVP_PKEY_free(pkey);
    return ok;
}

} // namespace

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

SshKeyManager::SshKeyManager(QObject *parent)
    : QObject(parent)
{
    scanAllKeys();
}

// ---------------------------------------------------------------------------
// Path helpers
// ---------------------------------------------------------------------------

QString SshKeyManager::sshDirPath()
{
    return QDir::homePath() + "/.ssh";
}

QString SshKeyManager::sshDir() const
{
    return sshDirPath();
}

// ---------------------------------------------------------------------------
// Active key selection
// ---------------------------------------------------------------------------

namespace {
constexpr const char *SETTINGS_ORG = "GitEase";
constexpr const char *SETTINGS_APP = "SshSettings";
constexpr const char *ACTIVE_KEY   = "activeKey";

const QStringList &providers()
{
    static const QStringList list{QStringLiteral("github"), QStringLiteral("gitlab")};
    return list;
}

QString providerSettingsKey(const QString &provider)
{
    return QStringLiteral("providerKey/") + provider;
}

/// Re-point or clear every provider assignment that references @p oldName.
void remapProviderAssignments(const QString &oldName, const QString &newName)
{
    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    for (const QString &p : providers()) {
        if (settings.value(providerSettingsKey(p)).toString() != oldName)
            continue;
        if (newName.isEmpty())
            settings.remove(providerSettingsKey(p));
        else
            settings.setValue(providerSettingsKey(p), newName);
    }
}
}

QString SshKeyManager::assignedKeyName(const QString &provider)
{
    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    const QString name = settings.value(providerSettingsKey(provider)).toString();
    return (!name.isEmpty() && QFile::exists(sshDirPath() + "/" + name)) ? name : QString();
}

QString SshKeyManager::providerForUrl(const QString &url)
{
    QString host;
    if (url.contains("://")) {
        host = QUrl(url).host();
    } else {
        // scp-style: [user@]host:path
        host = url.section(':', 0, 0);
        host = host.section('@', -1);
    }
    host = host.trimmed().toLower();

    if (host == "github.com" || host.endsWith(".github.com") || host.startsWith("github."))
        return QStringLiteral("github");
    if (host.contains("gitlab"))
        return QStringLiteral("gitlab");
    return {};
}

QString SshKeyManager::privateKeyPathForUrl(const QString &remoteUrl)
{
    const QString provider = providerForUrl(remoteUrl);
    if (!provider.isEmpty()) {
        const QString assigned = assignedKeyName(provider);
        if (!assigned.isEmpty())
            return sshDirPath() + "/" + assigned;
    }
    return activePrivateKeyPath();
}

GitResult SshKeyManager::setProviderKey(const QString &provider, const QString &keyName)
{
    if (!providers().contains(provider))
        return GitResult(false, QVariant(), "Unknown provider.");

    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    if (keyName.isEmpty()) {
        settings.remove(providerSettingsKey(provider));
    } else {
        if (!QFile::exists(sshDir() + "/" + keyName))
            return GitResult(false, QVariant(), "Key not found.");
        settings.setValue(providerSettingsKey(provider), keyName);
    }
    settings.sync();

    emit keysChanged();
    return GitResult(true);
}

QString SshKeyManager::resolveActiveKeyName()
{
    const QString dir = sshDirPath();
    auto hasPrivate = [&dir](const QString &name) {
        return !name.isEmpty() && QFile::exists(dir + "/" + name);
    };

    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    const QString stored = settings.value(ACTIVE_KEY).toString();
    if (hasPrivate(stored))
        return stored;

    for (const QString &name : {QStringLiteral("id_ed25519"), QStringLiteral("id_rsa"),
                                QStringLiteral("id_ecdsa")}) {
        if (hasPrivate(name))
            return name;
    }

    const QStringList pubs = QDir(dir).entryList({"*.pub"}, QDir::Files, QDir::Name);
    for (const QString &pub : pubs) {
        const QString name = pub.left(pub.length() - 4);
        if (hasPrivate(name))
            return name;
    }
    return {};
}

QString SshKeyManager::activePrivateKeyPath()
{
    const QString name = resolveActiveKeyName();
    return name.isEmpty() ? QString() : sshDirPath() + "/" + name;
}

QString SshKeyManager::activeKeyName() const
{
    return resolveActiveKeyName();
}

GitResult SshKeyManager::setActiveKey(const QString &keyName)
{
    if (keyName.isEmpty() || !QFile::exists(sshDir() + "/" + keyName))
        return GitResult(false, QVariant(), "Key not found.");

    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    settings.setValue(ACTIVE_KEY, keyName);
    settings.sync();

    emit activeKeyChanged();
    emit keysChanged();
    return GitResult(true);
}

QString SshKeyManager::generateUniqueKeyName() const
{
    // Generate unique name like "gitease_key_1", "gitease_key_2", etc.
    int counter = 1;
    while (true) {
        QString name = QString("gitease_key_%1").arg(counter);
        bool exists = false;
        for (const auto& key : m_allKeys) {
            if (key.name == name) {
                exists = true;
                break;
            }
        }
        if (!exists)
            return name;
        counter++;
    }
}

// ---------------------------------------------------------------------------
// State accessors
// ---------------------------------------------------------------------------

QVariantList SshKeyManager::allKeys() const
{
    QVariantList result;
    const QString active = resolveActiveKeyName();
    for (const auto& key : m_allKeys) {
        QVariantMap map;
        map["name"] = key.name;
        map["fingerprint"] = key.fingerprint;
        map["publicKeyPath"] = key.publicKeyPath;
        map["privateKeyPath"] = key.privateKeyPath;
        map["publicKeyContent"] = key.publicKeyContent;
        map["isActive"] = (key.name == active);

        QStringList assigned;
        for (const QString &p : providers()) {
            if (assignedKeyName(p) == key.name)
                assigned << p;
        }
        map["providers"] = assigned;
        result.append(map);
    }
    return result;
}

bool SshKeyManager::isGenerating() const
{
    return m_isGenerating;
}

// ---------------------------------------------------------------------------
// Internal: scan ~/.ssh for all available keys
// ---------------------------------------------------------------------------

void SshKeyManager::scanAllKeys()
{
    m_allKeys.clear();

    QDir sshDirectory(sshDir());
    if (!sshDirectory.exists())
        return;

    // Find all .pub files to identify keys
    const QStringList pubFiles = sshDirectory.entryList(QStringList() << "*.pub", QDir::Files);

    for (const QString& pubFile : pubFiles) {
        // Extract key name from "keyname.pub"
        QString keyName = pubFile;
        if (keyName.endsWith(".pub"))
            keyName = keyName.left(keyName.length() - 4);

        SshKeyInfo info = loadSingleKeyInfo(keyName);
        if (!info.publicKeyContent.isEmpty()) {
            m_allKeys.append(info);
        }
    }
}

SshKeyManager::SshKeyInfo SshKeyManager::loadSingleKeyInfo(const QString &keyName) const
{
    SshKeyInfo info;
    info.name = keyName;

    const QString pubPath = sshDir() + "/" + keyName + ".pub";
    const QString privPath = sshDir() + "/" + keyName;

    QFile pubFile(pubPath);
    if (!pubFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return info;

    info.publicKeyContent = QTextStream(&pubFile).readAll().trimmed();
    pubFile.close();

    if (info.publicKeyContent.isEmpty())
        return info;

    info.publicKeyPath = pubPath;
    info.privateKeyPath = privPath;
    info.fingerprint = computeFingerprint(info.publicKeyContent);

    return info;
}

// ---------------------------------------------------------------------------
// Internal: SHA256 fingerprint computed from the .pub contents
// (same format as `ssh-keygen -lf`, so it matches GitHub / GitLab UIs)
// ---------------------------------------------------------------------------

QString SshKeyManager::computeFingerprint(const QString &publicKeyContent) const
{
    const QList<QByteArray> parts = publicKeyContent.toUtf8().simplified().split(' ');
    if (parts.size() < 2)
        return {};

    const QByteArray blob = QByteArray::fromBase64(parts.at(1));
    if (blob.isEmpty())
        return {};

    const QByteArray digest = QCryptographicHash::hash(blob, QCryptographicHash::Sha256);
    return "SHA256:" + QString::fromLatin1(
        digest.toBase64(QByteArray::Base64Encoding | QByteArray::OmitTrailingEquals));
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

QString SshKeyManager::suggestedKeyName() const
{
    return generateUniqueKeyName();
}

QString SshKeyManager::keyNameError(const QString &keyName) const
{
    const QString name = keyName.trimmed();
    if (name.isEmpty())
        return "Enter a name for the key.";

    static const QRegularExpression valid("^[A-Za-z0-9][A-Za-z0-9._-]*$");
    if (!valid.match(name).hasMatch() || name.endsWith(".pub"))
        return "Use only letters, digits, '.', '_' and '-' (no spaces, no .pub suffix).";

    if (QFile::exists(sshDir() + "/" + name) || QFile::exists(sshDir() + "/" + name + ".pub"))
        return "A key with that name already exists.";

    return {};
}

GitResult SshKeyManager::generateKey(const QString &keyComment, const QString &requestedName)
{
    if (m_isGenerating)
        return GitResult(false, QVariant(), "Key generation already in progress.");

    const QString chosenName = requestedName.trimmed();
    if (!chosenName.isEmpty()) {
        const QString error = keyNameError(chosenName);
        if (!error.isEmpty())
            return GitResult(false, QVariant(), error);
    }

    // Ensure ~/.ssh exists
    QDir dir(sshDir());
    if (!dir.exists() && !dir.mkpath("."))
        return GitResult(false, QVariant(),
                         QString("Failed to create SSH directory: %1").arg(sshDir()));

    m_isGenerating = true;
    emit isGeneratingChanged();

    const QString keyName = chosenName.isEmpty() ? generateUniqueKeyName() : chosenName;
    const QString privPath = sshDir() + "/" + keyName;
    const QString pubPath = privPath + ".pub";
    const QByteArray finalComment = (keyComment.trimmed().isEmpty()
                                     ? QString::fromUtf8(DEFAULT_KEY_COMMENT)
                                     : keyComment.trimmed()).toUtf8();

    auto finish = [this](GitResult r) {
        m_isGenerating = false;
        emit isGeneratingChanged();
        return r;
    };

    QByteArray rawPriv, rawPub;
    if (!generateEd25519(rawPriv, rawPub))
        return finish(GitResult(false, QVariant(), "Failed to generate Ed25519 key pair."));

    QByteArray privPem = encodeOpenSshPrivateKey(rawPriv, rawPub, finalComment);
    OPENSSL_cleanse(rawPriv.data(), size_t(rawPriv.size()));

    const QByteArray pubLine = "ssh-ed25519 " + ed25519PublicBlob(rawPub).toBase64()
                               + ' ' + finalComment + '\n';

    // Private key: create, restrict to owner, then write.
    QFile privFile(privPath);
    bool ok = privFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
           && privFile.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner)
           && privFile.write(privPem) == privPem.size();
    privFile.close();
    OPENSSL_cleanse(privPem.data(), size_t(privPem.size()));

    QFile pubFile(pubPath);
    ok = ok && pubFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
            && pubFile.write(pubLine) == pubLine.size();
    pubFile.close();

    if (!ok) {
        QFile::remove(privPath);
        QFile::remove(pubPath);
        return finish(GitResult(false, QVariant(),
                                QString("Failed to write key files in %1").arg(sshDir())));
    }

    finish(GitResult(true));
    scanAllKeys();
    emit keysChanged();
    emit activeKeyChanged();

    return GitResult(true, QVariant(pubPath));
}

QString SshKeyManager::suggestedImportName(const QString &sourcePath) const
{
    QString base = QFileInfo(toLocalPath(sourcePath)).completeBaseName();
    if (base.isEmpty())
        base = QFileInfo(toLocalPath(sourcePath)).fileName();

    base.replace(QRegularExpression("[^A-Za-z0-9._-]"), "-");
    while (base.startsWith('.') || base.startsWith('-') || base.startsWith('_'))
        base.remove(0, 1);
    if (base.endsWith(".pub"))
        base.chop(4);
    if (base.isEmpty())
        return generateUniqueKeyName();

    QString candidate = base;
    for (int i = 1; !keyNameError(candidate).isEmpty(); ++i) {
        if (i > 999)
            return generateUniqueKeyName();
        candidate = QString("%1_%2").arg(base).arg(i);
    }
    return candidate;
}

GitResult SshKeyManager::importKey(const QString &sourcePath, const QString &requestedName)
{
    const QString name = requestedName.trimmed();
    const QString error = keyNameError(name);
    if (!error.isEmpty())
        return GitResult(false, QVariant(), error);

    const QString src = toLocalPath(sourcePath);
    QFile srcFile(src);
    if (!srcFile.exists() || srcFile.size() > 256 * 1024 || !srcFile.open(QIODevice::ReadOnly))
        return GitResult(false, QVariant(), "Could not read the selected file.");
    QByteArray privText = srcFile.readAll();
    srcFile.close();
    privText.replace("\r\n", "\n");

    if (src.endsWith(".pub") || privText.startsWith("ssh-") || privText.startsWith("ecdsa-"))
        return GitResult(false, QVariant(),
                         "That looks like a public key. Select the private key file instead.");

    const ParsedPrivateKey parsed = inspectPrivateKey(privText);
    if (!parsed.valid)
        return GitResult(false, QVariant(), "The selected file is not an SSH private key.");

    // Public key: prefer the sibling .pub, otherwise derive it from the key file.
    QByteArray pubLine;
    QFile sibling(src + ".pub");
    if (sibling.open(QIODevice::ReadOnly)) {
        pubLine = sibling.readAll().trimmed();
        sibling.close();
    }
    if (pubLine.isEmpty() && !parsed.publicLine.isEmpty())
        pubLine = (parsed.publicLine + ' ' + name).toUtf8();
    if (pubLine.isEmpty())
        return GitResult(false, QVariant(),
                         "This key format has no embedded public key. Put its .pub file next to it "
                         "(same name) and try again.");

    QDir dir(sshDir());
    if (!dir.exists() && !dir.mkpath("."))
        return GitResult(false, QVariant(),
                         QString("Failed to create SSH directory: %1").arg(sshDir()));

    if (!privText.endsWith('\n'))
        privText.append('\n');

    const QString privPath = sshDir() + "/" + name;
    QFile privFile(privPath);
    bool ok = privFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
           && privFile.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner)
           && privFile.write(privText) == privText.size();
    privFile.close();

    QFile pubFile(privPath + ".pub");
    ok = ok && pubFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
            && pubFile.write(pubLine + '\n') == pubLine.size() + 1;
    pubFile.close();

    if (!ok) {
        QFile::remove(privPath);
        QFile::remove(privPath + ".pub");
        return GitResult(false, QVariant(), "Failed to write the imported key files.");
    }

    scanAllKeys();
    emit keysChanged();
    emit activeKeyChanged();

    QVariantMap data;
    data["name"] = name;
    data["encrypted"] = parsed.encrypted;
    return GitResult(true, data);
}

GitResult SshKeyManager::exportKey(const QString &keyName, const QString &destDir, bool includePrivate)
{
    const QString privPath = sshDir() + "/" + keyName;
    const QString pubPath = privPath + ".pub";
    if (keyName.isEmpty() || !QFile::exists(pubPath))
        return GitResult(false, QVariant(), "Key not found.");
    if (includePrivate && !QFile::exists(privPath))
        return GitResult(false, QVariant(), "This key has no private key file to export.");

    const QString dest = toLocalPath(destDir);
    if (dest.isEmpty() || !QFileInfo(dest).isDir())
        return GitResult(false, QVariant(), "Choose an existing folder.");

    const QString outPub = dest + "/" + keyName + ".pub";
    const QString outPriv = dest + "/" + keyName;
    if (QFile::exists(outPub) || (includePrivate && QFile::exists(outPriv)))
        return GitResult(false, QVariant(),
                         "A file with that name already exists in the chosen folder.");

    if (!QFile::copy(pubPath, outPub))
        return GitResult(false, QVariant(), "Failed to write the public key.");

    if (includePrivate) {
        if (!QFile::copy(privPath, outPriv)) {
            QFile::remove(outPub);
            return GitResult(false, QVariant(), "Failed to write the private key.");
        }
        QFile::setPermissions(outPriv, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    }

    return GitResult(true, QVariant(dest));
}

GitResult SshKeyManager::deleteKeyByName(const QString &keyName)
{
    if (keyName.isEmpty())
        return GitResult(false, QVariant(), "Key name cannot be empty.");

    const QString privPath = sshDir() + "/" + keyName;
    const QString pubPath = privPath + ".pub";

    const bool removedPrivate = !QFile::exists(privPath) || QFile::remove(privPath);
    const bool removedPublic = !QFile::exists(pubPath) || QFile::remove(pubPath);

    if (!removedPrivate || !removedPublic)
        return GitResult(false, QVariant(), "Failed to delete one or more key files.");

    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    if (settings.value(ACTIVE_KEY).toString() == keyName)
        settings.remove(ACTIVE_KEY);
    remapProviderAssignments(keyName, QString());

    scanAllKeys();
    emit keysChanged();
    emit activeKeyChanged();

    return GitResult(true);
}

GitResult SshKeyManager::renameKey(const QString &oldName, const QString &newName)
{
    const QString target = newName.trimmed();

    if (oldName.isEmpty() || target.isEmpty())
        return GitResult(false, QVariant(), "Key name cannot be empty.");
    if (target == oldName)
        return GitResult(true);

    const QString oldPriv = sshDir() + "/" + oldName;
    const QString newPriv = sshDir() + "/" + target;

    if (!QFile::exists(oldPriv + ".pub"))
        return GitResult(false, QVariant(), "Key not found.");

    const QString nameError = keyNameError(target);
    if (!nameError.isEmpty())
        return GitResult(false, QVariant(), nameError);

    // Private key may be missing (public-only entry); rename what exists.
    const bool hasPriv = QFile::exists(oldPriv);
    if (hasPriv && !QFile::rename(oldPriv, newPriv))
        return GitResult(false, QVariant(), "Failed to rename private key file.");
    if (!QFile::rename(oldPriv + ".pub", newPriv + ".pub")) {
        if (hasPriv)
            QFile::rename(newPriv, oldPriv);   // roll back
        return GitResult(false, QVariant(), "Failed to rename public key file.");
    }

    QSettings settings{QString::fromLatin1(SETTINGS_ORG), QString::fromLatin1(SETTINGS_APP)};
    if (settings.value(ACTIVE_KEY).toString() == oldName)
        settings.setValue(ACTIVE_KEY, target);
    remapProviderAssignments(oldName, target);

    scanAllKeys();
    emit keysChanged();
    emit activeKeyChanged();
    return GitResult(true);
}

void SshKeyManager::refresh()
{
    scanAllKeys();
    emit keysChanged();
}
