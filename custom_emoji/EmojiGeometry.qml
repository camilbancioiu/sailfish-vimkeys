/*
 * Copyright (C) 2014 Janne Edelman.
 * Contact: Janne Edelman <janne.edelman@gmail.com>
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

QtObject {
    // Trying to adapt to different screen sizes
    property real widthCorrection: keyboard.width / (portraitMode ? 540 : 960)
    property int languageSelectKeyWidth: (portraitMode ? 66 : 100 ) * geometry.scaleRatio * widthCorrection
    // page key width set by icon width. width correction makes row to break after rotation to landscape
    // property int setPageKeyWidth: (portraitMode ? 72 : 72 ) * geometry.scaleRatio * widthCorrection
    property int setSelectKeyWidth: (portraitMode ? 44 : 88) * geometry.scaleRatio * widthCorrection
    property int configKeyWidth: (portraitMode ? 40 : 40) * geometry.scaleRatio * widthCorrection
}