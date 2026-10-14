import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SetupProfileForm
 * Reusable profile setup form component
 * Can be used in welcome flow or settings
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string fullName: fullNameField.text
    property string email: emailField.text
    property bool showHint: true
    property string errorMessage: ""

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 420)
        spacing: 0

        // Description text
        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: 28
            Layout.alignment: Qt.AlignHCenter
            text: "This information will be used for your Git commits and identify you in the repository history"
            wrapMode: Text.WordWrap
            color: Style.colors.secondaryText
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.fontTypes.inter
            font.weight: 400
            font.pixelSize: Style.appFont.h3Pt
            font.letterSpacing: 0.1
            lineHeight: 1.45
        }

        // Input sections
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 18

            // First input section: Full Name
            FormInputField {
                id: fullNameField
                label: "Full Name"
                placeholderText: "John Doe"
                icon: Style.icons.user
                helperText: "This will appear as the author on all your commits"
            }

            // Second input section: Email Address
            FormInputField {
                id: emailField
                label: "Email Address"
                placeholderText: "john@example.com"
                icon: Style.icons.envelope
                helperText: "Use the same email as your GitHub/GitLab account to link commits"
            }

            // Hint row
            Rectangle {
                id: hintRectangle
                visible: root.showHint && root.errorMessage.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: hintRow.implicitHeight + 20
                radius: 8
                color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.25)

                RowLayout {
                    id: hintRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Style.icons.lightbulb
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.smallPt
                        color: Style.colors.secondaryText
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "You can change these settings later in the Settings page"
                        wrapMode: Text.WordWrap
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.inter
                        font.weight: 400
                        font.letterSpacing: 0
                        color: Style.colors.secondaryText
                    }
                }
            }

            // Error row
            Rectangle {
                id: errorRectangle
                visible: root.errorMessage.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: errorRow.implicitHeight + 20
                radius: 8
                color: Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.4)

                RowLayout {
                    id: errorRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Style.icons.circleExclamation
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.smallPt
                        color: Style.colors.error
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: root.errorMessage
                        wrapMode: Text.WordWrap
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.inter
                        font.weight: 400
                        font.letterSpacing: 0
                        color: Style.colors.error
                    }
                }
            }
        }
    }
}

