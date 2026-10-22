#include "PalettoEngine.h"

#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QMetaProperty>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStandardPaths>

#include <algorithm>

namespace {

const QString kFormat  = QStringLiteral("gitease-paletto");
const int     kVersion = 1;

QString toHex(const QColor &c)
{
    return c.name(c.alpha() == 255 ? QColor::HexRgb : QColor::HexArgb);
}

// Group display order.
const QStringList &groupOrder()
{
    static const QStringList order = {
        QStringLiteral("Core"),
        QStringLiteral("Text"),
        QStringLiteral("Surfaces"),
        QStringLiteral("Controls and borders"),
        QStringLiteral("File status"),
        QStringLiteral("Diff"),
        QStringLiteral("Popups and menus"),
        QStringLiteral("Notifications"),
        QStringLiteral("Repository status"),
        QStringLiteral("Conflicts"),
        QStringLiteral("Rebase"),
        QStringLiteral("Utilities panel"),
        QStringLiteral("Commit panel"),
        QStringLiteral("Stash"),
        QStringLiteral("Commit graph"),
        QStringLiteral("Plugins"),
        QStringLiteral("Terminal"),
        QStringLiteral("Scrollbars"),
        QStringLiteral("Window"),
        QStringLiteral("Base swatches"),
        QStringLiteral("Other"),
    };
    return order;
}

struct Rule
{
    const char *match;  // prefix, or the whole name when exact
    bool        exact;
    const char *group;
};

//! A token goes to the first group whose rule matches.
QString groupFor(const QString &name)
{
    static const Rule rules[] = {
        { "utilities",           false, "Utilities panel" },
        { "stash",               false, "Stash" },
        { "notification",        false, "Notifications" },
        { "repoItemStatus",      false, "Repository status" },
        { "conflict",            false, "Conflicts" },
        { "rebase",              false, "Rebase" },
        { "plugin",              false, "Plugins" },
        { "updateButton",        true,  "Plugins" },
        { "compatible",          true,  "Plugins" },
        { "incompatible",        true,  "Plugins" },
        { "terminal",            false, "Terminal" },
        { "scrollBar",           false, "Scrollbars" },
        { "windows",             false, "Window" },
        { "resizeHandle",        false, "Window" },
        { "popup",               false, "Popups and menus" },
        { "contextMenu",         false, "Popups and menus" },
        { "scrimColor",          true,  "Popups and menus" },
        { "diff",                false, "Diff" },
        { "graph",               false, "Commit graph" },

        { "level",               false, "Commit panel" },
        { "branch",              false, "Commit panel" },
        { "forcePush",           false, "Commit panel" },
        { "section",             false, "Commit panel" },
        { "emptyCircle",         false, "Commit panel" },
        { "emptyState",          false, "Commit panel" },
        { "count",               false, "Commit panel" },
        { "action",              false, "Commit panel" },
        { "stageGreen",          true,  "Commit panel" },
        { "discardRed",          true,  "Commit panel" },
        { "openBlue",            true,  "Commit panel" },
        { "commitButton",        true,  "Commit panel" },
        { "filePath",            false, "Commit panel" },
        { "chip",                false, "Commit panel" },
        { "fileBrowser",         false, "Commit panel" },
        { "rowHoverBg",          true,  "Commit panel" },
        { "progressOverlay",     true,  "Controls and borders" },
        { "textButton",          true,  "Text" },

        { "primaryBackground",   true,  "Core" },
        { "secondaryBackground", true,  "Core" },
        { "foreground",          true,  "Core" },
        { "secondaryForeground", true,  "Core" },
        { "accent",              false, "Core" },
        { "error",               true,  "Core" },
        { "warning",             true,  "Core" },
        { "disabledButton",      true,  "Core" },

        { "addedFile",           true,  "File status" },
        { "deletededFile",       true,  "File status" },
        { "modifiediedFile",     true,  "File status" },
        { "renamedFile",         true,  "File status" },
        { "untrackedFile",       true,  "File status" },

        { "control",             false, "Controls and borders" },
        { "switch",              false, "Controls and borders" },
        { "primaryBorder",       true,  "Controls and borders" },
        { "secondaryBorder",     true,  "Controls and borders" },
        { "dashedButton",        false, "Controls and borders" },

        { "selectedText",        true,  "Text" },
        { "iconOn",              false, "Text" },
        { "lineNumber",          false, "Text" },
    };

    for(const Rule &rule : rules) {
        const QString match = QString::fromLatin1(rule.match);
        if(rule.exact ? name == match : name.startsWith(match)) {
            return QString::fromLatin1(rule.group);
        }
    }

    // "onAccentText", "onErrorText", ...
    if(name.size() > 2 && name.startsWith(QLatin1String("on")) && name.at(2).isUpper()) {
        return QStringLiteral("Text");
    }

    if(name.endsWith(QLatin1String("Text")) || name.endsWith(QLatin1String("Foreground"))
        || name.endsWith(QLatin1String("Foregroud"))) {
        return QStringLiteral("Text");
    }

    static const QSet<QString> swatches = {
        QStringLiteral("midnightBlack"),    QStringLiteral("warmChalk"),
        QStringLiteral("darkCharcoal"),     QStringLiteral("graphiteDark"),
        QStringLiteral("obsidianDark"),     QStringLiteral("mintyFresh"),
        QStringLiteral("softMintGlow"),     QStringLiteral("paleCoralMist"),
        QStringLiteral("deepObsidianOverlay"), QStringLiteral("deepCharcoalBlue"),
        QStringLiteral("graphiteMidnight"), QStringLiteral("mutedLavenderSlate"),
        QStringLiteral("vibrantMint"),      QStringLiteral("softCoralMist"),
        QStringLiteral("cornflowerBlue"),   QStringLiteral("amber"),
        QStringLiteral("purple"),           QStringLiteral("marigold"),
        QStringLiteral("vibrantMintBg"),    QStringLiteral("softCoralMistBg"),
        QStringLiteral("cornflowerBlueBg"), QStringLiteral("amberBg"),
        QStringLiteral("purpleBg"),         QStringLiteral("marigoldBg"),
        QStringLiteral("subtleAzureGlow"),  QStringLiteral("obsidianDeep"),
        QStringLiteral("softCloudWhite"),   QStringLiteral("slateLavender"),
        QStringLiteral("deepMidnight"),     QStringLiteral("darkObsidian"),
        QStringLiteral("abyssBlack"),       QStringLiteral("offWhite"),
        QStringLiteral("softParchment"),    QStringLiteral("darkGraphite"),
        QStringLiteral("charcoalGray"),     QStringLiteral("lightPlatinum"),
        QStringLiteral("azureTint"),        QStringLiteral("graphiteSurface"),
        QStringLiteral("graphiteHover"),    QStringLiteral("graphiteSelected"),
        QStringLiteral("slateMuted"),       QStringLiteral("frostWash"),
    };
    if(swatches.contains(name)) {
        return QStringLiteral("Base swatches");
    }

    const QString lower = name.toLower();
    static const char *surfaceHints[] = {
        "background", "backgroound", "bg", "surface", "hover", "card", "header", "nav", "row",
        "stripe", "segmented", "userinfo", "repo",
    };
    for(const char *hint : surfaceHints) {
        if(lower.contains(QLatin1String(hint))) {
            return QStringLiteral("Surfaces");
        }
    }

    return QStringLiteral("Other");
}

//! "primaryBackground" -> "Primary background"
QString labelFor(const QString &name)
{
    QString out;
    out.reserve(name.size() + 4);
    for(int i = 0; i < name.size(); ++i) {
        const QChar c = name.at(i);
        if(i == 0) {
            out += c.toUpper();
        } else if(c.isUpper() && (!name.at(i - 1).isUpper()
                                   || (i + 1 < name.size() && name.at(i + 1).isLower()))) {
            out += QLatin1Char(' ');
            out += c.toLower();
        } else {
            out += c;
        }
    }
    return out;
}

//! Keeps the entries of \a colors whose key is a token name and whose value is a color.
QVariantMap cleanColors(const QVariantMap &colors, int *skipped = nullptr)
{
    static const QRegularExpression nameRe(QStringLiteral("^[A-Za-z_][A-Za-z0-9_]*$"));

    QVariantMap out;
    for(auto it = colors.constBegin(); it != colors.constEnd(); ++it) {
        const QColor c(it.value().toString());
        if(!nameRe.match(it.key()).hasMatch() || !c.isValid()) {
            if(skipped) {
                ++*skipped;
            }
            continue;
        }
        out.insert(it.key(), toHex(c));
    }
    return out;
}

QJsonObject toJson(const QVariantMap &colors)
{
    QJsonObject obj;
    for(auto it = colors.constBegin(); it != colors.constEnd(); ++it) {
        obj.insert(it.key(), it.value().toString());
    }
    return obj;
}

QVariantMap fail(const QString &message)
{
    return { { QStringLiteral("success"), false }, { QStringLiteral("errorMessage"), message } };
}

QVariantMap ok()
{
    return { { QStringLiteral("success"), true } };
}

} // namespace

