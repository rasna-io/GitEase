#include "TemplateStore.h"

#include "OperationResult.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStandardPaths>

#include <algorithm>

namespace TemplateStore {

namespace {

const QString &userPrefix()
{
    static const QString prefix = QStringLiteral("user:");
    return prefix;
}

QString bundledDir()
{
    return QStringLiteral(":/com.gitease.gitignore-manager/templates/");
}

//! Folder of the templates the user wrote, in the roaming app data like the notifications.
QString userDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/gitignore-templates/");
}

bool isSafeBundledId(const QString &id)
{
    static const QRegularExpression safe(QStringLiteral(R"(^[A-Za-z0-9_.+-]+$)"));
    return safe.match(id).hasMatch();
}

bool isValidUserName(const QString &name)
{
    static const QRegularExpression valid(QStringLiteral(R"(^[A-Za-z0-9][A-Za-z0-9 _.+()-]{0,59}$)"));

    if (!valid.match(name).hasMatch()) {
        return false;
    }

    return !name.endsWith(QLatin1Char(' ')) && !name.endsWith(QLatin1Char('.'));
}

bool isCustomId(const QString &id)
{
    return id.startsWith(userPrefix());
}

QString customName(const QString &id)
{
    return id.mid(userPrefix().size());
}

QString customFilePath(const QString &name)
{
    return userDir() + name + QStringLiteral(".gitignore");
}

//! Where the customized copy of the bundled template \a id is kept; empty for an unsafe id.
QString overrideFilePath(const QString &id)
{
    if (!isSafeBundledId(id)) {
        return {};
    }

    return userDir() + QStringLiteral("overrides/") + id + QStringLiteral(".gitignore");
}

//! File text with LF line endings; empty when the file cannot be read.
QString readFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    QString text = QString::fromUtf8(file.readAll());
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    return text;
}

//! Writes \a content (LF endings, one trailing newline) to \a path, creating the folder.
QVariantMap writeTemplateFile(const QString &path, const QString &content)
{
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) {
        return OperationResult::failure(QStringLiteral("Could not create the templates folder"));
    }

    QString text = content;
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    if (!text.endsWith(QLatin1Char('\n'))) {
        text += QLatin1Char('\n');
    }

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        return OperationResult::failure(QStringLiteral("Could not save the template: ") + file.errorString());
    }

    file.write(text.toUtf8());
    if (!file.commit()) {
        return OperationResult::failure(QStringLiteral("Could not save the template: ") + file.errorString());
    }

    return OperationResult::success();
}

QList<Info> bundledIndex()
{
    QList<Info> list;

    QFile file(bundledDir() + QStringLiteral("index.json"));
    if (!file.open(QIODevice::ReadOnly)) {
        return list;
    }

    const QJsonArray array = QJsonDocument::fromJson(file.readAll()).array();
    for (const QJsonValue &value : array) {
        const QJsonObject object = value.toObject();

        Info info;
        info.id = object.value(QStringLiteral("id")).toString();
        info.name = object.value(QStringLiteral("name")).toString(info.id);
        info.category = object.value(QStringLiteral("category")).toString();
        info.description = object.value(QStringLiteral("description")).toString();

        if (!info.id.isEmpty()) {
            list << info;
        }
    }

    return list;
}

//! An earlier build kept custom templates in the local data folder; move them to the roaming one.
void migrateLegacyTemplates()
{
    static bool done = false;
    if (done) {
        return;
    }
    done = true;

    const QDir legacy(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                      + QStringLiteral("/GitEase/gitignore-templates/"));
    if (!legacy.exists()) {
        return;
    }

    QDir().mkpath(userDir());

    const QStringList names = legacy.entryList({ QStringLiteral("*.gitignore") }, QDir::Files);
    for (const QString &fileName : names) {
        const QString target = userDir() + fileName;

        if (!QFileInfo::exists(target)) {
            QFile::copy(legacy.filePath(fileName), target);
        }
        QFile::remove(legacy.filePath(fileName));
    }

    QDir().rmdir(legacy.path());
}

