import 'dart:developer' as dev;

void logInfo(String message) {
  dev.log(message, name: 'INFO');
}

void logError(String message) {
  dev.log(message, name: 'ERROR');
}