PalettoEngine::PalettoEngine(QObject *parent)
    : QObject(parent)
{
}

// -- Tokens ------------------------------------------------------------------------------------

QVariantList PalettoEngine::tokens(QObject *colors) const
{
    QVariantList list;
    if(!colors) {
        return list;
    }

    const QMetaObject *meta = colors->metaObject();
    const QMetaType colorType = QMetaType::fromType<QColor>();

    for(int i = 0; i < meta->propertyCount(); ++i) {
        const QMetaProperty prop = meta->property(i);
        if(prop.metaType() != colorType) {
            continue;
        }

        const QString name = QString::fromLatin1(prop.name());
        const QColor value = prop.read(colors).value<QColor>();

        list.append(QVariantMap {
            { QStringLiteral("name"),  name },
            { QStringLiteral("label"), labelFor(name) },
            { QStringLiteral("group"), groupFor(name) },
            { QStringLiteral("value"), toHex(value) },
        });
    }
    return list;
}

QVariantMap PalettoEngine::snapshot(QObject *colors) const
{
    QVariantMap map;
    const QVariantList list = tokens(colors);
    for(const QVariant &entry : list) {
        const QVariantMap token = entry.toMap();
        map.insert(token.value(QStringLiteral("name")).toString(),
                   token.value(QStringLiteral("value")));
    }
    return map;
}

