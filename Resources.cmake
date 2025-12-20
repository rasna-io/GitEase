# Resources.cmake

# Define Core Components
set(RESOURCES_CORE
    Qml/Core/Models/AppModel.qml
    Qml/Core/Models/AppSettings.qml

    Qml/Core/Controllers/WelcomeController.qml
)


# Define QML Components
set(RESOURCES_COMPONENTS
    # Base Components
    Qml/View/Components/Base/PageHeader.qml
    Qml/View/Components/Base/FormInputField.qml
    Qml/View/Components/Base/TabbedView.qml
    Qml/View/Components/Base/RepositoryListItem.qml

    # Profile Components
    Qml/View/Components/Profile/SetupProfileForm.qml

    # Repository Components
    Qml/View/Components/Repository/RecentRepositoriesList.qml
    Qml/View/Components/Repository/RepositorySelector.qml

    # Welcome-specific Content
    Qml/View/Components/WelcomeContents/WelcomeContent.qml
    Qml/View/Components/WelcomeContents/SetupProfileContent.qml
    Qml/View/Components/WelcomeContents/OpenRepositoryContent.qml
)


# Define UI Core Resources
set(RESOURCES_UICORE
    Qml/UiCore/UiSession.qml
    Qml/UiCore/UiSessionPopups.qml
)

# Define Popups Resources
set(RESOURCES_POPUPS
)


# Define QML Pages
set(RESOURCES_PAGES
    Qml/Pages/WelcomePage.qml
)
