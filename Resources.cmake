# Resources.cmake

# Define Core Components
set(RESOURCES_CORE
    # Application Models
    Qml/Core/Models/AppModel.qml              # Main application data model
    Qml/Core/Models/AppSettings.qml           # Application settings (singleton)
    Qml/Core/Models/GeneralSettings.qml
    Qml/Core/Models/AppearanceSettings.qml
    Qml/Core/Models/Enums.qml
    Qml/Core/Models/Repository.qml
    Qml/Core/Models/Page.qml
    Qml/Core/Models/UserProfile.qml           # user profile model
    Qml/Core/Models/NotificationSettings.qml
    Qml/Core/Models/Plugin.qml

    # Controllers
    Qml/Core/Controllers/WelcomeController.qml      # Welcome page controller
    Qml/Core/Controllers/DockController.qml         # Dock widget management controller
    Qml/Core/Controllers/LayoutController.qml       # Layout management controller (singleton)
    Qml/Core/Controllers/RepositoryController.qml   # Repository Controller
    Qml/Core/Controllers/BranchController.qml
    Qml/Core/Controllers/RemoteController.qml
    Qml/Core/Controllers/CommitController.qml
    Qml/Core/Controllers/StatusController.qml
    Qml/Core/Controllers/BundleController.qml
    Qml/Core/Controllers/ConfigController.qml       # Git Config Controller
    Qml/Core/Controllers/UserProfileController.qml  # User Profile Controller
    Qml/Core/Controllers/ShellController.qml        # Shell Commands (rightClick Actions) Controller
    Qml/Core/Controllers/StashController.qml
    Qml/Core/Controllers/NotificationController.qml
    Qml/Core/Controllers/ActivityController.qml
    Qml/Core/Controllers/SshKeyController.qml
    Qml/Core/Controllers/MergeController.qml
    Qml/Core/Controllers/RebaseController.qml
    Qml/Core/Controllers/CherryPickController.qml
    Qml/Core/Controllers/ConflictController.qml
    Qml/Core/Controllers/TagController.qml
    Qml/Core/Controllers/GitTreeController.qml      # Commit file tree browser controller
    Qml/Core/Controllers/PluginController.qml
    Qml/Core/Controllers/ResetController.qml
    Qml/Core/Controllers/NetworkController.qml      # Network Controller
    Qml/Core/Controllers/UpdateController.qml       # Application Update Controller
    Qml/Core/Controllers/TerminalController.qml
    Qml/Core/Controllers/GuideController.qml

    # Scripts
    Qml/Core/Scripts/GraphUtils.js
    Qml/Core/Scripts/GraphLayout.js
    Qml/Core/Scripts/ConflictPopupUtils.js
    Qml/Core/Scripts/GraphViewPresenter.js
    Qml/Core/Scripts/CommitGraphDataLoader.js
    Qml/Core/Scripts/CommitGraphFilter.js
    Qml/Core/Scripts/CommitGraphNavigation.js
    Qml/Core/Scripts/CommitGraphMenuBuilder.js
)


