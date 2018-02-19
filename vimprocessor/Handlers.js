.import "HandlerResults.js" as HR
.import "Utilities.js" as Util

// ======== Command handler
// Allow default behaviour for certain keys.
function handleIgnoredKeys(command, key, text) {
  var ignoredKeys = [Qt.Key_Enter, Qt.Key_Backspace, Qt.Key_Shift, Qt.Key_Paste,
      Qt.Key_Return];
  if (ignoredKeys.indexOf(key) != -1) {
    return HR.handlerResultPassthrough();
  }
  return HR.handlerResultUnrecognized();
}

// ======== Command handler
function handleSimpleNavigationKeys(command, key, text) {
  if (command.length > 1) {
    return HR.handlerResultUnrecognized();
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
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = keySets;
    return handlerResult;
  } else {
    return HR.handlerResultUnrecognized();
  }
}

// ======== Command handler
function handleInsertionKeys(command, key, text) {
  if (command == 'i') {
    return HR.handlerResultChangeMode("insert");
  }
  if (command == 'a') {
    return HR.handlerResultChangeMode("insert");
  }
  if (command == 'I') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_Home)
      ];
    handlerResult.changeMode = "insert";
    return handlerResult;
  }
  if (command == 'A') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_End)
      ];
    handlerResult.changeMode = "insert";
    return handlerResult;
  }
  if (command == 'o' || command == 'O') {
    var handlerResult = HR.handlerResultCommandComplete();
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

  return HR.handlerResultUnrecognized();
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
    return HR.handlerResultSendKeySets(keySets);
  }
  if (command == 'd') {
    return HR.handlerResultCommandIncomplete();
  }
  if (command == 'x') {
    return HR.handlerResultSendKeySets([normalKeySet(Qt.Key_Delete)]);
  }
  // If command starts with 'd' but hasn't been handled up to this point,
  // it must be invalid.
  if (command.length > 1 && command[0] == 'd') {
    return HR.handlerResultCommandInvalid();
  }

  return HR.handlerResultUnrecognized();
}

// ======== Command handler
function handleReplacementKeys(command, key, text) {
  if (command == 'r') {
    return HR.handlerResultCommandIncomplete();
  }

  if (command[0] == 'r') {
    var keySets = [
      normalKeySet(Qt.Key_Delete),
    textKeySet(command[1])
      ];
    return HR.handlerResultSendKeySets(keySets);
  }
  return HR.handlerResultUnrecognized();
}


// ======== Command handler
function handleDevelKeys(command, key, text) {
  if (command == '?') {
    Util.testUtilities();
    return HR.handlerResultCommandComplete();
  }

  return HR.handlerResultUnrecognized();
}


// ===========================================
// KeySet utilities.
// ===========================================
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
