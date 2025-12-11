import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UiSessionPopups holds popups that probabley one instance of them will serve to everywhere, like
 * about, close, confirm (yes, no, cancel, etc) popup, color select popup, etc
 *
 * \note This should be of type Item so Overlay.overlay (Window.window) is set for it and for its
 * Popups, since Popups will not open without this
 * ***********************************************************************************************/
Item {
    id: root

}
