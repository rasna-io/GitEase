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
)


# Define QML Components
set(RESOURCES_COMPONENTS
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

    # Navigation Components - Side rails / tab bars
    Qml/View/Components/Navigation/NavigationRail.qml           # Combined pages+repos navigation rail
    Qml/View/Components/Navigation/PagesRail.qml                # Pages-only navigation rail

    # Welcome-specific Content - Welcome page content sections
    Qml/View/Components/WelcomeContents/WelcomeContent.qml           # Main welcome content
)


# Define UI Core Resources
set(RESOURCES_UICORE
    Qml/UiCore/UiSession.qml          # Main UI session manager
    Qml/UiCore/UiSessionPopups.qml    # Popup management for UI session
)

# Define Popups Resources
set(RESOURCES_POPUPS
    # Popup components will be added here as they are created
)


# Define QML Pages
set(RESOURCES_PAGES
    Qml/Pages/WelcomePage.qml    # Initial welcome/onboarding page
)

# Define QML Services
set(RESOURCES_SERVICES
    Qml/Core/Services/GitService.qml
)

# Define View Resources
set(RESOURCES_VIEW
    Qml/View/MainWindow.qml
)
