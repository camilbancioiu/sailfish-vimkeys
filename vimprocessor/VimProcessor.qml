import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0 as Silica
import "."

Item {
  property string vimMode : "insert";
  property bool switching : false;
  property var indicator : ({});
  property string command : "";

  Component.onCompleted: {
    var statusIndicatorComponent = Qt.createComponent("VimProcessorStatusIndicator.qml");
    indicator = statusIndicatorComponent.createObject(keyboard);
    indicator.id = "vimProcessorStatusIndicator";
  }

  onVimModeChanged: {
    indicator.status = vimMode;
  }

  onSwitchingChanged: {
    if (switching) {
      indicator.status = "switching";
    } else {
      indicator.status = vimMode;
    }
  }


  Timer {
    id: vimModeKeyTriggerTimer
    repeat: false
    interval: 200

    onTriggered: {
      if (switching) {
        switching = false;
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
    vimMode = "insert";
    command = "";
    keyboard.resetShift();
  }

  function handleInput(pressedKey) {
    var vimModeSwitched = handleVimModeSwitching(pressedKey);
    if (switching) {
      if (vimMode == "normal") {
        return true;
      }
      return false;
    }

    if (vimModeSwitched && vimMode == "insert") {
      return true;
    }

    if (vimMode == "insert") {
      return false;
    } 

    if (vimModeSwitched) {
      return true;
    }
    
    if (vimMode == "normal") {
      if (pressedKey.key != Qt.Key_Shift) {
        keyboard.shiftState = ShiftState.NoShift;
      } 
      return handleVimNormalModeKeys(pressedKey);
    }
  }

  function handleVimModeSwitching(pressedKey) {
    if (pressedKey.key == Qt.Key_Space) {
      if (switching) {
        if (vimMode == "normal") {
          enterVimInsertMode();
        } else {
          enterVimNormalMode();
        }
        switching = false;
        return true;
      } else {
        vimModeKeyTriggerTimer.start();
        switching = true;
        return false;
      }
    }
    return false;
  }

  function enterVimNormalMode() {
    MInputMethodQuick.sendKey(Qt.Key_Backspace, 0, "\b", Maliit.KeyClick)
    resetParentInputHandler(); 
    keyboard.autocaps = false;
    keyboard.resetShift();
    vimMode = "normal";
    command = "";
    antiAutocapsTimer.start();
  }

  function enterVimInsertMode() {
    resetParentInputHandler(); 
    keyboard.resetShift();
    vimMode = "insert";
    command = "";
  }

  // See InputHandler._reset().
  function resetParentInputHandler() {
    autorepeatTimer.stop()
    multitap.flush()
    reset()
  }


  function handleVimNormalModeKeys(pressedKey) {
    var keys = [];
    var mods = [];

    // Allow default behaviour for the following keys.
    var bypassKeys = [Qt.Key_Enter, Qt.Key_Backspace];
    if (bypassKeys.indexOf(pressedKey.key) != -1) {
      return false;
    }

    // Handle command keys.
    var comboStartKeys = ['d'];
    var comboEndKeys = ['d'];
    if (command == "") {
      if (comboStartKeys.indexOf(pressedKey.text) != -1) {
        command = pressedKey.text;
        return true;
      }
    } else {
      if (comboEndKeys.indexOf(pressedKey.text) != -1) {
        command = command + pressedKey.text;
      } else {
        command = "";
        return true;
      }
      switch (command) {
        case 'dd': keys = [Qt.Key_Home, Qt.Key_End, Qt.Key_Delete];     mods = [null, Qt.ShiftModifier, null]; break;
        default: command = ''; return true;
      }
    }

    if (command == '') {
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
