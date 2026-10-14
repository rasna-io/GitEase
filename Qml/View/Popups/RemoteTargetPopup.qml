import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * RemoteTargetPopup
 * Asks which remote a fetch, pull, push or tag operation uses: when nothing decides it (several
 * remotes, no default remote and no upstream yet, or an upstream with a different name than the
 * branch), or every time while "Always ask which remote" is on. Lists the candidates, can make
 * the chosen remote branch the branch's upstream, lets the user turn "Always ask" on or off, and
 * shows the exact command. Open it with ask(); the choice comes back through chosen().
 * ************************************************************************************************/
PopupDialog {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! One of "fetch", "pull", "push", "pushForce", "pushTag", "deleteTag".
    property string operation:      "push"

    property string subject:        ""

    property string message:        ""

    //! [{ remote, branch, url, note, label }]. branch is empty for fetch and the tag operations;
    //! remote is empty for "every remote"; label, when set, replaces the shown remote name.
    property var    choices:        []

    property int    selectedIndex:  0

    //! Offers to make the chosen remote branch the upstream of the checked out branch.
    property bool   offerUpstream:  false

    property bool   setUpstream:    true

    property string currentUpstream: ""
    property string defaultRemote:  ""

    property bool   offerAlwaysAsk: false

    property bool   alwaysAsk:      false

    readonly property var  selected: root.choices.length > 0
                                     ? root.choices[Math.min(root.selectedIndex, root.choices.length - 1)]
                                     : null

    readonly property bool isTag:      root.operation === "pushTag" || root.operation === "deleteTag"

    readonly property bool remoteOnly: root.isTag || root.operation === "fetch"

    readonly property bool isDanger:   root.operation === "pushForce" || root.operation === "deleteTag"

    readonly property string selectedTarget: root.selected ? root.selected.remote + "/" + (root.selected.branch || "") : ""

    readonly property var    upstreamOffer: {
        if (!root.offerUpstream || !root.selected)
            return null

        let target = root.selected.remote + "/" + (root.selected.branch || "")
        return target !== root.currentUpstream ? { target: target, hint: root.upstreamHint() } : null
    }

    readonly property bool   canSetUpstream: root.upstreamOffer !== null

    /* Signals
     * ****************************************************************************************/
    signal chosen(string remote, string branch, bool setUpstream, bool alwaysAsk)

    /* Object Properties
     * ****************************************************************************************/
    width: 440

    title: {
        switch (root.operation) {
        case "fetch":     return "Fetch"
        case "pull":      return "Pull into '" + root.subject + "'"
        case "pushForce": return "Force Push '" + root.subject + "'"
        case "pushTag":   return "Push Tag '" + root.subject + "'"
        case "deleteTag": return "Delete Tag '" + root.subject + "' From Remote"
        default:          return "Push '" + root.subject + "'"
        }
    }

    iconText: root.operation === "fetch"     ? Style.icons.download
            : root.operation === "pull"      ? Style.icons.arrowDown
            : root.operation === "deleteTag" ? Style.icons.trash
            : root.isTag                     ? Style.icons.tag
                                             : Style.icons.arrowUp

    iconColor: root.isDanger ? Style.colors.error : Style.colors.accent

    onUpstreamOfferChanged: {
        if (root.upstreamOffer)
            upstreamSection.offer = root.upstreamOffer
    }

    /* Children
     * ****************************************************************************************/
    Text {
        Layout.fillWidth: true
        visible: root.message !== ""
        text: root.message
        wrapMode: Text.WordWrap
        color: Style.colors.popupCheckboxLabelText
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
    }

    // Candidate targets
    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.elementSpacing

        Text {
            text: root.remoteOnly ? "REMOTE" : "REMOTE BRANCH"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.choices

                Rectangle {
                    id: choiceRow

                    required property var modelData
                    required property int index

                    readonly property bool checked: root.selectedIndex === choiceRow.index

                    Layout.fillWidth: true
                    implicitHeight: choiceColumn.implicitHeight + 14
                    radius: 5
                    color: choiceRow.checked ? Style.colors.accentWash
                         : choiceHover.hovered ? Style.colors.utilitiesRowHoverBackground
                                               : "transparent"
                    border.width: 1
                    border.color: choiceRow.checked ? Style.colors.popupInputBorderFocus
                                                    : Style.colors.popupInputBorder

                    HoverHandler {
                        id: choiceHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.selectedIndex = choiceRow.index
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: choiceRow.checked ? Style.colors.popupRadioBorderChecked : "transparent"
                            border.width: 1
                            border.color: choiceRow.checked ? Style.colors.popupRadioBorderChecked
                                                            : Style.colors.popupRadioBorder

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: Style.colors.popupRadioDot
                                visible: choiceRow.checked
                            }
                        }

                        ColumnLayout {
                            id: choiceColumn
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: choiceRow.modelData.label
                                          || (root.remoteOnly ? choiceRow.modelData.remote
                                                              : choiceRow.modelData.remote + "/" + choiceRow.modelData.branch)
                                    elide: Text.ElideRight
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.jetBrainsMono
                                    font.pixelSize: Style.appFont.defaultPt
                                }

                                Text {
                                    visible: (choiceRow.modelData.note || "") !== ""
                                    text: choiceRow.modelData.note || ""
                                    color: Style.colors.secondaryText
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.smallPt
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: (choiceRow.modelData.url || "") !== ""
                                text: choiceRow.modelData.url || ""
                                elide: Text.ElideMiddle
                                color: Style.colors.utilitiesRowSubText
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: Style.appFont.smallPt
                            }
                        }
                    }
                }
            }
        }
    }

    component CheckRow: RowLayout {
        id: checkRow

        property bool   checked: false
        property string label:   ""

        signal toggled()

        spacing: 8
        Layout.fillWidth: true

        Rectangle {
            width: 16
            height: 16
            radius: 3
            color: checkRow.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
            border.color: checkRow.checked ? Style.colors.popupCheckboxBackgroundChecked
                                           : Style.colors.popupCheckboxBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\u2713"
                color: Style.colors.popupCheckboxCheckmark
                font.pixelSize: Style.appFont.smallPt
                visible: checkRow.checked
            }
        }

        Text {
            Layout.fillWidth: true
            text: checkRow.label
            elide: Text.ElideRight
            color: Style.colors.popupCheckboxLabelText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: checkRow.toggled()
        }
    }

    // Set as upstream, with what that changes
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.offerUpstream || root.offerAlwaysAsk
        spacing: 0

        Item {
            id: upstreamSection

            //! 0 hidden, 1 shown. One animated value moves the height, the gap and the fade together.
            property real reveal: root.canSetUpstream ? 1 : 0

            //! The upstreamOffer the row shows, see onUpstreamOfferChanged.
            property var  offer: null

            Layout.fillWidth: true
            implicitHeight: (upstreamColumn.implicitHeight + (root.offerAlwaysAsk ? 8 : 0)) * reveal
            opacity: reveal
            visible: reveal > 0
            clip: true

            // Not while ask() fills the dialog in: it opens with the row already in place.
            Behavior on reveal {
                enabled: root.visible

                NumberAnimation {
                    duration: Style.motionMedium
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: upstreamColumn
                width: parent.width
                spacing: 3

                CheckRow {
                    checked: root.setUpstream
                    label: upstreamSection.offer ? "Set " + upstreamSection.offer.target + " as the upstream" : ""
                    onToggled: root.setUpstream = !root.setUpstream
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    text: upstreamSection.offer ? upstreamSection.offer.hint : ""
                    wrapMode: Text.WordWrap
                    color: Style.colors.secondaryText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                }
            }
        }

        CheckRow {
            visible: root.offerAlwaysAsk
            checked: root.alwaysAsk
            label: "Always ask which remote to use"
            onToggled: root.alwaysAsk = !root.alwaysAsk
        }
    }

    CommandPreview {
        Layout.fillWidth: true
        command: root.previewCommand()
    }

    actions: [
        PopupButton {
            tone: root.isDanger ? PopupButton.Destructive : PopupButton.Primary
            enabled: root.selected !== null
            text: {
                switch (root.operation) {
                case "fetch":     return "Fetch"
                case "pull":      return "Pull"
                case "pushForce": return "Force Push"
                case "pushTag":   return "Push Tag"
                case "deleteTag": return "Delete Tag"
                default:          return "Push"
                }
            }
            onClicked: root.accept()
        }
    ]

    /* Functions
     * ****************************************************************************************/

    function ask(options) {
        root.operation       = options.operation || "push"
        root.subject         = options.subject || ""
        root.message         = options.message || ""
        root.choices         = options.choices || []
        root.selectedIndex   = Math.max(0, options.selectedIndex || 0)
        root.offerUpstream   = options.offerUpstream === true
        root.setUpstream     = options.setUpstream !== false
        root.currentUpstream = options.currentUpstream || ""
        root.defaultRemote   = options.defaultRemote || ""
        root.offerAlwaysAsk  = options.offerAlwaysAsk === true
        root.alwaysAsk       = options.alwaysAsk === true
        root.open()
    }

    function upstreamHint() {
        if (!root.setUpstream)
            return root.currentUpstream !== ""
                    ? "'" + root.subject + "' keeps tracking " + root.currentUpstream + "."
                    : "'" + root.subject + "' keeps having no upstream."

        if (root.offerAlwaysAsk && root.alwaysAsk)
            return "Pull and Push keep asking while \"Always ask\" is on: the upstream is only preselected "
                    + "here, and is what git uses on the command line."

        if (root.defaultRemote !== "")
            return "Pull will use it from now on. Push keeps going to the default remote, "
                    + root.defaultRemote + "."

        return "Pull and Push will use it from now on, without asking."
    }

    function accept() {
        if (!root.selected)
            return

        let remote    = root.selected.remote
        let branch    = root.selected.branch || ""
        let upstream  = root.canSetUpstream && root.setUpstream
        let alwaysAsk = root.alwaysAsk

        root.close()
        root.chosen(remote, branch, upstream, alwaysAsk)
    }

    function previewCommand() {
        if (!root.selected)
            return ""

        let remote = root.selected.remote
        let branch = root.selected.branch || ""
        let upstream = root.canSetUpstream && root.setUpstream

        switch (root.operation) {
        case "fetch":
            return GitCommandText.fetch(remote)
        case "pull":
            return GitCommandText.pull(remote, branch)
                    + (upstream ? " && " + GitCommandText.setUpstream(root.subject, remote, branch) : "")
        case "pushTag":
            return GitCommandText.pushTag(remote, root.subject)
        case "deleteTag":
            return GitCommandText.pushDeleteTag(remote, root.subject)
        default:
            return GitCommandText.push(remote, root.subject, branch, root.operation === "pushForce", upstream)
        }
    }
}