QString PalettoEngine::normalizeColor(const QString &text) const
{
    QString trimmed = text.trimmed();
    if(trimmed.isEmpty()) {
        return {};
    }

    // Allow "ff8800" without the hash.
    static const QRegularExpression bareHex(
        QStringLiteral("^([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"));
    if(bareHex.match(trimmed).hasMatch()) {
        trimmed.prepend(QLatin1Char('#'));
    }

    const QColor c(trimmed);
    return c.isValid() ? toHex(c) : QString();
}

QStringList PalettoEngine::groups() const
{
    return groupOrder();
}

// -- Library -----------------------------------------------------------------------------------

QString PalettoEngine::libraryPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/paletto/palettes.json");
}

QVariantList PalettoEngine::readLibrary() const
{
    QVariantList library;

    QFile file(libraryPath());
    if(!file.open(QIODevice::ReadOnly)) {
        return library;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    const QJsonArray array = doc.object().value(QStringLiteral("palettes")).toArray();

    for(const QJsonValue &value : array) {
        const QJsonObject obj = value.toObject();
        const QString name = obj.value(QStringLiteral("name")).toString().trimmed();
        if(name.isEmpty()) {
            continue;
        }

        const QVariantMap colors =
            cleanColors(obj.value(QStringLiteral("colors")).toObject().toVariantMap());
        library.append(QVariantMap {
            { QStringLiteral("name"),   name },
            { QStringLiteral("base"),   obj.value(QStringLiteral("base")).toString() },
            { QStringLiteral("colors"), colors },
            { QStringLiteral("count"),  static_cast<int>(colors.size()) },
        });
    }
    return library;
}

bool PalettoEngine::writeLibrary(const QVariantList &library, QString *error) const
{
    const QString path = libraryPath();
    if(!QDir().mkpath(QFileInfo(path).absolutePath())) {
        if(error) {
            *error = QStringLiteral("Could not create the Paletto data folder.");
        }
        return false;
    }

    QJsonArray array;
    for(const QVariant &entry : library) {
        const QVariantMap palette = entry.toMap();
        QJsonObject obj;
        obj.insert(QStringLiteral("name"),   palette.value(QStringLiteral("name")).toString());
        obj.insert(QStringLiteral("base"),   palette.value(QStringLiteral("base")).toString());
        obj.insert(QStringLiteral("colors"), toJson(palette.value(QStringLiteral("colors")).toMap()));
        array.append(obj);
    }

    QJsonObject root;
    root.insert(QStringLiteral("format"),   kFormat);
    root.insert(QStringLiteral("version"),  kVersion);
    root.insert(QStringLiteral("palettes"), array);

    QSaveFile file(path);
    if(!file.open(QIODevice::WriteOnly)) {
        if(error) {
            *error = QStringLiteral("Could not write %1.").arg(path);
        }
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));

    if(!file.commit()) {
        if(error) {
            *error = QStringLiteral("Could not save %1.").arg(path);
        }
        return false;
    }
    return true;
}

QVariantList PalettoEngine::palettes() const
{
    QVariantList library = readLibrary();
    std::sort(library.begin(), library.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("name")).toString().compare(
                   b.toMap().value(QStringLiteral("name")).toString(), Qt::CaseInsensitive) < 0;
    });
    return library;
}

