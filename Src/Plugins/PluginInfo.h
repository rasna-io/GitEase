#pragma once

#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QJsonObject>
#include <QJsonArray>

struct PluginInfo
{
    QString     id;
    QString     name;
    QString     version;
    QString     apiVersion;
    QStringList capabilities;   // "dock" | "command" | "auth" | "diff" | "service"
    QString     author;
    QString     description;
    QString     cppEntry;       // relative path to .dll / .so inside pluginDir
    QString     qmlEntry;       // relative path to root QML component
    QString     pluginDir;      // absolute path to the plugin folder
    bool        enabled      = true;
    bool        loaded       = false;
    QString     errorMessage;

    bool isValid()     const { return !id.isEmpty() && !name.isEmpty(); }
    bool hasCppEntry() const { return !cppEntry.isEmpty(); }
    bool hasQmlEntry() const { return !qmlEntry.isEmpty(); }

    QVariantMap toVariantMap() const
    {
        return {
            { QStringLiteral("id"),           id           },
            { QStringLiteral("name"),         name         },
            { QStringLiteral("version"),      version      },
            { QStringLiteral("author"),       author       },
            { QStringLiteral("description"),  description  },
            { QStringLiteral("capabilities"), capabilities },
            { QStringLiteral("pluginDir"),    pluginDir    },
            { QStringLiteral("qmlEntry"),     qmlEntry     },
            { QStringLiteral("enabled"),      enabled      },
            { QStringLiteral("loaded"),       loaded       },
            { QStringLiteral("errorMessage"), errorMessage },
        };
    }

    static PluginInfo fromJson(const QJsonObject& obj, const QString& dir)
    {
        PluginInfo info;
        info.id          = obj.value(QStringLiteral("id")).toString();
        info.name        = obj.value(QStringLiteral("name")).toString();
        info.version     = obj.value(QStringLiteral("version")).toString();
        info.apiVersion  = obj.value(QStringLiteral("apiVersion")).toString();
        info.author      = obj.value(QStringLiteral("author")).toString();
        info.description = obj.value(QStringLiteral("description")).toString();
        info.cppEntry    = obj.value(QStringLiteral("cppEntry")).toString();
        info.qmlEntry    = obj.value(QStringLiteral("qmlEntry")).toString();
        info.enabled     = obj.value(QStringLiteral("enabled")).toBool(true);
        info.pluginDir   = dir;
        const auto caps  = obj.value(QStringLiteral("capabilities")).toArray();
        for (const auto& cap : caps)
            info.capabilities << cap.toString();
        return info;
    }
};
