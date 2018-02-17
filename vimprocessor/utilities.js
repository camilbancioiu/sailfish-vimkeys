function debug(message) {
  console.warn('[DEBUG] Vimprocessor:   ' + message);
}

function debugPressedKey(message, pressedKey) {
  debug('Keypress [' + KeyName(pressedKey.key) + '] {' + pressedKey.text + '} :: ' + message);
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
