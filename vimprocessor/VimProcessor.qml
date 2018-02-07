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
    switching = false;
    antiAutocapsTimer.start();
  }

  function enterVimInsertMode() {
    resetParentInputHandler(); 
    keyboard.resetShift();
    vimMode = "insert";
    command = "";
    switching = false;
  }

  // See InputHandler._reset().
  function resetParentInputHandler() {
    autorepeatTimer.stop()
    multitap.flush()
    reset()
  }

  function handleVimNormalModeKeys(pressedKey) {
    var state = {
      handled: false,
      keys: [],
      mods: [],
      setVimMode: null,
      returnValue: false
    };

    state = handleIgnoredKeys(pressedKey, state);
    state = handleInsertionKeys(pressedKey, state);
    state = handleSimpleNavigationKeys(pressedKey, state);
    state = handleDeletionKeys(pressedKey, state);

    sendKeys(state.keys, state.mods);

    if (state.setVimMode != null) {
      if (state.setVimMode == "insert") {
        enterVimInsertMode();
      }
      if (state.setVimMode == "normal") {
        enterVimNormalMode();
      }
    }

    return state.returnValue;
  }

  function handleIgnoredKeys(pressedKey, state) {
    if (state.handled) return state;

    // Allow default behaviour for the following keys.
    var ignoredKeys = [Qt.Key_Enter, Qt.Key_Backspace];
    if (ignoredKeys.indexOf(pressedKey.key) != -1) {
      return handled([], [], false);
    }
    return unhandled();
  }

  function handleSimpleNavigationKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == '') {
      var navHandled = true;
      var keys = [];
      var mods = [];
      // Basic mappings.
      switch (pressedKey.text) {
        case "h": keys = [Qt.Key_Left];     mods = [null]; break;
        case "j": keys = [Qt.Key_Down];     mods = [null]; break;
        case "k": keys = [Qt.Key_Up];       mods = [null]; break;
        case "l": keys = [Qt.Key_Right];    mods = [null]; break;
        case "b": keys = [Qt.Key_Left];     mods = [Qt.ControlModifier]; break;
        case "w": keys = [Qt.Key_Right];    mods = [Qt.ControlModifier]; break;
        case "0": keys = [Qt.Key_Home];     mods = [null]; break;
        case "$": keys = [Qt.Key_End];    mods = [null]; break;

        default: navHandled = false; break;
      }
      if (navHandled) {
        return handled(keys, mods, true);
      } else {
        return unhandled();
      }
    } else {
      return unhandled();
    }
  }

  function handleInsertionKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == '') {
      if (pressedKey.text == 'i') {
        state = handled([], [], true);
        state.setVimMode = "insert";
        return state;
      }
      if (pressedKey.text == 'a') {
        state = handled([Qt.Key_Right], [null], true);
        state.setVimMode = "insert";
        return state;
      }
    }

    return unhandled();
  }

  function handleDeletionKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == 'd') {
      if (pressedKey.text == 'd') {
        return handled(
          [Qt.Key_Home, Qt.Key_End, Qt.Key_Delete],
          [null, Qt.ShiftModifier, null], 
          true);
      }
      command = '';
      return unhandled();
    }
    if (command == '') {
      if (pressedKey.text == 'd') {
        command = 'd';
        return handled([], [], true);
      }
      if (pressedKey.text == 'x') {
        return handled([Qt.Key_Delete], [null], true);
      }
    }

    return unhandled();
  }

  function unhandled() {
    return {handled: false, keys: [], mods: [], returnValue: false };
  }
  
  function handled(k, m, rv) {
    return {handled: true, keys: k, mods: m, returnValue: rv};
  }

  function sendKeys(keys, mods) {
    // Send keys.
    for (var i = 0; i < keys.length; i++) {
      if (mods[i] != null) {
        MInputMethodQuick.sendKey(keys[i], mods[i]);
      } else {
        MInputMethodQuick.sendKey(keys[i]);
      }
    }
  }
}
