import QtQuick

import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PalettoScrollBar
 * The application's own scroll bar (GitEase_Style_Impl.ScrollBar). It lives in a file of its own
 * so the Impl module, which also provides Popup, TextField and others, is not imported into the
 * files that use the stock Qt Quick Controls types.
 *
 *   ListView {
 *       ScrollBar.vertical: PalettoScrollBar {}
 *   }
 * ************************************************************************************************/
ScrollBar {}
