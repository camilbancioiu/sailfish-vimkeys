function debug(message) {
  console.warn('[DEBUG] VimKeys:   ' + message);
}

function debugPressedKey(message, pressedKey) {
  debug('Keypress [' + KeyName(pressedKey.key) + '] {' + pressedKey.text + '} :: ' + message);
}

function debugCommandHandler(handler, handlerResult, command) {
  debug('Handler "' + handler.name + '", c['+command+'] {'+handlerToString(handlerResult)+'}');
}

function testUtilities() {
  debug("Test utilities.");
  debug("Test KeyName: " + KeyName(Qt.Key_Backspace));
}

function KeyName(key) {
  if (key == null) {
    return "null";
  }
  for (var property in Qt) {
    if (Qt.hasOwnProperty(property)) {
      if (Qt[property] == key) {
        return property;
      }
    }
  }
  return "";
}

function handlerToString (obj) {
  var str = '';
  for (var p in obj) {
    if (obj.hasOwnProperty(p)) {
      if (p == 'keySets') {
        continue;
      }
      str += p + '=' + obj[p] + ', ';
    }
  }
  if (obj.hasOwnProperty('keySets')) {
    str += "\nKeySets: \n";
    for (var k in obj.keySets) {
      var keySetName = KeyName(obj.keySets[k][0]);
      var keySetModifier = "none";
      switch (obj.keySets[k][1]) {
        case Qt.ShiftModifier: keySetModifier = "Shift"; break;
        case Qt.ControlModifier: keySetModifier = "Ctrl"; break;
        case Qt.ShiftModifier | Qt.ControlModifier: keySetModifier = "CtrlShift"; break;
      }
      str += "(" + keySetName + ', ' + keySetModifier + ')\n';
    }
  }
  return str;
}

function objToString (obj) {
  var str = '';
  for (var p in obj) {
    if (obj.hasOwnProperty(p)) {
      str += p + '=' + obj[p] + ', ';
    }
  }
  return str;
}
