#include "IgnoreFile.h"

#include <QFile>
#include <QSaveFile>

bool isPattern(const QString &line)
{
    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty()) {
        return false;
    }

    return !trimmed.startsWith(QLatin1Char('#'));
}

QString IgnoreFile::filePath(const QString &root)
{
    return root + QStringLiteral("/.gitignore");
}

IgnoreFile IgnoreFile::read(const QString &root)
{
    IgnoreFile result;

    QFile file(filePath(root));
    if (!file.open(QIODevice::ReadOnly)) {
        return result;
    }

    result.exists = true;

    QString text = QString::fromUtf8(file.readAll());
    if (text.startsWith(QChar(0xFEFF))) {
        text.remove(0, 1);
    }

    if (text.contains(QStringLiteral("\r\n"))) {
        result.eol = QStringLiteral("\r\n");
    }

    result.lines = text.split(QLatin1Char('\n'));
    if (!result.lines.isEmpty() && result.lines.last().isEmpty()) {
        result.lines.removeLast();
    }

    for (QString &line : result.lines) {
        if (line.endsWith(QLatin1Char('\r'))) {
            line.chop(1);
        }
    }

    return result;
}

bool IgnoreFile::save(const QString &root, QString *error) const
{
    QSaveFile file(filePath(root));
    if (!file.open(QIODevice::WriteOnly)) {
        *error = QStringLiteral("Could not write .gitignore: ") + file.errorString();
        return false;
    }

    if (!lines.isEmpty()) {
        file.write((lines.join(eol) + eol).toUtf8());
    }

    if (!file.commit()) {
        *error = QStringLiteral("Could not write .gitignore: ") + file.errorString();
        return false;
    }

    return true;
}

QSet<QString> IgnoreFile::patterns() const
{
    QSet<QString> result;

    for (const QString &line : lines) {
        if (isPattern(line)) {
            result.insert(line.trimmed());
        }
    }

    return result;
}
