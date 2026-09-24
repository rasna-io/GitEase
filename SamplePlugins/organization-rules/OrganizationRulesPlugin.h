#pragma once

#include <QObject>
#include "IPagePlugin.h"
#include "IRulePlugin.h"
#include "IRepositoryAwarePlugin.h"
#include "PluginContext.h"

class RuleManager;

class OrganizationRulesPlugin : public QObject, public IPagePlugin, public IRepositoryAwarePlugin, public IRulePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IPagePlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IPagePlugin IRulePlugin IRepositoryAwarePlugin)
public:
    QString id()      const override { return QStringLiteral("com.gitease.organization-rules"); }
    QString name()    const override { return QStringLiteral("Organization Rules"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown() override {}

    // IPagePlugin
    QString pageId()     const override { return QStringLiteral("com.gitease.organization-rules"); }
    QString pageTitle()  const override { return QStringLiteral("Rules"); }
    QString pageIcon()   const override { return QStringLiteral("\uf0e3"); } // fa-gavel
    QUrl    pageQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.organization-rules/qml/RulesPage.qml"));
    }
    int pageOrder() const override { return 60; }

    void repositoryChanged(const QString& repoPath) override;
    GitResult check(ActionContext* context) override;

    RuleManager* ruleManager() const { return m_ruleManager; }

private:
    RuleManager* m_ruleManager = nullptr;
};
