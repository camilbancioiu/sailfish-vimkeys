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
    commandPassthrough: false,
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