QString markerStart(const QString &name)
{
    return QStringLiteral("# >>> ") + name + QStringLiteral(" (template)");
}

QString markerEnd(const QString &name)
{
    return QStringLiteral("# <<< ") + name;
}

//! Names of the templates whose start marker is in \a lines.
QSet<QString> appliedNames(const QStringList &lines)
{
    static const QRegularExpression marker(QStringLiteral(R"(^# >>> (.+) \(template\)$)"));

    QSet<QString> names;
    for (const QString &line : lines) {
        const QRegularExpressionMatch match = marker.match(line.trimmed());
        if (match.hasMatch()) {
            names.insert(match.captured(1));
        }
    }

    return names;
}

/*!
 * Template text without the patterns already in \a present (which is extended). Blocks left
 * without a pattern are dropped together with their comments.
 */
QStringList filterTemplate(const QString &content, QSet<QString> &present, int *ruleCount)
{
    QStringList out;
    QStringList block;
    int blockRules = 0;

    auto flush = [&] {
        if (blockRules > 0) {
            if (!out.isEmpty()) {
                out << QString();
            }
            out += block;
        }

        block.clear();
        blockRules = 0;
    };

    const QStringList lines = content.split(QLatin1Char('\n'));
    for (const QString &raw : lines) {
        QString line = raw;
        if (line.endsWith(QLatin1Char('\r'))) {
            line.chop(1);
        }

        if (line.trimmed().isEmpty()) {
            flush();
            continue;
        }

        if (!isPattern(line)) {
            block << line;
            continue;
        }

        const QString key = line.trimmed();
        if (present.contains(key)) {
            continue;
        }

        present.insert(key);
        block << line;
        ++blockRules;
        ++*ruleCount;
    }

    flush();
    return out;
}

} // namespace

QList<Info> index()
{
    migrateLegacyTemplates();

    QList<Info> list;

    const QStringList files = QDir(userDir()).entryList({ QStringLiteral("*.gitignore") },
                                                        QDir::Files,
                                                        QDir::IgnoreCase | QDir::Name);
    for (const QString &fileName : files) {
        const QString name = fileName.chopped(int(QStringLiteral(".gitignore").size()));
        if (!isValidUserName(name)) {
            continue;
        }

        Info info;
        info.id = userPrefix() + name;
        info.name = name;
        info.category = QStringLiteral("My templates");
        info.description = QStringLiteral("Your own template");
        list << info;
    }

    list += bundledIndex();
    return list;
}

QString readDefault(const QString &id)
{
    if (isCustomId(id) || !isSafeBundledId(id)) {
        return {};
    }

    return readFile(bundledDir() + id + QStringLiteral(".gitignore"));
}

QString read(const QString &id)
{
    if (isCustomId(id)) {
        const QString name = customName(id);
        if (!isValidUserName(name)) {
            return {};
        }

        return readFile(customFilePath(name));
    }

    // A customized copy wins over the text that ships with the plugin.
    const QString overridePath = overrideFilePath(id);
    if (!overridePath.isEmpty()) {
        const QString customized = readFile(overridePath);
        if (!customized.isEmpty()) {
            return customized;
        }
    }

    return readDefault(id);
}

QVariantList catalog()
{
    QVariantList list;

    for (const Info &info : index()) {
        const QString content = read(info.id);
        if (content.isEmpty()) {
            continue;
        }

        int rules = 0;
        const QStringList lines = content.split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (isPattern(line)) {
                ++rules;
            }
        }

        const QString overridePath = overrideFilePath(info.id);
        const bool customized = !overridePath.isEmpty() && QFileInfo::exists(overridePath);

        QVariantMap entry;
        entry[QStringLiteral("id")] = info.id;
        entry[QStringLiteral("name")] = info.name;
        entry[QStringLiteral("category")] = info.category;
        entry[QStringLiteral("description")] = info.description;
        entry[QStringLiteral("rules")] = rules;
        entry[QStringLiteral("custom")] = isCustomId(info.id);
        entry[QStringLiteral("customized")] = customized;
        list << entry;
    }

    return list;
}

