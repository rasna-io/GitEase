#include "GitignoreEngine.h"

#include "IgnoreFile.h"
#include "IgnorePatterns.h"
#include "OperationResult.h"
#include "RepositoryScanner.h"
#include "RuleEditor.h"
#include "TemplateStore.h"

#include <QDir>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QPointer>
#include <QtConcurrent/QtConcurrentRun>

namespace {

QVariantMap noRepository()
{
    return OperationResult::failure(QStringLiteral("No repository is open"));
}

} // namespace

GitignoreEngine::GitignoreEngine(QObject *parent)
    : QObject(parent)
{
}

QString GitignoreEngine::repoPath() const
{
    return m_repoPath;
}

bool GitignoreEngine::busy() const
{
    return m_busy;
}

void GitignoreEngine::setRepoPath(const QString &path)
{
    if (m_repoPath == path) {
        return;
    }

    m_repoPath = path;

    // A scan that is still running must not report into the new repository.
    ++m_generation;
    setBusy(false);

    emit repoPathChanged();
}

void GitignoreEngine::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }

    m_busy = busy;
    emit busyChanged();
}

QString GitignoreEngine::currentRoot() const
{
    // The host opened this path as a repository, so it is the working directory itself.
    if (m_repoPath.isEmpty() || !QFileInfo(m_repoPath).isDir()) {
        return {};
    }

    return QDir::cleanPath(m_repoPath);
}

// -- Repository --------------------------------------------------------------------------------

int GitignoreEngine::beginScan()
{
    setBusy(true);
    return ++m_generation;
}

void GitignoreEngine::finishScan(int generation, const QVariantMap &hostScan)
{
    if (generation != m_generation) {
        return;
    }

    auto *watcher = new QFutureWatcher<QVariantMap>(this);
    QPointer<GitignoreEngine> self(this);

    connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [self, watcher, generation]() {
        const QVariantMap result = watcher->result();
        watcher->deleteLater();

        if (!self || generation != self->m_generation) {
            return;
        }

        self->setBusy(false);
        emit self->scanned(result);
    });

    // Sorting and counting every file does not belong on the GUI thread.
    watcher->setFuture(QtConcurrent::run(&RepositoryScanner::analyze, hostScan));
}

void GitignoreEngine::failScan(int generation, const QString &message)
{
    if (generation != m_generation) {
        return;
    }

    setBusy(false);
    emit scanned(OperationResult::failure(message));
}

void GitignoreEngine::cancelScan(int generation)
{
    if (generation != m_generation) {
        return;
    }

    setBusy(false);
}

// -- Rules -------------------------------------------------------------------------------------

QStringList GitignoreEngine::patternsFor(const QVariantList &entries, const QString &mode) const
{
    return IgnorePatterns::build(entries, mode);
}

QVariantMap GitignoreEngine::addPatterns(const QStringList &patterns)
{
    const QString root = currentRoot();
    if (root.isEmpty()) {
        return noRepository();
    }

    return RuleEditor::addPatterns(root, patterns);
}

QVariantMap GitignoreEngine::planUnignore(const QStringList &paths, const QVariantList &hits) const
{
    return RuleEditor::planUnignore(paths, hits);
}

QVariantMap GitignoreEngine::removeRules(const QVariantList &rules)
{
    const QString root = currentRoot();
    if (root.isEmpty()) {
        return noRepository();
    }

    return RuleEditor::removeRules(root, rules);
}

// -- The file ----------------------------------------------------------------------------------

QVariantMap GitignoreEngine::createGitignore(const QStringList &templateIds)
{
    const QString root = currentRoot();
    if (root.isEmpty()) {
        return noRepository();
    }

    if (QFileInfo::exists(IgnoreFile::filePath(root))) {
        return OperationResult::failure(QStringLiteral(".gitignore already exists"));
    }

    return applyTemplates(templateIds);
}

QVariantMap GitignoreEngine::saveGitignore(const QString &content)
{
    const QString root = currentRoot();
    if (root.isEmpty()) {
        return noRepository();
    }

    // The existing file decides the line ending the new text is written with.
    IgnoreFile file = IgnoreFile::read(root);
    file.lines = content.split(QLatin1Char('\n'));

    for (QString &line : file.lines) {
        if (line.endsWith(QLatin1Char('\r'))) {
            line.chop(1);
        }
    }

    while (!file.lines.isEmpty() && file.lines.last().isEmpty()) {
        file.lines.removeLast();
    }

    QString error;
    if (!file.save(root, &error)) {
        return OperationResult::failure(error);
    }

    return OperationResult::success();
}

// -- Templates ---------------------------------------------------------------------------------

QVariantList GitignoreEngine::templates() const
{
    return TemplateStore::catalog();
}

QString GitignoreEngine::templateContent(const QString &id) const
{
    return TemplateStore::read(id);
}

QString GitignoreEngine::defaultTemplateContent(const QString &id) const
{
    return TemplateStore::readDefault(id);
}

QVariantMap GitignoreEngine::applyTemplates(const QStringList &templateIds)
{
    const QString root = currentRoot();
    if (root.isEmpty()) {
        return noRepository();
    }

    IgnoreFile file = IgnoreFile::read(root);
    const bool existed = file.exists;

    const TemplateStore::ApplyResult applied = TemplateStore::applyTo(file, templateIds);

    // The file is written when something was added, or when it has to be created.
    if (!applied.applied.isEmpty() || !existed) {
        QString error;
        if (!file.save(root, &error)) {
            return OperationResult::failure(error);
        }
    }

    QVariantMap result = OperationResult::success();
    result[QStringLiteral("created")] = !existed;
    result[QStringLiteral("applied")] = applied.applied;
    result[QStringLiteral("skipped")] = applied.skipped;
    result[QStringLiteral("added")] = applied.addedRules;
    return result;
}

QVariantMap GitignoreEngine::saveUserTemplate(const QString &name, const QString &content)
{
    return TemplateStore::saveCustom(name, content);
}

QVariantMap GitignoreEngine::deleteUserTemplate(const QString &id)
{
    return TemplateStore::deleteCustom(id);
}

QVariantMap GitignoreEngine::saveTemplateOverride(const QString &id, const QString &content)
{
    return TemplateStore::saveOverride(id, content);
}

QVariantMap GitignoreEngine::resetTemplateOverride(const QString &id)
{
    return TemplateStore::resetOverride(id);
}
