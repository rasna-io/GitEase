# Resources.cmake

# Define Core Components
set(RESOURCES_CORE
    # Application Models
    Qml/Core/Models/AppModel.qml              # Main application data model
    Qml/Core/Models/AppSettings.qml           # Application settings (singleton)
    Qml/Core/Models/Enums.qml
    Qml/Core/Models/Repository.qml
    Qml/Core/Models/Page.qml

    # Controllers
    Qml/Core/Controllers/WelcomeController.qml    # Welcome page controller
    Qml/Core/Controllers/DockController.qml       # Dock widget management controller
    Qml/Core/Controllers/PageController.qml       # Page lifecycle and navigation controller
    Qml/Core/Controllers/LayoutController.qml     # Layout management controller (singleton)
    Qml/Core/Controllers/RepositoryController.qml # Repository Controller
    Qml/Core/Controllers/BranchController.qml
    Qml/Core/Controllers/RemoteController.qml
    Qml/Core/Controllers/CommitController.qml
    Qml/Core/Controllers/StatusController.qml

    # Scripts
    Qml/Core/Scripts/GraphUtils.js
    Qml/Core/Scripts/GraphLayout.js
)


# Define QML Components
set(RESOURCES_COMPONENTS

    Qml/View/Header.qml
    Qml/View/WindowsHeader.qml
    Qml/View/WindowsButton.qml

    Qml/View/Components/ProgressButton.qml

    # Base Components - Fundamental UI building blocks
    Qml/View/Components/Base/PageHeader.qml              # Standard page header component
    Qml/View/Components/Base/FormInputField.qml          # Form input field with validation
    Qml/View/Components/Base/TabbedView.qml              # Tabbed interface component
    Qml/View/Components/Base/RepositoryListItem.qml      # Repository list item display

    # Profile Components - User profile management
    Qml/View/Components/Profile/SetupProfileForm.qml     # Profile setup/editing form

    # Repository Components - Git repository management
    Qml/View/Components/Repository/RecentRepositoriesList.qml   # Recent repositories list
    Qml/View/Components/Repository/RepositorySelector.qml       # Repository selection component
    Qml/View/Components/Repository/RepositoriesSidebar.qml      # Repositories Sidebar component
    Qml/View/Components/Repository/SideBySideDiff.qml

    Qml/View/Components/Diff/DiffView.qml
    Qml/View/Components/Diff/StackedDiff.qml

    # Navigation Components - Side rails / tab bars
    Qml/View/Components/Navigation/NavigationRail.qml           # Combined pages+repos navigation rail
    Qml/View/Components/Navigation/PagesRail.qml                # Pages-only navigation rail

    # Welcome-specific Content - Welcome page content sections
    Qml/View/Components/WelcomeContents/WelcomeContent.qml      # Main welcome content

    #DockPanel Components
    Qml/View/Components/Docks/SimpleDock.qml                     # SimpleDock : header + content
    Qml/View/Components/PageDockZone/PageDropZone.qml            # Page Drop Zone
    Qml/View/Components/PageDockZone/DropZoneIndicator.qml       # Page Drop Zone Indicator

    # DockPanel Docks
    Qml/View/Components/Docks/CommitGraphDock.qml       # CommitGraphDock : show Commits and Graph
    Qml/View/Components/Docks/CommitGraphSimulator.qml  # GraphDummyDataGenerator
    Qml/View/Components/Docks/FileChangesDock.qml       # FileChangesDock : show file Changes on commit

    # File list components (commit UI)
    Qml/View/Components/FileLists/UnstagedFileListSection.qml  # Unstaged File Status Section
    Qml/View/Components/FileLists/UnstagedFileListRow.qml      # Unstaged File Status Section Row Item
    Qml/View/Components/FileLists/StagedFileListSection.qml    # Staged File Status Section
    Qml/View/Components/FileLists/StagedFileListRow.qml        # Staged File Status Section Row Item
    Qml/View/Components/FileLists/ActionIconButton.qml         # Action Button with Icon for Rows
    Qml/View/Components/FileLists/ChangesFileLists.qml         # File Status Section Component
    Qml/View/Components/FileLists/FileListSection.qml          # File List Section Base (header + rows)
    Qml/View/Components/FileLists/FileListRow.qml              # File List Section Base row item
)


# Define UI Core Resources
set(RESOURCES_UICORE
    Qml/UiCore/UiSession.qml          # Main UI session manager
    Qml/UiCore/UiSessionPopups.qml    # Popup management for UI session
)

# Define Popups Resources
set(RESOURCES_POPUPS
    # Popup components will be added here as they are created
    Qml/View/Popups/RepositorySelectorPopup.qml
)


# Define QML Pages
set(RESOURCES_PAGES
    Qml/Pages/DockAblePage.qml      # Dockable Page (indicators and etc)
    Qml/Pages/WelcomePage.qml       # Initial welcome/onboarding page
    Qml/Pages/GraphViewPage.qml     # Main graph view page
    Qml/Pages/CommittingPage.qml    # Commit Page
    Qml/Pages/BlankPage.qml         # Blank placeholder page
)

# Define QML Services
set(RESOURCES_SERVICES
    Qml/Core/Services/GitService.qml
)

# Define View Resources
set(RESOURCES_VIEW
    Qml/View/MainWindow.qml
)
