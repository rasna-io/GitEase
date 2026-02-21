#include "SshKeyManager.h"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QTextStream>
#include <QDateTime>
#include <QStandardPaths>

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

static constexpr const char* KEY_COMMENT = "gitease-key";

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

QString SshKeyManager::sshDir() const
{
    return QDir::homePath() + "/.ssh";
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
    for (const auto& key : m_allKeys) {
        QVariantMap map;
        map["name"] = key.name;
        map["fingerprint"] = key.fingerprint;
        map["publicKeyPath"] = key.publicKeyPath;
        map["privateKeyPath"] = key.privateKeyPath;
        map["publicKeyContent"] = key.publicKeyContent;
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
    info.fingerprint = runSshKeygenFingerprint(pubPath);

    return info;
}

// ---------------------------------------------------------------------------
// Internal: check if ssh-keygen is available
// ---------------------------------------------------------------------------

bool SshKeyManager::isSshKeygenAvailable() const
{
    return !QStandardPaths::findExecutable("ssh-keygen").isEmpty();
}

// ---------------------------------------------------------------------------
// Internal: get key fingerprint via ssh-keygen -lf
// ---------------------------------------------------------------------------

QString SshKeyManager::runSshKeygenFingerprint(const QString &pubPath) const
{
    if (!isSshKeygenAvailable())
        return {};

    QProcess proc;
    proc.start("ssh-keygen", {"-lf", pubPath});
    if (!proc.waitForFinished(5000))
        return {};

    const QString out = proc.readAllStandardOutput().trimmed();
    const int spaceIdx = out.indexOf(' ');
    return (spaceIdx >= 0) ? out.mid(spaceIdx + 1) : out;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

GitResult SshKeyManager::generateKey()
{
    if (m_isGenerating)
        return GitResult(false, QVariant(), "Key generation already in progress.");

    // Check if ssh-keygen is available
    if (!isSshKeygenAvailable())
        return GitResult(false, QVariant(),
                         "ssh-keygen not found. Please install OpenSSH.");

    // Ensure ~/.ssh exists
    QDir dir(sshDir());
    if (!dir.exists() && !dir.mkpath("."))
        return GitResult(false, QVariant(),
                         QString("Failed to create SSH directory: %1").arg(sshDir()));

    m_isGenerating = true;
    emit isGeneratingChanged();

    // Generate a unique key name
    QString keyName = generateUniqueKeyName();
    QString privPath = sshDir() + "/" + keyName;

    QStringList args;
    args << "-t" << "ed25519"
         << "-C" << KEY_COMMENT
         << "-f" << QDir::toNativeSeparators(privPath)
         << "-N" << "";  // No passphrase

    QProcess proc;
    proc.start("ssh-keygen", args);

    if (!proc.waitForStarted(5000)) {
        m_isGenerating = false;
        emit isGeneratingChanged();
        return GitResult(false, QVariant(),
                         "Failed to start ssh-keygen process.");
    }

    if (!proc.waitForFinished(15000)) {
        proc.kill();
        m_isGenerating = false;
        emit isGeneratingChanged();
        return GitResult(false, QVariant(), "ssh-keygen timed out.");
    }

    m_isGenerating = false;
    emit isGeneratingChanged();

    if (proc.exitCode() != 0) {
        QString errMsg = proc.readAllStandardError().trimmed();
        if (errMsg.isEmpty())
            errMsg = proc.readAllStandardOutput().trimmed();
        return GitResult(false, QVariant(),
                         QString("ssh-keygen failed: %1").arg(errMsg));
    }

    scanAllKeys();
    emit keysChanged();

    return GitResult(true, QVariant(privPath + ".pub"));
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

    scanAllKeys();
    emit keysChanged();

    return GitResult(true);
}

void SshKeyManager::refresh()
{
    scanAllKeys();
    emit keysChanged();
}
