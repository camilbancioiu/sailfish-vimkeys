import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0 as Silica
import "."
import "utilities.js" as Util

Item {
  property string vimMode : "insert";
  property bool switching : false;
  property var indicator : ({});
  property string command : "";
  property bool enabled: true;

  property bool _KEYPRESS_HANDLED: true;
  property bool _KEYPRESS_IGNORED: false;

  Component.onCompleted: {
    var statusIndicatorComponent = Qt.createComponent("VimProcessorStatusIndicator.qml");
    indicator = statusIndicatorComponent.createObject(keyboard);
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
      if (vimMode == "normal") {
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
    if (!enabled) return _KEYPRESS_IGNORED;

    var vimModeSwitched = handleVimModeSwitching_ShiftSpace(pressedKey);
    if (switching) {
      return _KEYPRESS_HANDLED;
    }

    if (vimModeSwitched) {
      return _KEYPRESS_HANDLED;
    } 

    if (vimMode == "insert") {
      return _KEYPRESS_IGNORED;
    } 
    
    if (vimMode == "normal") {
      if (pressedKey.key != Qt.Key_Shift) {
        keyboard.shiftState = ShiftState.NoShift;
      } 
      return handleVimNormalModeKeys(pressedKey);
    }
  }

  function handleVimModeSwitching_DoubleTapSpace(pressedKey) {
    if (pressedKey.key == Qt.Key_Space) {
      Util.debug("keyboard.shiftKeyPressed: " + keyboard.shiftKeyPressed);
      if (switching) {
        if (vimMode == "normal") {
          enterVimInsertMode();
        } else {
          enterVimNormalMode();
        }
        return _KEYPRESS_HANDLED;
      } else {
        vimModeKeyTriggerTimer.start();
        switching = true;
        return _KEYPRESS_IGNORED;
      }
    }
    return _KEYPRESS_IGNORED;
  }

  function handleVimModeSwitching_ShiftSpace(pressedKey) {
    var _MODE_SWITCHED = true;
    var _MODE_NOT_SWITCHED = false;
    switching = false;
    if (pressedKey.key == Qt.Key_Space && keyboard.shiftKeyPressed) {
      Util.debug("keyboard.shiftKeyPressed: " + keyboard.shiftKeyPressed);
      if (vimMode == "normal") {
        enterVimInsertMode();
      } else {
        enterVimNormalMode();
      }
      return _MODE_SWITCHED;
    }
    return _MODE_NOT_SWITCHED;
  }

  function enterVimNormalMode() {
    resetParentInputHandler(); 
    keyboard.autocaps = false;
    keyboard.resetShift();
    vimMode = "normal";
    command = "";
    switching = false;
    antiAutocapsTimer.start();
    Util.debug("Entered normal mode.");
  }

  function enterVimInsertMode() {
    resetParentInputHandler(); 
    keyboard.resetShift();
    vimMode = "insert";
    command = "";
    switching = false;
    Util.debug("Entered insert mode.");
  }

  // See InputHandler._reset().
  function resetParentInputHandler() {
    autorepeatTimer.stop()
    multitap.flush()
    reset()
  }

  function handleVimNormalModeKeys(pressedKey) {
    var state = {
      // Flag set by a command handler, if it has handled the input.
      // All further handlers will be skipped.
      handled: false,

      // Array of keys to be sent if the input has been handled.
      keys: [],

      // Array of key modifiers to be sent if the input has been handled.
      // Must match they "keys" array element-by-element 
      // (i.e. one modifier for each key).
      mods: [],

      // Array of texts to be sent if the input has been handled. 
      // Must match the "keys" array element-by-element
      // (i.e. one modifier for each key).
      // Only sent if the corresponding element in the "keys" array is "null".
      texts: [],

      // Value set by command handlers, if they want to change the Vim mode.
      setVimMode: null,

      returnValue: _KEYPRESS_IGNORED   
    };

    state = handleIgnoredKeys(pressedKey, state);
    state = handleInsertionKeys(pressedKey, state);
    state = handleSimpleNavigationKeys(pressedKey, state);
    state = handleReplacementKeys(pressedKey, state);
    state = handleDeletionKeys(pressedKey, state);
    state = handleDevelKeys(pressedKey, state);

    sendKeys(state.keys, state.mods, state.texts);

    if (state.setVimMode != null) {
      if (state.setVimMode == "insert") {
        enterVimInsertMode();
      }
      if (state.setVimMode == "normal") {
        enterVimNormalMode();
      }
    }
    
    if (state.returnValue) {
      Util.debugPressedKey("Handled.", pressedKey);
    } else {
      Util.debugPressedKey("Not handled.", pressedKey);
    }

    state = defaultBlocker(pressedKey, state);
    return state.returnValue;
  }

  // ======== Command handler
  // Block all unhandled keys, by default. 
  // Thus in "normal" mode, no keys will be sent to the app,
  // unless a command handler explicitly decides to.
  function defaultBlocker(pressedKey, state) {
    if (state.handled) return state;

    if (state.handled == false) {
      return handled([], [], [], _KEYPRESS_HANDLED);
    }
  }

  // ======== Command handler
  // Allow default behaviour for certain keys.
  function handleIgnoredKeys(pressedKey, state) {
    if (state.handled) return state;

    var ignoredKeys = [Qt.Key_Enter, Qt.Key_Backspace, Qt.Key_Shift, Qt.Key_Paste];
    if (ignoredKeys.indexOf(pressedKey.key) != -1) {
      return handled([], [], [], _KEYPRESS_IGNORED);
    }
    return unhandled();
  }

  // ======== Command handler
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
      var texts = [];
      for (var i = 0; i < keys.length; i++) {
        texts.push(null);
      }

      if (navHandled) {
        return handled(keys, mods, texts, _KEYPRESS_HANDLED);
      } else {
        return unhandled();
      }
    } else {
      return unhandled();
    }
  }

  // ======== Command handler
  function handleInsertionKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == '') {
      if (pressedKey.text == 'i') {
        state = handled([], [], [], _KEYPRESS_HANDLED);
        state.setVimMode = "insert";
        return state;
      }
      if (pressedKey.text == 'a') {
        state = handled([Qt.Key_Right], [null], [null], _KEYPRESS_HANDLED);
        state.setVimMode = "insert";
        return state;
      }
    }

    return unhandled();
  }

  // ======== Command handler
  function handleDeletionKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == 'd') {
      if (pressedKey.text == 'd') {
        command = '';
        return handled(
          [Qt.Key_Home, Qt.Key_End, Qt.Key_Delete, Qt.Key_Backspace],
          [null, Qt.ShiftModifier, null, null], 
          [null, null, null, null], 
          _KEYPRESS_HANDLED);
      } else {
        command = '';
        return unhandled();
      }
    }
    if (command == '') {
      if (pressedKey.text == 'd') {
        command = 'd';
        return handled([], [], [], _KEYPRESS_HANDLED);
      }
      if (pressedKey.text == 'x') {
        return handled([Qt.Key_Delete], [null], [null], _KEYPRESS_HANDLED);
      }
    }

    return unhandled();
  }

  // ======== Command handler
  function handleReplacementKeys(pressedKey, state) {
    if (state.handled) return state;

    if (command == 'r') {
      command = '';
      return handled(
        [Qt.Key_Delete, null],
        [null, null],
        [null, pressedKey.text],
        _KEYPRESS_HANDLED);
    }
    if (command == '') {
      if (pressedKey.text == 'r') {
        command = 'r';
        return handled([], [], [], _KEYPRESS_HANDLED);
      }
    }
    return unhandled();
  }


  // ======== Command handler
  function handleDevelKeys(pressedKey, state) {
    if (state.handled) return state;

    if (pressedKey.text == '?') {
      Util.testUtilities();
    }

    return unhandled();
  }

  // Helper to create state objects returned by handlers.
  function unhandled() {
    return {handled: false, keys: [], mods: [], texts: [], returnValue: _KEYPRESS_IGNORED, setVimMode: false };
  }
  
  function handled(k, m, t, rv) {
    return {handled: true, keys: k, mods: m, texts: t, returnValue: rv, setVimMode: false };
  }

  function sendKeys(keys, mods, texts) {
    // Send keys.
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] != null) {
        if (mods[i] != null) {
          MInputMethodQuick.sendKey(keys[i], mods[i]);
        } else {
          MInputMethodQuick.sendKey(keys[i]);
        }
      } else if (texts[i] != null) {
        MInputMethodQuick.sendCommit(texts[i]);
      }
    }
  }
}
