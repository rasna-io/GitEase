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

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Description text
        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: 24
            Layout.maximumWidth: 360
            Layout.alignment: Qt.AlignHCenter
            text: "This information will be used for your Git commits and identify you in the repository history"
            wrapMode: Text.WordWrap
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.fontTypes.roboto
            font.weight: 300
            font.pixelSize: 16
            font.italic: true
            font.letterSpacing: 0
        }

        // Input sections
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 440
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

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
                visible: root.showHint
                Layout.fillWidth: true
                Layout.preferredHeight: 37
                radius: 5
                color: Style.colors.hintBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "💡 Tip: You can change these settings later in the Settings page"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            color: Style.colors.hintText
                            font.family: Style.fontTypes.roboto
                            font.weight: 300
                            font.styleName: "Light"
                            font.letterSpacing: 0
                        }
                    }
                }
            }
        }
    }
}

