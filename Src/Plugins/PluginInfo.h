#pragma once

#include <QString>
#include <QStringList>
#include <QVariantList>
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
    QString     icon;           // icon path relative to pluginDir (from plugin.json)
    QString     iconUrl;        // icon URL from server/CDN (from plugin.json)
    QString     minAppVersion;  // minimum GitEase version required
    QString     releaseDate;    // package release date
    QString     size;           // display size string, e.g. "128 KB"
    QString     longDescription; // details page: about text (long_description)
    QString     installGuide;   // details page: usage notes (install_guide)
    QString     githubUrl;      // details page: project link (github_url)
    QStringList tags;           // details page: keywords
    QVariantList features;      // details page: [{ title, description }] or plain strings
    QVariantList changelog;     // details page: [{ version, date, notes: [...] }]
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
            { QStringLiteral("icon"),         icon         },
            { QStringLiteral("iconUrl"),      iconUrl      },
            { QStringLiteral("minAppVersion"),minAppVersion},
            { QStringLiteral("releaseDate"),  releaseDate  },
            { QStringLiteral("size"),         size         },
            { QStringLiteral("longDescription"), longDescription },
            { QStringLiteral("installGuide"), installGuide },
            { QStringLiteral("githubUrl"),    githubUrl    },
            { QStringLiteral("tags"),         tags         },
            { QStringLiteral("features"),     features     },
            { QStringLiteral("changelog"),    changelog    },
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
        info.icon           = obj.value(QStringLiteral("icon")).toString();
        info.iconUrl        = obj.value(QStringLiteral("iconUrl")).toString();
        info.minAppVersion  = obj.value(QStringLiteral("minAppVersion")).toString();
        info.releaseDate    = obj.value(QStringLiteral("releaseDate")).toString();
        info.size           = obj.value(QStringLiteral("size")).toString();
        info.longDescription = obj.value(QStringLiteral("long_description")).toString();
        info.installGuide   = obj.value(QStringLiteral("install_guide")).toString();
        info.githubUrl      = obj.value(QStringLiteral("github_url")).toString();
        info.features       = obj.value(QStringLiteral("features")).toArray().toVariantList();
        info.changelog      = obj.value(QStringLiteral("changelog")).toArray().toVariantList();

        const auto tagList  = obj.value(QStringLiteral("tags")).toArray();
        for (const auto& tag : tagList)
            info.tags << tag.toString();
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
