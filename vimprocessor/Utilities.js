function debug(message) {
  console.warn('[DEBUG] Vimprocessor:   ' + message);
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
    str += "\nKeySets: ";
    for (var k in obj.keySets) {
      str += KeyName(obj.keySets[k][0]) + ', ';
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
