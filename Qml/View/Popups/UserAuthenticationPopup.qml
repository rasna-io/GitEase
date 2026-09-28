import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserAuthenticationPopup
 * Asks for the personal access token needed by an HTTPS remote operation.
 *
 * open() shows a generic prompt; request(operation, remoteName, remoteUrl) adds context about
 * what is being authenticated. The token is emitted through passwordConfirm and never stored.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool   isConfirmed:    false

    //! One of "", "fetch", "pull", "push", "pushForce".
    property string operation:      ""
    property string remoteName:     ""
    property string remoteUrl:      ""

    readonly property string token:         tokenField.text.trim()
    readonly property bool   canConfirm:    token.length > 0
    readonly property bool   hasWhitespace: tokenField.text.length > 0 && tokenField.text !== token

    readonly property string host: {
        const match = /^[a-z]+:\/\/(?:[^@\/]+@)?([^\/:]+)/i.exec(remoteUrl)
        return match ? match[1].toLowerCase() : ""
    }

    readonly property string repoPath: {
        const match = /^[a-z]+:\/\/[^\/]+\/(.+?)(?:\.git)?\/?$/i.exec(remoteUrl)
        return match ? match[1] : ""
    }

    readonly property string providerName: {
        if (host === "github.com" || host.endsWith(".github.com"))  return "GitHub"
        if (host.indexOf("gitlab") !== -1)                          return "GitLab"
        if (host === "bitbucket.org")                               return "Bitbucket"
        if (host === "dev.azure.com" || host.endsWith(".visualstudio.com")) return "Azure DevOps"
        return host
    }

    readonly property string tokenHelpUrl: {
        switch (providerName) {
        case "GitHub":       return "https://github.com/settings/tokens/new?description=GitEase&scopes=repo"
        case "GitLab":       return "https://" + host + "/-/user_settings/personal_access_tokens?name=GitEase&scopes=read_repository,write_repository"
        case "Bitbucket":    return "https://bitbucket.org/account/settings/app-passwords/new"
        case "Azure DevOps": return "https://dev.azure.com/_usersSettings/tokens"
        default:             return ""
        }
    }

    readonly property string operationLabel: {
        switch (operation) {
        case "fetch":     return "Fetch"
        case "pull":      return "Pull"
        case "push":      return "Push"
        case "pushForce": return "Force push"
        default:          return ""
        }
    }

    readonly property string subtitle: {
        const target = remoteName.length > 0 ? remoteName : "the remote"
        switch (operation) {
        case "fetch":     return "A personal access token is needed to fetch from " + target + "."
        case "pull":      return "A personal access token is needed to pull from " + target + "."
        case "push":      return "A personal access token is needed to push to " + target + "."
        case "pushForce": return "A personal access token is needed to force push to " + target + "."
        default:          return "This remote uses HTTPS and needs a personal access token."
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal passwordConfirm(string password)
    signal rejected()

    /* Object Properties
     * ****************************************************************************************/
    width: parent ? Math.min(Style.dp(460), parent.width - Style.dp(40)) : Style.dp(460)
    height: implicitHeight
    padding: Style.dp(22)

    modal: true
    closePolicy: Popup.CloseOnEscape

    onOpened: {
        isConfirmed = false
        tokenField.text = ""
        tokenField.revealed = false
        tokenField.forceActiveFocus()
    }

    onClosed: {
        tokenField.text = ""
        tokenField.revealed = false
        if (!isConfirmed)
            root.rejected()
        root.operation = ""
        root.remoteName = ""
        root.remoteUrl = ""
    }

    /* Functions
     * ****************************************************************************************/
    //! Opens the prompt with context about the operation that needs the token.
    function request(operation, remoteName, remoteUrl) {
        root.operation = operation || ""
        root.remoteName = remoteName || ""
        root.remoteUrl = remoteUrl || ""
        root.open()
    }

    function confirm() {
        if (!root.canConfirm) {
            tokenField.forceActiveFocus()
            return
        }
        root.isConfirmed = true
        root.passwordConfirm(root.token)
        root.close()
    }

    /* Children
     * ****************************************************************************************/
    component DialogButton: AbstractButton {
        id: dialogButton

        property string iconText: ""
        property bool   primary:  false
        property color  accentColor: Style.colors.accent

        implicitHeight: Style.dp(36)
        implicitWidth: Math.max(Style.dp(92), buttonRow.implicitWidth + Style.dp(28))
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        opacity: enabled ? 1.0 : 0.5

        background: Rectangle {
            radius: Style.dp(7)
            color: dialogButton.primary
                   ? (dialogButton.down ? Qt.darker(dialogButton.accentColor, 1.15)
                                        : dialogButton.hovered ? Qt.lighter(dialogButton.accentColor, 1.1)
                                                               : dialogButton.accentColor)
                   : (dialogButton.down || dialogButton.hovered ? Style.colors.controlBackgroundHover
                                                                : Style.colors.controlBackground)
            border.width: dialogButton.primary ? 0 : 1
            border.color: dialogButton.visualFocus ? Style.colors.accent : Style.colors.controlBorder

            Behavior on color { ColorAnimation { duration: Style.motionFast } }
        }

        contentItem: Item {
            Row {
                id: buttonRow
                anchors.centerIn: parent
                spacing: Style.dp(7)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: dialogButton.iconText.length > 0
                    text: dialogButton.iconText
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.captionPt
                    color: dialogButton.primary ? Style.colors.onAccentText : Style.colors.foreground
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: dialogButton.text
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.DemiBold
                    color: dialogButton.primary ? Style.colors.onAccentText : Style.colors.foreground
                }
            }
        }

        HoverHandler { cursorShape: dialogButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    }

    background: Rectangle {
        radius: Style.dp(12)
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: ColumnLayout {
        spacing: Style.dp(16)

        // ── Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(12)

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Style.dp(40)
                Layout.preferredHeight: Style.dp(40)
                radius: Style.dp(10)
                color: Style.colors.accentWash

                Text {
                    anchors.centerIn: parent
                    text: Style.icons.lock
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.largePt
                    color: Style.colors.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.dp(3)

                Text {
                    Layout.fillWidth: true
                    text: "Authentication required"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h3Pt
                    font.weight: Font.DemiBold
                    color: Style.colors.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    wrapMode: Text.WordWrap
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.secondaryText
                }
            }

            ActionIconButton {
                Layout.alignment: Qt.AlignTop
                iconText: Style.icons.close
                tooltip: "Cancel"
                backgroundColor: "transparent"
                textColor: Style.colors.secondaryText
                onClicked: root.close()
            }
        }

        // ── Remote context ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: remoteRow.implicitHeight + Style.dp(20)
            visible: root.remoteName.length > 0 || root.host.length > 0
            radius: Style.dp(8)
            color: Style.colors.controlBackground
            border.width: 1
            border.color: Style.colors.controlBorder

            RowLayout {
                id: remoteRow
                anchors.fill: parent
                anchors.leftMargin: Style.dp(12)
                anchors.rightMargin: Style.dp(12)
                spacing: Style.dp(10)

                Text {
                    text: Style.icons.cloud
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.defaultPt
                    color: Style.colors.secondaryText
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(2)

                    Text {
                        Layout.fillWidth: true
                        text: root.remoteName.length > 0 ? root.remoteName : root.providerName
                        elide: Text.ElideRight
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        color: Style.colors.foreground
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.host.length > 0
                        text: root.host + (root.repoPath.length > 0 ? "/" + root.repoPath : "")
                        elide: Text.ElideMiddle
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.microPt
                        color: Style.colors.secondaryText
                    }
                }

                Rectangle {
                    visible: root.operationLabel.length > 0
                    Layout.preferredHeight: Style.dp(22)
                    Layout.preferredWidth: operationText.implicitWidth + Style.dp(18)
                    radius: height / 2
                    color: root.operation === "pushForce" ? Style.colors.repoItemStatusConflictBg : Style.colors.accentWash

                    Text {
                        id: operationText
                        anchors.centerIn: parent
                        text: root.operationLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.microPt
                        font.weight: Font.DemiBold
                        color: root.operation === "pushForce" ? Style.colors.repoItemStatusConflictText : Style.colors.accent
                    }
                }
            }
        }

        // ── Token ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(6)

            Text {
                text: "Personal access token"
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt
                font.weight: Font.Medium
                color: Style.colors.foreground
            }

            TextField {
                id: tokenField

                property bool revealed: false

                Layout.fillWidth: true
                icon: Style.icons.key
                iconSize: Style.dp(14)
                placeholderText: root.providerName === "GitHub" ? "ghp_… or github_pat_…"
                               : root.providerName === "GitLab" ? "glpat-…"
                                                                : "Paste your token"
                echoMode: revealed ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                rightPadding: revealButton.width + Style.dp(12)
                font.family: revealed || text.length === 0 ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
                backgroundColor: Style.colors.controlBackground
                borderColor: Style.colors.controlBorder
                focusBorderColor: Style.colors.accent
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                onAccepted: root.confirm()

                ActionIconButton {
                    id: revealButton
                    anchors.right: parent.right
                    anchors.rightMargin: Style.dp(6)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tokenField.text.length > 0
                    iconText: tokenField.revealed ? Style.icons.eyeSlash : Style.icons.eye
                    tooltip: tokenField.revealed ? "Hide token" : "Show token"
                    backgroundColor: "transparent"
                    textColor: Style.colors.secondaryText
                    onClicked: {
                        tokenField.revealed = !tokenField.revealed
                        tokenField.forceActiveFocus()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.hasWhitespace
                text: "Leading or trailing spaces will be removed."
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.warning
            }
        }

        // ── Guidance ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: guidance.implicitHeight + Style.dp(20)
            radius: Style.dp(8)
            color: Style.colors.accentWash

            RowLayout {
                id: guidance
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.dp(12)
                anchors.rightMargin: Style.dp(12)
                spacing: Style.dp(10)

                Text {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Style.dp(1)
                    text: Style.icons.shield
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(6)

                    Text {
                        Layout.fillWidth: true
                        text: (root.providerName.length > 0 ? root.providerName : "Most Git hosts")
                              + " no longer accept account passwords over HTTPS. Use a token with repository access instead."
                              + " It is used for this operation only and is never saved."
                        wrapMode: Text.WordWrap
                        lineHeight: 1.15
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.microPt
                        color: Style.colors.secondaryText
                    }

                    Text {
                        visible: root.tokenHelpUrl.length > 0
                        text: "Create a token on " + root.providerName + "  " + Style.icons.detach
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.microPt
                        font.weight: Font.DemiBold
                        font.underline: linkHover.hovered
                        color: Style.colors.accent

                        HoverHandler {
                            id: linkHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: Qt.openUrlExternally(root.tokenHelpUrl)
                        }
                    }
                }
            }
        }

        // ── Actions ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)
            spacing: Style.dp(8)

            Text {
                Layout.fillWidth: true
                text: "Enter to confirm · Esc to cancel"
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.mutedText
            }

            DialogButton {
                text: "Cancel"
                onClicked: root.close()
            }

            DialogButton {
                primary: true
                enabled: root.canConfirm
                accentColor: root.operation === "pushForce" ? Style.colors.error : Style.colors.accent
                iconText: Style.icons.key
                text: root.operationLabel.length > 0 ? root.operationLabel : "Authenticate"
                onClicked: root.confirm()
            }
        }
    }
}
