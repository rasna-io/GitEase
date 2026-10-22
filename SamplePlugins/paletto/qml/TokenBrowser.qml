import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * TokenBrowser
 * Center of the page: search and filter controls above the grouped list of color tokens.
 * The list model is owned by the page, which rebuilds it when the filters change.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    //! Rows of the list: { tokenName, label, group, value, changed }.
    property var    tokens: null

    //! Groups that contain at least one token.
    property var    groupNames: []

    property string searchText:   ""
    property string groupFilter:  ""
    property bool   changedOnly:  false
    property string selectedName: ""

    //! "Revert all" needs an installed palette that differs from its base.
    property bool   canRevertAll: false

    /* Signals
     * ****************************************************************************************/
    signal searchEdited(string text)
    signal groupSelected(string group)
    signal changedOnlyToggled()
    signal tokenClicked(string tokenName)
    signal tokenRevertRequested(string tokenName)
    signal revertAllRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: 10

    /* Children
     * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        PalettoTextField {
            chrome: root.chrome
            Layout.fillWidth: true
            placeholderText: "Search tokens by name or color"
            text: root.searchText
            onTextEdited: root.searchEdited(text)
        }

        PalettoButton {
            chrome: root.chrome
            text: root.changedOnly ? "Showing changed" : "Changed only"
            variant: root.changedOnly ? "primary" : "secondary"
            iconText: "" // filter
            onClicked: root.changedOnlyToggled()
        }

        PalettoButton {
            chrome: root.chrome
            text: "Revert all"
            iconText: "" // undo
            enabled: root.canRevertAll
            tooltip: "Put every token back to the base theme value"
            onClicked: root.revertAllRequested()
        }
    }

    TokenGroupBar {
        chrome: root.chrome
        Layout.fillWidth: true
        groups: root.groupNames
        currentGroup: root.groupFilter
        onGroupSelected: function(group) {
            root.groupSelected(group)
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 10
        color: root.chrome.panel
        border.width: 1
        border.color: root.chrome.border

        ListView {
            id: tokenList

            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: root.tokens
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 600

            ScrollBar.vertical: PalettoScrollBar {}

            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                id: sectionHeader

                required property string section

                width: ListView.view.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    text: sectionHeader.section.toUpperCase()
                    font.family: root.chrome.fontText
                    font.pixelSize: root.chrome.sizeMicro
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    color: root.chrome.textFaint
                }
            }

            // The model roles (tokenName, label, value, changed) fill TokenRow's required properties.
            delegate: TokenRow {
                chrome: root.chrome
                width: ListView.view.width
                selected: root.selectedName === tokenName

                onClicked: root.tokenClicked(tokenName)
                onRevertRequested: root.tokenRevertRequested(tokenName)
            }

            Text {
                anchors.centerIn: parent
                visible: tokenList.count === 0
                text: root.changedOnly ? "No token differs from the base theme yet."
                                       : "No token matches your search."
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeBody
                color: root.chrome.textFaint
            }
        }
    }
}
