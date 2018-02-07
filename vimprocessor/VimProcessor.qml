import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    property bool vimNormalMode : false
    property bool vimModeKeyTriggerWaiting : false

    property string status : "insert";
    property var indicator : ({});
    property string combination : "";

    Component.onCompleted: {
      var statusIndicatorComponent = Qt.createComponent("VimProcessorStatusIndicator.qml");
      indicator = statusIndicatorComponent.createObject(keyboard);
      indicator.id = "vimProcessorStatusIndicator";
    }

    onStatusChanged: {
      indicator.status = status;
    }

    Timer {
        id: vimModeKeyTriggerTimer
        repeat: false
        interval: 200

        onTriggered: {
            if (vimModeKeyTriggerWaiting == true) {
                vimModeKeyTriggerWaiting = false;
                vimNormalMode = false;
                status = "insert";
            }
        }
    }

    Timer {
        id: antiAutocapsTimer
        repeat: false
        interval: 5
        
        onTriggered: {
            if (keyboard.vimNormalMode == true) {
               keyboard.shiftState = ShiftState.NoShift; 
            }
        }
    }

    function reset() {
        vimNormalMode = false;
        vimModeKeyTriggerWaiting = false;
        combination = "";
        keyboard.resetShift();
    }

    function handleVimKeys(pressedKey) {
        if (vimNormalMode == false) {
            if (pressedKey.key == Qt.Key_Space) {
                if (vimModeKeyTriggerWaiting == true) {
                    enterVimNormalMode();
                    return true;
                } else {
                    vimModeKeyTriggerWaiting = true;
                    vimModeKeyTriggerTimer.start();
                    status = "switching";
                }
            }
            return false;
        } else {
            if (pressedKey.key == Qt.Key_Space) {
                // Leave VimNormalMode and reset the parent InputHandler.
                _reset();
                status = "insert";
                return true;
            }
            if (pressedKey.key != Qt.Key_Shift) {
                keyboard.shiftState = ShiftState.NoShift;
            }
            return handleVimNormalModeKeys(pressedKey);
        }
    }

    function enterVimNormalMode() {
        MInputMethodQuick.sendKey(Qt.Key_Backspace, 0, "\b", Maliit.KeyClick)
        _reset();
        vimNormalMode = true;
        vimModeKeyTriggerWaiting = false;
        keyboard.autocaps = false;
        antiAutocapsTimer.start();
        status = "normal";
    }


    function handleVimNormalModeKeys(pressedKey) {
        var keys = [];
        var mods = [];

        // Allow default behaviour for the following keys.
        var bypassKeys = [Qt.Key_Enter, Qt.Key_Backspace];
        if (bypassKeys.indexOf(pressedKey.key) != -1) {
            return false;
        }

        // Handle combination keys.
        var comboStartKeys = ['d'];
        var comboEndKeys = ['d'];
        if (combination == "") {
            if (comboStartKeys.indexOf(pressedKey.text) != -1) {
                combination = pressedKey.text;
                return true;
            }
        } else {
            if (comboEndKeys.indexOf(pressedKey.text) != -1) {
                combination = combination + pressedKey.text;
            } else {
                combination = "";
                return true;
            }
            switch (combination) {
                case 'dd': keys = [Qt.Key_Home, Qt.Key_End, Qt.Key_Delete];     mods = [null, Qt.ShiftModifier, null]; break;
                default: combination = ''; return true;
            }
        }
        
        if (combination == '') {
            // Basic mappings.
            switch (pressedKey.text) {
                case "h": keys = [Qt.Key_Left];     mods = [null]; break;
                case "j": keys = [Qt.Key_Down];     mods = [null]; break;
                case "k": keys = [Qt.Key_Up];       mods = [null]; break;
                case "l": keys = [Qt.Key_Right];    mods = [null]; break;
                case "b": keys = [Qt.Key_Left];     mods = [Qt.ControlModifier]; break;
                case "w": keys = [Qt.Key_Right];    mods = [Qt.ControlModifier]; break;
                case "x": keys = [Qt.Key_Delete];   mods = [null]; break;
                case "u": keys = [Qt.Key_Z];        mods = [Qt.ControlModifier]; break;
            }
        }
        
        // Send keys.
        for (var i = 0; i < keys.length; i++) {
            if (mods[i] != null) {
                MInputMethodQuick.sendKey(keys[i], mods[i]);
            } else {
                MInputMethodQuick.sendKey(keys[i]);
            }
        }

        // Special handling.
        if (pressedKey.text == "s") {
            MInputMethodQuick.sendCommit(MInputMethodQuick.surroundingText);
        }

        return true;
    }

}
