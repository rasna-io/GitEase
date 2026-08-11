import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * GraphFilterPopup
 *
 * Consolidated commit-filter panel: which field to search, a date range, and a branch. Values are
 * staged locally while the popup is open and only committed (via applyRequested/clearRequested)
 * when the user presses "Apply filters" / "Clear all".
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    filterFieldOptions : []
    property string filterField        : ""
    property string startDate          : ""
    property string endDate            : ""
    property var    branchNames        : []
    property string branchFilter       : ""
    property var    navigationRules    : []
    property string navigationRule     : ""

    /* Signals
     * ****************************************************************************************/
    signal applyRequested(string filterField, string startDate, string endDate, string branchFilter)
    signal clearRequested()
    signal startDateFieldClicked(var field)
    signal endDateFieldClicked(var field)
    signal navigationRuleSelected(string rule)

    /* Object Properties
     * ****************************************************************************************/
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 18
    width: 300

    background: Rectangle {
        color: Style.colors.primaryBackground
        radius: 14
        border.color: Style.colors.primaryBorder
        border.width: 1
    }

    onOpened: {
        x = Math.max(0, Math.min(x, parent.width - width))
        fieldCombo.currentIndex = root.fieldIndexFor(root.filterField)
        branchCombo.currentIndex = root.branchIndexFor(root.branchFilter)
        navCombo.currentIndex = root.navigationRules.indexOf(root.navigationRule)
    }

    contentItem: ColumnLayout {
        width: root.availableWidth
        spacing: 16

        Text {
            text: "FILTER COMMITS"
            color: Style.colors.descriptionText
            font.family: Style.fontTypes.inter
            font.weight: Font.DemiBold
            font.pixelSize: Style.appFont.captionPt
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "SEARCH FIELD"
                color: Style.colors.descriptionText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
            }

            ComboBox {
                id: fieldCombo
                Layout.fillWidth: true
                minHeight: 32
                model: root.filterFieldOptions
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: fieldCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "DATE RANGE"
                color: Style.colors.descriptionText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                DateField {
                    id: fromField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    placeholder: "From"
                    dateString: root.startDate
                    onClicked: root.startDateFieldClicked(fromField)
                }

                DateField {
                    id: toField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    placeholder: "To"
                    dateString: root.endDate
                    onClicked: root.endDateFieldClicked(toField)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "NAVIGATE BY"
                color: Style.colors.descriptionText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
            }

            ComboBox {
                id: navCombo
                Layout.fillWidth: true
                minHeight: 32
                model: root.navigationRules
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: navCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                currentIndex: root.navigationRules.indexOf(root.navigationRule)
                onActivated: function(index) {
                    root.navigationRuleSelected(root.navigationRules[index])
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "BRANCH"
                color: Style.colors.descriptionText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
            }

            ComboBox {
                id: branchCombo
                Layout.fillWidth: true
                minHeight: 32
                model: ["All branches"].concat(root.branchNames)
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: branchCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10

            Button {
                id: clearButton
                text: "Clear all"
                Layout.fillWidth: true
                Material.foreground: Style.colors.foreground

                background: Rectangle {
                    implicitHeight: 34
                    radius: 5
                    color: clearButton.hovered ? Style.colors.cardBackground : "transparent"
                    border.color: Style.colors.primaryBorder
                    border.width: 1
                }

                onClicked: {
                    root.filterField = ""
                    root.startDate = ""
                    root.endDate = ""
                    root.branchFilter = ""
                    fieldCombo.currentIndex = 0
                    branchCombo.currentIndex = 0
                    root.clearRequested()
                }
            }

            Button {
                id: applyButton
                text: "Apply filters"
                Layout.fillWidth: true
                Material.foreground: "white"

                background: Rectangle {
                    implicitHeight: 34
                    radius: 5
                    color: applyButton.hovered ? Style.colors.accentHover : Style.colors.accent
                }

                onClicked: {
                    var field = fieldCombo.currentIndex > 0 ? root.filterFieldOptions[fieldCombo.currentIndex] : ""
                    var branch = branchCombo.currentIndex > 0 ? root.branchNames[branchCombo.currentIndex - 1] : ""
                    root.applyRequested(field, root.startDate, root.endDate, branch)
                    root.close()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function fieldIndexFor(value) {
        var idx = root.filterFieldOptions.indexOf(value)
        return idx >= 0 ? idx : 0
    }

    function branchIndexFor(value) {
        var idx = root.branchNames.indexOf(value)
        return idx >= 0 ? idx + 1 : 0
    }
}