QVariantMap PalettoEngine::savePalette(const QString &name, const QString &base,
                                       const QVariantMap &colors)
{
    const QString trimmed = name.trimmed();
    if(trimmed.isEmpty()) {
        return fail(QStringLiteral("Give the palette a name."));
    }

    QVariantList library = readLibrary();
    const QVariantMap palette {
        { QStringLiteral("name"),   trimmed },
        { QStringLiteral("base"),   base },
        { QStringLiteral("colors"), cleanColors(colors) },
    };

    bool replaced = false;
    for(QVariant &entry : library) {
        const QString existing = entry.toMap().value(QStringLiteral("name")).toString();
        if(existing.compare(trimmed, Qt::CaseInsensitive) == 0) {
            entry = palette;
            replaced = true;
            break;
        }
    }
    if(!replaced) {
        library.append(palette);
    }

    QString error;
    if(!writeLibrary(library, &error)) {
        return fail(error);
    }
    return ok();
}

QVariantMap PalettoEngine::deletePalette(const QString &name)
{
    QVariantList library = readLibrary();
    bool removed = false;
    for(int i = library.size() - 1; i >= 0; --i) {
        const QString existing = library.at(i).toMap().value(QStringLiteral("name")).toString();
        if(existing.compare(name, Qt::CaseInsensitive) == 0) {
            library.removeAt(i);
            removed = true;
        }
    }
    if(!removed) {
        return fail(QStringLiteral("That palette no longer exists."));
    }

    QString error;
    if(!writeLibrary(library, &error)) {
        return fail(error);
    }
    return ok();
}

// -- Files -------------------------------------------------------------------------------------

QVariantMap PalettoEngine::exportPalette(const QString &path, const QString &name,
                                         const QString &base, const QVariantMap &colors) const
{
    if(path.isEmpty()) {
        return fail(QStringLiteral("No file was chosen."));
    }

    QJsonObject root;
    root.insert(QStringLiteral("format"),  kFormat);
    root.insert(QStringLiteral("version"), kVersion);
    root.insert(QStringLiteral("name"),    name);
    root.insert(QStringLiteral("base"),    base);
    root.insert(QStringLiteral("colors"),  toJson(cleanColors(colors)));

    QSaveFile file(path);
    if(!file.open(QIODevice::WriteOnly)) {
        return fail(QStringLiteral("Could not write %1.").arg(path));
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    if(!file.commit()) {
        return fail(QStringLiteral("Could not save %1.").arg(path));
    }
    return ok();
}

QVariantMap PalettoEngine::importPalette(const QString &path) const
{
    QFile file(path);
    if(!file.open(QIODevice::ReadOnly)) {
        return fail(QStringLiteral("Could not open %1.").arg(path));
    }
    if(file.size() > 4 * 1024 * 1024) {
        return fail(QStringLiteral("That file is too large to be a palette."));
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if(parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        return fail(QStringLiteral("That file is not a valid palette (%1).")
                        .arg(parseError.errorString()));
    }

    const QJsonObject root = doc.object();
    if(root.value(QStringLiteral("format")).toString() != kFormat
        || !root.value(QStringLiteral("colors")).isObject()) {
        return fail(QStringLiteral("That file is not a Paletto palette."));
    }
    if(root.value(QStringLiteral("version")).toInt(kVersion) > kVersion) {
        return fail(QStringLiteral("That palette was made by a newer version of Paletto."));
    }

    int skipped = 0;
    const QVariantMap colors =
        cleanColors(root.value(QStringLiteral("colors")).toObject().toVariantMap(), &skipped);

    QString name = root.value(QStringLiteral("name")).toString().trimmed();
    if(name.isEmpty()) {
        name = QFileInfo(path).completeBaseName();
    }

    QVariantMap result = ok();
    result.insert(QStringLiteral("name"),    name);
    result.insert(QStringLiteral("base"),    root.value(QStringLiteral("base")).toString());
    result.insert(QStringLiteral("colors"),  colors);
    result.insert(QStringLiteral("skipped"), skipped);
    return result;
}

QString PalettoEngine::localPath(const QUrl &url) const
{
    if(url.isLocalFile()) {
        return url.toLocalFile();
    }
    return url.toString();
}

QString PalettoEngine::suggestedFileName(const QString &name) const
{
    QString base = name.trimmed();
    base.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9._-]+")), QStringLiteral("-"));
    base.remove(QRegularExpression(QStringLiteral("^-+|-+$")));
    if(base.isEmpty()) {
        base = QStringLiteral("palette");
    }
    return base + QStringLiteral(".paletto.json");
}

QUrl PalettoEngine::suggestedExportUrl(const QString &name) const
{
    QString folder = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if(folder.isEmpty()) {
        folder = QDir::homePath();
    }
    return QUrl::fromLocalFile(folder + QLatin1Char('/') + suggestedFileName(name));
}
