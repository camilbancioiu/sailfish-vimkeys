.import "HandlerResults.js" as HR
.import "Utilities.js" as Util



var REWordBoundary = new RegExp('$|[ \n$]|[\-.,\/#!$%\^&\*;:{}=_`~()]');


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
function handleSpecialCommands(command, key, text) {
  if (command == 'u') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [normalKeySet(Qt.Key_Z, Qt.ControlModifier)];
    return handlerResult;
  }
  if (command == 'U') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [normalKeySet(Qt.Key_Y, Qt.ControlModifier)];
    return handlerResult;
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

    //case "b": keySets = [normalKeySet(Qt.Key_Left, Qt.ControlModifier)];   break;
    case "b": keySets = getMovementToBeginningOfWord(null);   break;
    case "w": keySets = [normalKeySet(Qt.Key_Right, Qt.ControlModifier)];   break;

    case "0": keySets = [normalKeySet(Qt.Key_Home)];   break;
    case "$": keySets = [normalKeySet(Qt.Key_End)];   break;

    case "e": keySets = getMovementToEndOfWord(null); break;

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

function getDistanceToEndOfWord(substr, immediate) {
  if (typeof substr === "undefined" || substr === false) {
    var surroundingText = MInputMethodQuick.surroundingText;
    var cursorPosition = MInputMethodQuick.cursorPosition;
    substr = surroundingText.substring(cursorPosition);
  }
  if (typeof immediate === "undefined") {
    immediate = false;
  }
  var endOfWordPos = substr.search(REWordBoundary);

  var offset = 0;
  if (endOfWordPos != -1) {
    while (endOfWordPos == 0) {
      if (substr == "" || immediate) {
        return 0;
      }
      substr = substr.substring(1);
      endOfWordPos = substr.search(REWordBoundary);
      offset += 1;
    }
    return offset + endOfWordPos;
  } else {
    return -2;
  }
}

function getDistanceToBeginningOfWord(substr, immediate) {
  if (typeof substr === "undefined" || substr === false) {
    var surroundingText = MInputMethodQuick.surroundingText;
    var cursorPosition = MInputMethodQuick.cursorPosition;
    substr = surroundingText.substring(0, cursorPosition);
  }
  if (typeof immediate === "undefined") {
    immediate = false;
  }

  // Reverse substr.
  substr = substr.split("").reverse().join("");
  return getDistanceToEndOfWord(substr, immediate);
}

function getMovementToBeginningOfWord(mod) {
  var distance = getDistanceToBeginningOfWord();

  if (distance == -2 || distance == 0) {
    return [normalKeySet(Qt.Key_Left, Qt.ControlModifier)];
  }
  return repeatKeySet(normalKeySet(Qt.Key_Left, mod), distance);
}

function getMovementToEndOfWord(mod) {
  var distance = getDistanceToEndOfWord();

  if (distance == -2 || distance == 0) {
    return [normalKeySet(Qt.Key_Right, Qt.ControlModifier)];
  }
  return repeatKeySet(normalKeySet(Qt.Key_Right, mod), distance);
}

