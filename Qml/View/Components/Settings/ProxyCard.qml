import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * ProxyCard
 * Proxy configuration panel used inside the Settings.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ProxyManager           proxyManager:           null
    property NotificationController notificationController: null

    readonly property var   typeLabels:  ["None", "HTTP", "SOCKS5", "VMess", "VLess", "Auto"]
    readonly property bool  isNoneType:  (root.proxyManager?.proxyType ?? 0) === 0
    readonly property bool  isAutoType:  root.proxyManager?.proxyType === 5
    readonly property bool  isV2RayType: root.proxyManager?.proxyType === 3 || root.proxyManager?.proxyType === 4

    /* Private state
    * ****************************************************************************************/
    property string _passwordDraft: ""

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: content.implicitHeight

    /* Functions
     * ****************************************************************************************/
    function _syncFromManager() {
        if (!root.proxyManager)
            return

        proxyTypeCombo.cmb.currentIndex = root.proxyManager.proxyType
        hostField.text = root.proxyManager.host
        portField.text = String(root.proxyManager.port)
        authCheckbox.checked = root.proxyManager.requiresAuth
        usernameField.text = root.proxyManager.username
        noProxyArea.text = root.proxyManager.noProxyList
    }

    /* Connections
    * ****************************************************************************************/
    Component.onCompleted: root._syncFromManager()
    onProxyManagerChanged: root._syncFromManager()

    Connections {
        target: root.proxyManager

        function onProxyTypeChanged() {
            if (proxyTypeCombo.cmb.currentIndex !== root.proxyManager.proxyType)
                proxyTypeCombo.cmb.currentIndex = root.proxyManager.proxyType
        }
        function onHostChanged() {
            if (hostField.text !== root.proxyManager.host)
                hostField.text = root.proxyManager.host
        }
        function onPortChanged() {
            if (portField.text !== String(root.proxyManager.port))
                portField.text = String(root.proxyManager.port)
        }
        function onRequiresAuthChanged() {
            if (authCheckbox.checked !== root.proxyManager.requiresAuth)
                authCheckbox.checked = root.proxyManager.requiresAuth
        }
        function onUsernameChanged() {
            if (usernameField.text !== root.proxyManager.username)
                usernameField.text = root.proxyManager.username
        }
        function onNoProxyListChanged() {
            if (noProxyArea.text !== root.proxyManager.noProxyList)
                noProxyArea.text = root.proxyManager.noProxyList
        }
    }

    component Collapsible: Item {
        id: section

        property bool shown: true
        property real progress: shown ? 1 : 0
        property real gap: 10
        property real contentSpacing: 10
        default property alias content: sectionColumn.data

        Layout.fillWidth: true
        Layout.preferredHeight: sectionColumn.implicitHeight * section.progress
        Layout.topMargin: section.gap * section.progress
        clip: true
        opacity: section.progress
        visible: section.progress > 0
        enabled: section.shown

        Behavior on progress {
            NumberAnimation {
                duration: Style.motionMedium;
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: sectionColumn
            width: section.width
            spacing: section.contentSpacing
        }
    }

    /* Children
     * ****************************************************************************************/
    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        NumberAnimation {
            id: wheelScrollAnim
            target: flick
            property: "contentY"
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                const maxY = Math.max(0, flick.contentHeight - flick.height)
                const base = wheelScrollAnim.running ? wheelScrollAnim.to : flick.contentY
                const next = Math.max(0, Math.min(maxY, base - event.angleDelta.y))
                wheelScrollAnim.stop()
                if (!Style.motionEnabled) {
                    flick.contentY = next
                    return
                }
                wheelScrollAnim.to = next
                wheelScrollAnim.start()
            }
        }

        ColumnLayout {
            id: content
            width: flick.width
            spacing: 0

            ComboboxItem {
                id: proxyTypeCombo
                Layout.fillWidth: true
                title: "Proxy Type"
                description: "Route Git and app traffic through a proxy. \"None\" disables proxying (default)."
                cmb.model: root.typeLabels
                cmb.onActivated: (index) => { if (root.proxyManager) root.proxyManager.proxyType = index }
            }

            // Everything below only applies when a proxy of ours is configured
            // (Auto has no host/port - the system/git config decides).
            Collapsible {
                shown: !root.isNoneType && !root.isAutoType
                contentSpacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: Style.colors.primaryBorder
                }

                TextFieldItem {
                    Layout.topMargin: 10
                    id: hostField
                    Layout.fillWidth: true
                    title: "Host"
                    description: "Proxy server address, e.g. 127.0.0.1 or proxy.example.com"
                    onTextChanged: if (root.proxyManager && root.proxyManager.host !== text) root.proxyManager.host = text
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 10
                    color: Style.colors.primaryBorder
                }

                TextFieldItem {
                    Layout.topMargin: 10
                    id: portField
                    Layout.fillWidth: true
                    title: "Port"
                    description: "Proxy server port (0 - 65535)"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 65535 }
                    onTextChanged: {
                        if (!root.proxyManager)
                            return
                        const parsed = parseInt(text, 10)
                        if (!isNaN(parsed) && root.proxyManager.port !== parsed)
                            root.proxyManager.port = parsed
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 10
                    color: Style.colors.primaryBorder
                }

                CheckboxItem {
                    Layout.topMargin: 10
                    id: authCheckbox
                    Layout.fillWidth: true
                    title: "Requires Authentication"
                    description: "Enable if the proxy server requires a username and password"
                    onCheckedChanged: if (root.proxyManager && root.proxyManager.requiresAuth !== checked) root.proxyManager.requiresAuth = checked
                }

                Collapsible {
                    shown: authCheckbox.checked

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: Style.colors.primaryBorder
                    }

                    TextFieldItem {
                        id: usernameField
                        Layout.fillWidth: true
                        title: "Username"
                        description: "Proxy authentication username"
                        onTextChanged: if (root.proxyManager && root.proxyManager.username !== text) root.proxyManager.username = text
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: Style.colors.primaryBorder
                    }

                    TextFieldItem {
                        id: passwordField
                        Layout.fillWidth: true
                        title: "Password"
                        description: (root.proxyManager?.hasPassword && root._passwordDraft.length === 0)
                                     ? "Proxy authentication password (a password is saved)"
                                     : "Proxy authentication password"
                        echoMode: TextInput.Password
                        placeholderText: root.proxyManager?.hasPassword ? "••••••••" : ""
                        field.onTextEdited: root._passwordDraft = passwordField.text
                        field.onEditingFinished: {
                            // Only push a change when the user actually typed something -
                            // avoids clobbering the stored password just by tabbing through.
                            if (root.proxyManager && root._passwordDraft.length > 0)
                                root.proxyManager.setPassword(passwordField.text)
                        }
                    }
                }
            }

            // Bypass list applies to Auto too, so it sits outside the block above.
            Collapsible {
                shown: !root.isNoneType

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: Style.colors.primaryBorder
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "No Proxy For"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Style.colors.foreground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Comma-separated hosts that skip the proxy: names, *.suffix wildcards or CIDR ranges (e.g. localhost, *.internal.corp, 10.0.0.0/8)"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 10
                            color: Style.colors.mutedText
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        radius: 6
                        color: Style.colors.controlBackground
                        border.width: noProxyArea.activeFocus ? 2 : 1
                        border.color: noProxyArea.activeFocus ? Style.colors.accent : Style.colors.controlBorder

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 6
                            clip: true

                            TextArea {
                                id: noProxyArea
                                wrapMode: TextArea.Wrap
                                font.family: Style.fontTypes.inter
                                font.pixelSize: 12
                                color: Style.colors.foreground
                                background: null
                                selectByMouse: true

                                onActiveFocusChanged: {
                                    if (!activeFocus && root.proxyManager && root.proxyManager.noProxyList !== text)
                                        root.proxyManager.noProxyList = text
                                }
                            }
                        }
                    }
                }
            }

            Collapsible {
                shown: root.isV2RayType

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: Style.colors.primaryBorder
                }

                ButtonItem {
                    id: useV2RayButton
                    Layout.fillWidth: true
                    title: "Local V2Ray / Xray"
                    description: "VMess/VLess aren't spoken directly - detect a running V2Ray/Xray client and route through its SOCKS inbound."
                    buttonTitle: "Use Local V2Ray"
                    onClicked: {
                        if (!root.proxyManager)
                            return

                        if (root.proxyManager.detectLocalV2Ray()) {
                            root.proxyManager.useLocalV2Ray()
                            if (root.notificationController)
                                root.notificationController.success(
                                    "Using local V2Ray/Xray SOCKS inbound at 127.0.0.1:10808.", "Proxy", 3000)
                        } else if (root.notificationController) {
                            root.notificationController.warning(
                                "No local V2Ray/Xray client detected on 127.0.0.1:10808. Make sure it's running and try again.",
                                "Proxy", 4000)
                        }
                    }
                }
            }
        }
    }
}
