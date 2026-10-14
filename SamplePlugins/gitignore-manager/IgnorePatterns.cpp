#include "IgnorePatterns.h"

#include <QSet>
#include <QVariantMap>

namespace IgnorePatterns {

namespace {

//! Escapes what git would otherwise read as a glob or a comment.
QString escape(const QString &text)
{
    QString out;
    out.reserve(text.size() + 2);

    for (const QChar c : text) {
        const bool special = c == QLatin1Char('\\')
                             || c == QLatin1Char('*')
                             || c == QLatin1Char('?')
                             || c == QLatin1Char('[')
                             || c == QLatin1Char(']');
        if (special) {
            out += QLatin1Char('\\');
        }
        out += c;
    }

    if (out.startsWith(QLatin1Char('#')) || out.startsWith(QLatin1Char('!'))) {
        out.prepend(QLatin1Char('\\'));
    }

    if (out.endsWith(QLatin1Char(' '))) {
        out.insert(out.size() - 1, QLatin1Char('\\'));
    }

    return out;
}

QString folderSuffix(bool isDir)
{
    if (isDir) {
        return QStringLiteral("/");
    }

    return QString();
}

} // namespace

QStringList build(const QVariantList &entries, const QString &mode)
{
    QStringList patterns;
    QSet<QString> seen;

    auto add = [&](const QString &pattern) {
        if (pattern.isEmpty() || seen.contains(pattern)) {
            return;
        }

        seen.insert(pattern);
        patterns << pattern;
    };

    for (const QVariant &value : entries) {
        const QVariantMap entry = value.toMap();

        QString path = entry.value(QStringLiteral("path")).toString();
        const bool isDir = entry.value(QStringLiteral("isDir")).toBool() || path.endsWith(QLatin1Char('/'));

        while (path.endsWith(QLatin1Char('/'))) {
            path.chop(1);
        }

        if (path.isEmpty()) {
            continue;
        }

        const int slash = path.lastIndexOf(QLatin1Char('/'));
        const QString name = slash < 0 ? path : path.mid(slash + 1);
        const QString exact = QLatin1Char('/') + escape(path) + folderSuffix(isDir);

        if (mode == QLatin1String("name")) {
            add(escape(name) + folderSuffix(isDir));
            continue;
        }

        if (mode == QLatin1String("extension")) {
            const int dot = name.lastIndexOf(QLatin1Char('.'));
            const bool hasExtension = !isDir && dot > 0 && dot < name.size() - 1;

            if (hasExtension) {
                add(QStringLiteral("*.") + escape(name.mid(dot + 1)));
            } else {
                add(exact);
            }
            continue;
        }

        if (mode == QLatin1String("folder")) {
            if (slash > 0) {
                add(QLatin1Char('/') + escape(path.left(slash)) + QLatin1Char('/'));
            } else {
                add(exact);
            }
            continue;
        }

        add(exact);
    }

    return patterns;
}

} // namespace IgnorePatterns
