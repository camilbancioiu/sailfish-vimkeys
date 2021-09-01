import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0 as Silica
import "."
import "Utilities.js" as Util
import "Handlers.js" as Handlers

Item {
  property string vimMode : "insert";
  property bool switching : false;
  property var indicator : ({});
  property string command : "";
  property bool enabled: true;
  property string visual: "off";

  property bool _KEYPRESS_HANDLED: true;
  property bool _KEYPRESS_IGNORED: false;

  Component.onCompleted: {
    var statusIndicatorComponent = Qt.createComponent("VimKeysStatusIndicator.qml");
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
    visual = "off";
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
    if (pressedKey.key == Qt.Key_Space && keyboard.shiftState == ShiftState.LatchedShift) {
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
    visual = "off";
    command = "";
    switching = false;
    antiAutocapsTimer.start();
    Util.debug("Entered normal mode.");
  }

  function enterVimInsertMode() {
    resetParentInputHandler(); 
    keyboard.resetShift();
    vimMode = "insert";
    visual = "off";
    command = "";
    switching = false;
    Util.debug("Entered insert mode.");
  }

  // See InputHandler._reset().
  function resetParentInputHandler() {
    autorepeatTimer.stop()
    multitap.flush()
    reset()
    if (typeof preedit !== "undefined") {
      MInputMethodQuick.sendCommit(preedit);
      preedit = "";
    }
  }

  function handleVimNormalModeKeys(pressedKey) {
    var key = pressedKey.key;
    var text = pressedKey.text;

    command = command + text;
    Util.debug("Current command: " + command);
    var handlers = [
      Handlers.handleIgnoredKeys,
      Handlers.handleSpecialCommands,
      Handlers.handleVisualMode,
      Handlers.handleReplacementKeys,
      Handlers.handleDeletionKeys,
      Handlers.handleInsertionKeys,
      Handlers.handleCopyingAndPastingKeys,
      Handlers.handleDevelKeys,
      Handlers.handleSimpleNavigationKeys,
      Handlers.handleMacroNavigationKeys
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

    if (handlerResult.commandPassthrough == true) {
      command = '';
      return _KEYPRESS_IGNORED;
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

    // Don't leak keypresses no matter what, because we're in normal mode.
    return _KEYPRESS_HANDLED;
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
      if (handlerResult.changeMode == "visualSimple") {
        visual = "simple";
      }
      if (handlerResult.changeMode == "visualLine") {
        visual = "line";
      }
      if (handlerResult.changeMode == "visualOff") {
        visual = "off";
      }
    }
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

}
