import QtQuick
import QtQuick.Templates as T

/*! ***********************************************************************************************
 * ScrollView
 * Material's ScrollView layout with the app's own ScrollBar, so every ScrollView scrolls with the
 * same thin, fading bar as the rest of the app instead of the stock Material one.
 * ************************************************************************************************/
T.ScrollView {
    id: control

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    /* Children
     * ****************************************************************************************/
    T.ScrollBar.vertical: ScrollBar {
        parent: control
        x: control.mirrored ? 0 : control.width - width
        y: control.topPadding
        height: control.availableHeight
        active: control.T.ScrollBar.horizontal.active
    }

    T.ScrollBar.horizontal: ScrollBar {
        parent: control
        x: control.leftPadding
        y: control.height - height
        width: control.availableWidth
        active: control.T.ScrollBar.vertical.active
    }
}
