#pragma once

// ── Core ─────────────────────────────────────────────────────────────────────
#include "IPlugin.h"
#include "IPluginContext.h"
#include "ActionContext.h"
#include "GitResult.h"

// ── Extension point interfaces ────────────────────────────────────────────────
#include "IDockPlugin.h"
#include "IPagePlugin.h"
#include "IContextMenuPlugin.h"
#include "IWorkflowPlugin.h"
#include "IToolbarPlugin.h"
#include "IRulePlugin.h"

// ── Optional mix-in interfaces ────────────────────────────────────────────────
#include "IRepositoryAwarePlugin.h"
#include "ICommandPlugin.h"
#include "IDiffPlugin.h"
