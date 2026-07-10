const uint8_t LED_PIN = 13;

String commandBuffer;

void printManual() {
  Serial.println(F("MAN-BEGIN"));
  Serial.println(F("DEVICE: Arduino Mega LED controller"));
  Serial.println(F("BAUD: 115200"));
  Serial.println(F("OUTPUT: built-in LED on digital pin 13"));
  Serial.println(F("COMMAND LEDON: set pin 13 HIGH and turn the LED on"));
  Serial.println(F("COMMAND LEDOFF: set pin 13 LOW and turn the LED off"));
  Serial.println(F("COMMAND MAN: return this firmware operation manual"));
  Serial.println(F("RULE: commands are case-insensitive and end with LF or CRLF"));
  Serial.println(F("RESPONSE LEDON: OK LEDON"));
  Serial.println(F("RESPONSE LEDOFF: OK LEDOFF"));
  Serial.println(F("RESPONSE UNKNOWN: ERROR UNKNOWN COMMAND; USE MAN"));
  Serial.println(F("MAN-END"));
}

void executeCommand(String command) {
  command.trim();
  command.toUpperCase();

  if (command == "LEDON") {
    digitalWrite(LED_PIN, HIGH);
    Serial.println(F("OK LEDON"));
  } else if (command == "LEDOFF") {
    digitalWrite(LED_PIN, LOW);
    Serial.println(F("OK LEDOFF"));
  } else if (command == "MAN") {
    printManual();
  } else if (command.length() > 0) {
    Serial.println(F("ERROR UNKNOWN COMMAND; USE MAN"));
  }
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  Serial.begin(115200);
  commandBuffer.reserve(32);
  Serial.println(F("READY; SEND MAN"));
}

void loop() {
  while (Serial.available() > 0) {
    const char received = static_cast<char>(Serial.read());
    if (received == '\n') {
      executeCommand(commandBuffer);
      commandBuffer = "";
    } else if (received != '\r') {
      if (commandBuffer.length() < 31) {
        commandBuffer += received;
      } else {
        commandBuffer = "";
        Serial.println(F("ERROR COMMAND TOO LONG"));
      }
    }
  }
}
