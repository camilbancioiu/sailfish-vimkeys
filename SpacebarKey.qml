// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0

CharacterKey {
    property alias languageLabel: textField.text
    property bool expandingKey: true

    caption: " "
    captionShifted: " "
    showPopper: false
    separator: SeparatorState.HiddenSeparator
    showHighlight: false
    key: Qt.Key_Space

    Rectangle {
        color: parent.pressed ? Theme.highlightBackgroundColor : Theme.primaryColor
        opacity: parent.pressed ? 0.6 : 0.07
        radius: geometry.keyRadius

        anchors.fill: parent
        anchors.margins: Theme.paddingMedium
    }

    Text {
        id: textField
        x: Theme.paddingMedium + 2
        width: parent.width - 2*x
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: languageCode
        color: Theme.primaryColor
        opacity: .4
        font.pixelSize: Theme.fontSizeSmall
        fontSizeMode: Text.Fit
    }
}