# Define QML Components
set(RESOURCES_COMPONENTS

    Qml/View/Header.qml
    Qml/View/WindowsHeader.qml
    Qml/View/WindowsButton.qml

    Qml/View/Components/ProgressButton.qml

    # Base Components - Fundamental UI building blocks
    Qml/View/Components/Base/PageHeader.qml                    # Standard page header component
    Qml/View/Components/Base/FormInputField.qml                # Form input field with validation
    Qml/View/Components/Base/TabbedView.qml                    # Tabbed interface component
    Qml/View/Components/Base/RepositoryListItem.qml            # Repository list item display
    Qml/View/Components/Base/EmptyStateView.qml                # Items Empty State View
    Qml/View/Components/Base/BusyWaiter.qml                    # Items Busy Wait State View
    Qml/View/Components/Base/UtilitiesCard.qml
    Qml/View/Components/Base/DashedButton.qml                  # Dashed ghost action button for utilities cards
    Qml/View/Components/Base/ContextMenu.qml
    Qml/View/Components/Base/AccentCard.qml                    # Card with accent peeking out on the left
    Qml/View/Components/Base/DetachablePanel.qml               # Detachable panel wrapper
    Qml/View/Components/Base/MinimizedPanels.qml                # Footer bar for minimized DetachablePanel/Terminal instances
    Qml/View/Components/Base/SplitViewHandle.qml                # Shared SplitView drag handle
    Qml/View/Components/Base/DropZone.qml                      # Dock zone
    Qml/View/Components/Base/ScrollingText.qml                 # Single-line auto-scrolling text
    Qml/View/Components/Base/ModernInputArea.qml               # Modern Input Area
    Qml/View/Components/Base/PluginCard.qml
    Qml/View/Components/Base/ModernSpinBox.qml
    Qml/View/Components/Base/HorizontalTagInput.qml
    Qml/View/Components/Base/VerticalTagInput.qml
    Qml/View/Components/Base/FileStatusTag.qml                 # File change-status tag (compact letter / expanded word)

    # Profile Components - User profile management
    Qml/View/Components/Profile/SetupProfileForm.qml           # Profile setup/editing form
    Qml/View/Components/Profile/ProfileAvatar.qml              # Circular initial+color avatar
    Qml/View/Components/Profile/UserInfoSelector.qml           # Profile Selector
    Qml/View/Components/Profile/UserInfoSelectorItem.qml       # Profile Selector Item

    # Repository Components - Git repository management
    Qml/View/Components/Repository/RecentRepositoriesList.qml   # Recent repositories list
    Qml/View/Components/Repository/RecentRepositoryRow.qml      # Single recent-repository row
    Qml/View/Components/Repository/RepositorySelector.qml       # Repository selection component
    Qml/View/Components/Repository/RepositoriesSidebar.qml      # Repositories Sidebar component
    Qml/View/Components/Repository/WorktreeCard.qml             # Single worktree entry card
    Qml/View/Components/Repository/SideBySideDiff.qml

    Qml/View/Components/Repository/RepoSectionLabel.qml         # Uppercase field label
    Qml/View/Components/Repository/RepoTextField.qml            # Compact themed input
    Qml/View/Components/Repository/RepoBrowseButton.qml         # Outlined Browse/Open button
    Qml/View/Components/Repository/RepoRadio.qml                # Compact centered radio
    Qml/View/Components/Repository/RepoValidationLine.qml       # Green validation row

    # Repository selector dialog - tab sections
    Qml/View/Components/Repository/RecentsTab.qml               # Recents tab
    Qml/View/Components/Repository/OpenLocalTab.qml             # Open local tab
    Qml/View/Components/Repository/CloneTab.qml                 # Clone tab
    Qml/View/Components/Repository/WorktreesTab.qml             # Worktrees tab (UI only)
    Qml/View/Components/Repository/InitNewTab.qml               # Init new tab

    Qml/View/Components/Diff/DiffView.qml
    Qml/View/Components/Diff/StackedDiff.qml
    Qml/View/Components/Diff/StripedBackground.qml

    # Navigation Components - Side rails / tab bars
    Qml/View/Components/Navigation/NavigationRail.qml           # Combined pages+repos navigation rail
    Qml/View/Components/Navigation/PagesRail.qml                # Pages-only navigation rail

    # Welcome-specific Content - Welcome page content sections
    Qml/View/Components/WelcomeContents/WelcomeContent.qml      # Main welcome content

    # DockPanel Docks
    Qml/View/Components/Docks/CommitGraphDock.qml       # CommitGraphDock : show Commits and Graph
    Qml/View/Components/Docks/CommitGraphSimulator.qml  # GraphDummyDataGenerator

    Qml/View/Components/Docks/StashManagerDock.qml
    Qml/View/Components/Docks/RecentActivityDock.qml

    Qml/View/Components/Docks/RecentActivityDock.qml
    Qml/View/Components/Docks/RebaseDock.qml

    Qml/View/Components/Docks/RepositoriesHistoryDock.qml       # All Repositories Dock

    Qml/View/Components/Utilities/UtilityPanel.qml              # Filter field + scrolling dock flow

    # File list components (commit UI)
    Qml/View/Components/FileLists/UnstagedFileListSection.qml  # Unstaged File Status Section
    Qml/View/Components/FileLists/UnstagedFileListRow.qml      # Unstaged File Status Section Row Item
    Qml/View/Components/FileLists/StagedFileListSection.qml    # Staged File Status Section
    Qml/View/Components/FileLists/StagedFileListRow.qml        # Staged File Status Section Row Item
    Qml/View/Components/FileLists/ActionIconButton.qml         # Action Button with Icon for Rows
    Qml/View/Components/FileLists/ChangesFileLists.qml         # File Status Section Component
    Qml/View/Components/FileLists/FileListSection.qml          # File List Section Base (header + rows)
    Qml/View/Components/FileLists/FileListRow.qml              # File List Section Base row item

    # DockPanel Docks
    Qml/View/Components/Docks/FileChangesDock.qml       # FileChangesDock : show file Changes on commit

    Qml/View/Components/Settings/CheckboxItem.qml
    Qml/View/Components/Settings/PathSelectorItem.qml
    Qml/View/Components/Settings/TextFieldItem.qml
    Qml/View/Components/Settings/ComboboxItem.qml
    Qml/View/Components/Settings/SpinboxItem.qml
    Qml/View/Components/Settings/ButtonItem.qml
    Qml/View/Components/Settings/SshKeyCard.qml
    Qml/View/Components/Settings/UpdateCard.qml

    # Import Export Bundle Components
    Qml/View/Components/ImportExport/ImportExportBundle.qml
    Qml/View/Components/ImportExport/ImportView.qml
    Qml/View/Components/ImportExport/ExportView.qml

    Qml/View/Components/Remotes/RemoteView.qml

    Qml/View/Components/Branch/BranchManagementView.qml
    Qml/View/Components/Branch/BranchesList.qml
    Qml/View/Components/Tag/TagManagementView.qml

    # DockPanel Docks
    Qml/View/Components/Docks/ImportExportBundleDock.qml       # Import Export git Bundle Dock

    # Notifications
    Qml/View/Components/Notification/NotificationItem.qml
    Qml/View/Components/Notification/NotificationCloseAllHeader.qml

    # Conflict Components
    Qml/View/Components/Conflict/ConflictFileList.qml
    Qml/View/Components/Conflict/ConflictConfirmationDialog.qml
    Qml/View/Components/Conflict/ConflictEditorDelegate.qml

    # Guide Components
    Qml/View/Components/Guide/GuideOverlay.qml
    Qml/View/Components/Guide/GuideTooltip.qml
    Qml/View/Components/Guide/GuideHoverTrigger.qml

    # Pages Components
    Qml/View/Components/Pages/CommittingPage/CommittingPageHeader.qml
    Qml/View/Components/Pages/CommittingPage/UnsavedChangesDialog.qml
    Qml/View/Components/Pages/PluginsPage/PluginsPageHeader.qml
    Qml/View/Components/Pages/PluginsPage/PluginsLeftPanel.qml
    Qml/View/Components/GraphView/GraphViewHeader.qml
    Qml/View/Components/GraphView/DateField.qml
    Qml/View/Components/GraphView/GraphFilterPopup.qml
    Qml/View/Components/GraphView/ResizableColumnHeader.qml
    Qml/View/Components/GraphView/CommitGraphCanvas.qml
    Qml/View/Components/GraphView/CommitListDelegate.qml
)


