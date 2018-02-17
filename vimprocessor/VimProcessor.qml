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
    var key = pressedKey.key;
    var text = pressedKey.text;

    command = command + text;
    Util.debug("Current command: " + command);
    var handlers = [
      handleIgnoredKeys,
      handleReplacementKeys,
      handleDeletionKeys,
      handleInsertionKeys,
      handleDevelKeys,
      handleSimpleNavigationKeys
    ];

    var handler;
    var handlerResult;
    for (var i = 0; i < handlers.length; i++) {
      handler = handlers[i];
      handlerResult = handler(command, key, text);
      if (handlerResult.commandRecognized == true) {
        Util.debugCommandHandler(handler, handlerResult, command);
        break;
      }
    }

    if (handlerResult.commandReconginzed == false || handlerResult.commandValid == false) {
      command = '';
    }

    if (handlerResult.commandRecognized) {
      if (handlerResult.commandValid) {
        if (handlerResult.commandComplete) {
          executeCommand(handlerResult, command);
          command = '';
        } else {
          Util.debug("Current command is incomplete: " + command);
        }
      } else {
        command = '';
      }
    } else {
      command = '';
    }

    if (handlerResult.commandOp == "passthrough") {
      command = '';
      return _KEYPRESS_IGNORED;
    } else {
      // Don't leak keypresses no matter what, because we're in normal mode.
      return _KEYPRESS_HANDLED;
    }
  }

  function executeCommand(handlerResult, command) {
    if (typeof handlerResult.keySets !== "undefined") {
      sendKeySets(handlerResult.keySets);
    }
    if (handlerResult.changeMode) {
      if (handlerResult.changeMode == "insert") {
        enterVimInsertMode();
      }
      if (handlerResult.changeMode == "normal") {
        enterVimNormalMode();
      }
    }
  }

  function handlerResultUnrecognized() {
    return {
      commandRecognized: false,
      commandComplete: false,
      commandValid: false,
      commandPassthrough: false
    };
  }

  function handlerResultPassthrough() {
    return {
      commandRecognized: true,
      commandComplete: true,
      commandValid: true,
      commandPassthrough: true
    };
  }

  function handlerResultChangeMode(mode) {
    return {
      commandRecognized: true,
      commandComplete: true,
      commandValid: true,
      commandPassthrough: true,
      changeMode: mode
    };
  } 

  function handlerResultCommandInvalid() {
    return {
      commandRecognized: true,
      commandComplete: false,
      commandValid: false,
      commandPassthrough: false
    };
  }

  function handlerResultSendKeySets(keySets) {
    return {
      commandRecognized: true,
      commandComplete: true,
      commandValid: true,
      commandPassthrough: false,
      keySets: keySets
    };
  }

  function handlerResultCommandComplete() {
    return {
      commandRecognized: true,
      commandComplete: true,
      commandValid: true,
      commandPassthrough: false
    };
  }

  function handlerResultCommandIncomplete() {
    return {
      commandRecognized: true,
      commandComplete: false,
      commandValid: true,
      commandPassthrough: false,
    };
  }

  function sendKeySets(keySets) {
    // Send keys.
    for (var i = 0; i < keySets.length; i++) {
      var keySet = keySets[i];
      var key = keySet[0];
      var mod = keySet[1];
      var text = keySet[2];
      if (key != null) {
        if (mod != null) {
          MInputMethodQuick.sendKey(key, mod);
        } else {
          MInputMethodQuick.sendKey(key);
        }
      } else if (text != null) {
        MInputMethodQuick.sendCommit(text);
      }
    }
  }

  function makeKeySet() {
    if (arguments.length == 0) {
      return [null, null, null];
    }
    if (arguments.length == 1) {
      return [arguments[0], null, null];
    }
    if (arguments.length == 2) {
      return [arguments[0], arguments[1], null];
    }
    if (arguments.length == 3) {
      return [arguments[0], arguments[1], arguments[2]];
    }
  }

  function normalKeySet(key, mod) {
    if (typeof mod === "undefined") {
      mod = null;
    }
    return makeKeySet(key, mod);
  }

  function textKeySet(text) {
    return makeKeySet(null, null, text);
  }

  // ======== Command handler
  // Allow default behaviour for certain keys.
  function handleIgnoredKeys(command, key, text) {
    var ignoredKeys = [Qt.Key_Enter, Qt.Key_Backspace, Qt.Key_Shift, Qt.Key_Paste,
                       Qt.Key_Return];
    if (ignoredKeys.indexOf(key) != -1) {
      return handlerResultPassthrough();
    }
    return handlerResultUnrecognized();
  }

  // ======== Command handler
  function handleSimpleNavigationKeys(command, key, text) {
    if (command.length > 1) {
      return handlerResultUnrecognized();
    }
    var navHandled = true;
    var keySets = [];
    // Basic mappings.
    switch (command) {
      case "h": keySets = [normalKeySet(Qt.Key_Left)];   break;
      case "j": keySets = [normalKeySet(Qt.Key_Down)];   break;
      case "k": keySets = [normalKeySet(Qt.Key_Up)];   break;
      case "l": keySets = [normalKeySet(Qt.Key_Right)];   break;

      case "b": keySets = [normalKeySet(Qt.Key_Left, Qt.ControlModifier)];   break;
      case "w": keySets = [normalKeySet(Qt.Key_Right, Qt.ControlModifier)];   break;

      case "0": keySets = [normalKeySet(Qt.Key_Home)];   break;
      case "$": keySets = [normalKeySet(Qt.Key_End)];   break;

      default: navHandled = false; break;
    }

    if (navHandled) {
      var handlerResult = handlerResultCommandComplete();
      handlerResult.keySets = keySets;
      return handlerResult;
    } else {
      return handlerResultUnrecognized();
    }
  }

  // ======== Command handler
  function handleInsertionKeys(command, key, text) {
    if (command == 'i') {
      return handlerResultChangeMode("insert");
    }
    if (command == 'a') {
      return handlerResultChangeMode("insert");
    }
    if (command == 'o' || command == 'O') {
      var handlerResult = handlerResultCommandComplete();
      handlerResult.changeMode = "insert";
      if (command == 'o') {
        handlerResult.keySets = [
          normalKeySet(Qt.Key_End),
          normalKeySet(Qt.Key_Return),
          normalKeySet(Qt.Key_Return),
          normalKeySet(Qt.Key_Up),
        ];
      }
      if (command == 'O') {
        handlerResult.keySets = [
          normalKeySet(Qt.Key_Home),
          normalKeySet(Qt.Key_Return),
          normalKeySet(Qt.Key_Up),
        ];
      }
      return handlerResult;
    }

    return handlerResultUnrecognized();
  }

  // ======== Command handler
  function handleDeletionKeys(command, key, text) {
    if (command == 'dd') {
      var keySets = [
        normalKeySet(Qt.Key_Home),
        normalKeySet(Qt.Key_End, Qt.ShiftModifier),
        normalKeySet(Qt.Key_Delete),
        normalKeySet(Qt.Key_Backspace)
      ];
      return handlerResultSendKeySets(keySets);
    }
    if (command == 'd') {
      return handlerResultCommandIncomplete();
    }
    if (command == 'x') {
      return handlerResultSendKeySets([normalKeySet(Qt.Key_Delete)]);
    }
    // If command starts with 'd' but hasn't been handled up to this point,
    // it must be invalid.
    if (command.length > 1 && command[0] == 'd') {
      return handlerResultCommandInvalid();
    }

    return handlerResultUnrecognized();
  }

  // ======== Command handler
  function handleReplacementKeys(command, key, text) {
    if (command == 'r') {
      return handlerResultCommandIncomplete();
    }

    if (command[0] == 'r') {
      var keySets = [
        normalKeySet(Qt.Key_Delete),
        textKeySet(command[1])
      ];
      return handlerResultSendKeySets(keySets);
    }
    return handlerResultUnrecognized();
  }


  // ======== Command handler
  function handleDevelKeys(command, key, text) {
    if (command == '?') {
      Util.testUtilities();
      return handlerResultCommandComplete();
    }

    return handlerResultUnrecognized();
  }
}