QStringList appliedIds(const QStringList &lines)
{
    const QSet<QString> names = appliedNames(lines);

    QStringList ids;
    for (const Info &info : index()) {
        if (names.contains(info.name)) {
            ids << info.id;
        }
    }

    return ids;
}

ApplyResult applyTo(IgnoreFile &file, const QStringList &ids)
{
    ApplyResult result;

    QSet<QString> present = file.patterns();
    const QSet<QString> already = appliedNames(file.lines);
    const QList<Info> catalogIndex = index();

    for (const QString &id : ids) {
        const auto info = std::find_if(catalogIndex.begin(), catalogIndex.end(),
                                       [&id](const Info &candidate) { return candidate.id == id; });
        if (info == catalogIndex.end()) {
            continue;
        }

        if (already.contains(info->name)) {
            result.skipped << info->name;
            continue;
        }

        int rules = 0;
        const QStringList section = filterTemplate(read(id), present, &rules);
        if (rules == 0) {
            result.skipped << info->name;
            continue;
        }

        if (!file.lines.isEmpty()) {
            file.lines << QString();
        }

        file.lines << markerStart(info->name);
        file.lines += section;
        file.lines << markerEnd(info->name);

        result.applied << info->name;
        result.addedRules += rules;
    }

    return result;
}

QVariantMap saveCustom(const QString &name, const QString &content)
{
    const QString trimmed = name.trimmed();

    if (!isValidUserName(trimmed)) {
        return OperationResult::failure(QStringLiteral("The template name is not valid"));
    }

    if (content.trimmed().isEmpty()) {
        return OperationResult::failure(QStringLiteral("The template is empty"));
    }

    QVariantMap result = writeTemplateFile(customFilePath(trimmed), content);
    if (result.value(QStringLiteral("success")).toBool()) {
        result[QStringLiteral("id")] = userPrefix() + trimmed;
    }

    return result;
}

QVariantMap deleteCustom(const QString &id)
{
    if (!isCustomId(id) || !isValidUserName(customName(id))) {
        return OperationResult::failure(QStringLiteral("Only your own templates can be deleted"));
    }

    QFile file(customFilePath(customName(id)));
    if (file.exists() && !file.remove()) {
        return OperationResult::failure(QStringLiteral("Could not delete the template: ") + file.errorString());
    }

    return OperationResult::success();
}

QVariantMap saveOverride(const QString &id, const QString &content)
{
    const QString path = overrideFilePath(id);
    const QString original = readDefault(id);

    if (path.isEmpty() || original.isEmpty()) {
        return OperationResult::failure(QStringLiteral("Only bundled templates can be customized"));
    }

    QString text = content;
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));

    if (text.trimmed().isEmpty()) {
        return OperationResult::failure(QStringLiteral("The template is empty"));
    }

    if (!text.endsWith(QLatin1Char('\n'))) {
        text += QLatin1Char('\n');
    }

    // Saving the shipped text again is the same as resetting.
    if (text == original) {
        return resetOverride(id);
    }

    QVariantMap result = writeTemplateFile(path, text);
    if (result.value(QStringLiteral("success")).toBool()) {
        result[QStringLiteral("id")] = id;
    }

    return result;
}

QVariantMap resetOverride(const QString &id)
{
    const QString path = overrideFilePath(id);
    if (path.isEmpty()) {
        return OperationResult::failure(QStringLiteral("Only bundled templates can be reset"));
    }

    QFile file(path);
    if (file.exists() && !file.remove()) {
        return OperationResult::failure(QStringLiteral("Could not reset the template: ") + file.errorString());
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("id")] = id;
    return result;
}

} // namespace TemplateStore