function selectWord() {
  var distanceToBeginning = getDistanceToBeginningOfWord(false, true);
  var distanceToEnd = getDistanceToEndOfWord(false, true);

  var moveToBeginning;
  if (distanceToBeginning == -2 ) {
    moveToBeginning = [normalKeySet(Qt.Key_Left, Qt.ControlModifier)];
  } else {
    moveToBeginning = repeatKeySet(normalKeySet(Qt.Key_Left, null), distanceToBeginning);
  }

  var moveToEndWithShift;
  if (distanceToEnd == -2 ) {
    moveToEndWithShift = [normalKeySet(Qt.Key_Right, Qt.ControlModifier)];
  } else {
    moveToEndWithShift = repeatKeySet(normalKeySet(Qt.Key_Right, Qt.ShiftModifier), distanceToBeginning + distanceToEnd);
  }

  return [].concat.apply([], [moveToBeginning, moveToEndWithShift]);
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
  if (command == 'd') {
    return HR.handlerResultCommandIncomplete();
  }
  if (command == 'di') {
    return HR.handlerResultCommandIncomplete();
  }
  if (command == 'dd') {
    var keySets = [
      normalKeySet(Qt.Key_Home),
      normalKeySet(Qt.Key_End, Qt.ShiftModifier),
      normalKeySet(Qt.Key_Delete),
      normalKeySet(Qt.Key_Backspace)
    ];
    return HR.handlerResultSendKeySets(keySets);
  }
  if (command == 'de') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [].concat.apply([], [ 
      getMovementToEndOfWord(Qt.ShiftModifier)
      , [normalKeySet(Qt.Key_Delete)]
    ]);
    return handlerResult;
  }
  if (command == 'diw') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [].concat.apply([], [ 
        selectWord()
      , [normalKeySet(Qt.Key_Delete)]
    ]);
    return handlerResult;
  }
  if (command == 'D') {
    var keySets = [
      normalKeySet(Qt.Key_End, Qt.ShiftModifier),
      normalKeySet(Qt.Key_Delete),
    ];
    return HR.handlerResultSendKeySets(keySets);
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
  if (command == 'c') {
    return HR.handlerResultCommandIncomplete();
  }
  if (command == 'ci') {
    return HR.handlerResultCommandIncomplete();
  }

  if (command[0] == 'r') {
    var keySets = [
      normalKeySet(Qt.Key_Delete),
      textKeySet(command[1])
      ];
    return HR.handlerResultSendKeySets(keySets);
  }
  if (command == 'cc') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_Home),
      normalKeySet(Qt.Key_End, Qt.ShiftModifier),
      normalKeySet(Qt.Key_Delete),
      normalKeySet(Qt.Key_Backspace)
    ];
    handlerResult.changeMode = "insert";
    return handlerResult;
  }
  if (command == 'C') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_End, Qt.ShiftModifier),
      normalKeySet(Qt.Key_Delete),
    ];
    handlerResult.changeMode = "insert";
    return handlerResult;
  }

  if (command == 'ce') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.changeMode = "insert";
    handlerResult.keySets = [].concat.apply([], [ 
      getMovementToEndOfWord(Qt.ShiftModifier)
      , [normalKeySet(Qt.Key_Delete)]
    ]);
    return handlerResult;
  }
  if (command == 'ciw') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.changeMode = "insert";
    handlerResult.keySets = [].concat.apply([], [ 
        selectWord()
      , [normalKeySet(Qt.Key_Delete)]
    ]);
    return handlerResult;
  }

  // If command starts with 'c' but hasn't been handled up to this point,
  // it must be invalid.
  if (command.length > 1 && command[0] == 'c') {
    return HR.handlerResultCommandInvalid();
  }
  return HR.handlerResultUnrecognized();
}

// ======== Command handler
function handleCopyingAndPastingKeys(command, key, text) {
  if (command == 'y') {
    return HR.handlerResultCommandIncomplete();
  }
  if (command == 'p') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_Right),
      normalKeySet(Qt.Key_V, Qt.ControlModifier)
    ];
    return handlerResult;
  }
  if (command == 'P') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_V, Qt.ControlModifier)
    ];
    return handlerResult;
  }
  if (command == 'yy') {
    var handlerResult = HR.handlerResultCommandComplete();
    handlerResult.keySets = [
      normalKeySet(Qt.Key_Home),
      normalKeySet(Qt.Key_End, Qt.ShiftModifier),
      normalKeySet(Qt.Key_C, Qt.ControlModifier)
    ];
    return handlerResult;
  }
  // If command starts with 'y' but hasn't been handled up to this point,
  // it must be invalid.
  if (command.length > 1 && command[0] == 'y') {
    return HR.handlerResultCommandInvalid();
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

function repeatKeySet(key, n) {
  var keySets = [];
  for (var i = 0; i < n; i++) {
    keySets.push(key);
  }
  return keySets;
}