# Define UI Core Resources
set(RESOURCES_UICORE
    Qml/UiCore/UiSession.qml                    # Main UI session manager
    Qml/UiCore/UiSessionPopups.qml              # Popup management for UI session
    Qml/UiCore/RemoteOperationsSession.qml      # Control Fetch/Push/Pull actions
)

# Define Popups Resources
set(RESOURCES_POPUPS
    # Popup components will be added here as they are created
    Qml/View/Popups/UserInfoSelectionPopup.qml      # Show users list with action
    Qml/View/Popups/UserAuthenticationPopup.qml     # enter user password popup
    Qml/View/Popups/RepositorySelectorPopup.qml
    Qml/View/Popups/ItemSelectorPopup.qml           # Select Item popup
    Qml/View/Popups/SettingsPopup.qml
    Qml/View/Popups/IPopup.qml
    Qml/View/Popups/AddEditRemotePopup.qml
    Qml/View/Popups/AddBranchPopup.qml
    Qml/View/Popups/CheckoutBranchSelectorPopup.qml  # Branch picker for double-click checkout
    Qml/View/Popups/AddStashPopup.qml
    Qml/View/Popups/NotificationCenterPopup.qml
    Qml/View/Popups/ManageStashPopup.qml
    Qml/View/Popups/FetchSummaryPopup.qml
    Qml/View/Popups/ConflictPopup.qml
    Qml/View/Popups/MergeMethodPopup.qml
    Qml/View/Popups/CommitAmendPopup.qml

    Qml/View/Popups/AddTagPopup.qml
    Qml/View/Popups/CalendarPopup.qml

    Qml/View/Popups/CommitPlanPopup.qml
    Qml/View/Popups/CommitFileBrowserPopup.qml #browse file tree at a commit

)


# Define QML Pages
set(RESOURCES_PAGES
    Qml/Pages/WelcomePage.qml       # Initial welcome/onboarding page
    Qml/Pages/GraphViewPage.qml     # Main graph view page
    Qml/Pages/CommittingPage.qml    # Commit Page
    Qml/Pages/BlankPage.qml         # Blank placeholder page
    Qml/Pages/PluginsPage.qml       # Plugins page
)

# Define QML Services
set(RESOURCES_SERVICES
    Qml/Core/Services/GitService.qml
)

# Define View Resources
set(RESOURCES_VIEW
    Qml/View/MainWindow.qml
    Qml/View/FloatingNotificationWindow.qml     # show notifications
    Qml/View/Terminal.qml
)
