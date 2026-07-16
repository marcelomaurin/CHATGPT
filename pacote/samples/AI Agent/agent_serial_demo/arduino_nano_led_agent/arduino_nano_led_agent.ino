// Device de demonstração para o Agent Serial Demo.
// Placa alvo: Arduino Nano com ATmega328P.

const uint8_t LED_PIN = LED_BUILTIN;
const uint8_t ANALOG_PIN = A0;
const unsigned long SERIAL_BAUD = 115200UL;
const size_t MAX_COMMAND_LENGTH = 63;

char commandBuffer[MAX_COMMAND_LENGTH + 1];
size_t commandLength = 0;
bool discardUntilNewline = false;
bool ledState = false;

void setLed(const bool enabled) {
  ledState = enabled;
  digitalWrite(LED_PIN, enabled ? HIGH : LOW);
}

void sendLEDState() {
  Serial.print(F("STATE LED="));
  if (digitalRead(LED_PIN) == HIGH) {
    Serial.println(F("ON"));
  } else {
    Serial.println(F("OFF"));
  }
}

void executeLEDCommand(const bool enabled) {
  setLed(enabled);
  if (enabled) {
    Serial.println(F("OK LEDON"));
  } else {
    Serial.println(F("OK LEDOFF"));
  }
  sendLEDState();
}

void printManual() {
  Serial.println(F("MAN-BEGIN"));
  Serial.println(F("DEVICE: Arduino Nano Agent Serial Device"));
  Serial.println(F("MANUAL-VERSION: 1.1"));
  Serial.println(F("PROTOCOL: send exactly one ASCII command per line"));
  Serial.println(F("LINE-END: every command must end with LF or CRLF"));
  Serial.println(F("BAUD: 115200 8N1"));
  Serial.println(F("CASE: command names are case-insensitive"));
  Serial.println(F("PARAMETERS: none of the commands below accept parameters"));
  Serial.println(F("COMMAND MAN: syntax=MAN; parameters=none; returns=this manual from MAN-BEGIN through MAN-END"));
  Serial.println(F("COMMAND HELP: syntax=HELP; parameters=none; alias=MAN; returns=this manual"));
  Serial.println(F("COMMAND PING: syntax=PING; parameters=none; returns=OK PONG"));
  Serial.println(F("COMMAND ID?: syntax=ID?; parameters=none; returns=OK ID <device> VERSION=<version>"));
  Serial.println(F("COMMAND STATUS?: syntax=STATUS?; parameters=none; returns=OK STATUS LED=<ON|OFF> A0=<0..1023> UPTIME_MS=<number>"));
  Serial.println(F("COMMAND LEDON: syntax=LEDON; parameters=none; effect=turn built-in LED on; returns=OK LEDON then STATE LED=ON"));
  Serial.println(F("COMMAND LEDOFF: syntax=LEDOFF; parameters=none; effect=turn built-in LED off; returns=OK LEDOFF then STATE LED=OFF"));
  Serial.println(F("COMMAND LED?: syntax=LED?; parameters=none; returns=STATE LED=<ON|OFF>"));
  Serial.println(F("COMMAND A0?: syntax=A0?; parameters=none; returns=OK A0=<raw ADC value 0..1023>"));
  Serial.println(F("ERRORS: unknown command returns ERROR UNKNOWN_COMMAND; USE MAN"));
  Serial.println(F("RULE: never append arguments to commands whose parameters are none"));
  Serial.println(F("MAN-END"));
}

void printStatus() {
  Serial.print(F("OK STATUS LED="));
  Serial.print(ledState ? F("ON") : F("OFF"));
  Serial.print(F(" A0="));
  Serial.print(analogRead(ANALOG_PIN));
  Serial.print(F(" UPTIME_MS="));
  Serial.println(millis());
}

void normalizeCommand(char *text) {
  for (size_t i = 0; text[i] != '\0'; ++i) {
    if ((text[i] >= 'a') && (text[i] <= 'z')) {
      text[i] = static_cast<char>(text[i] - ('a' - 'A'));
    }
  }
}

void executeCommand(char *command) {
  normalizeCommand(command);

  if ((strcmp(command, "MAN") == 0) || (strcmp(command, "HELP") == 0)) {
    printManual();
  } else if (strcmp(command, "PING") == 0) {
    Serial.println(F("OK PONG"));
  } else if (strcmp(command, "ID?") == 0) {
    Serial.println(F("OK ID ARDUINO_NANO_AGENT_SERIAL VERSION=1.1"));
  } else if (strcmp(command, "STATUS?") == 0) {
    printStatus();
  } else if (strcmp(command, "LEDON") == 0) {
    executeLEDCommand(true);
  } else if (strcmp(command, "LEDOFF") == 0) {
    executeLEDCommand(false);
  } else if (strcmp(command, "LED?") == 0) {
    sendLEDState();
  } else if (strcmp(command, "A0?") == 0) {
    Serial.print(F("OK A0="));
    Serial.println(analogRead(ANALOG_PIN));
  } else if (command[0] != '\0') {
    Serial.println(F("ERROR UNKNOWN_COMMAND; USE MAN"));
  }
}

void finishCommand() {
  if (discardUntilNewline) {
    discardUntilNewline = false;
    commandLength = 0;
    return;
  }

  commandBuffer[commandLength] = '\0';
  executeCommand(commandBuffer);
  commandLength = 0;
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  setLed(false);
  Serial.begin(SERIAL_BAUD);
  Serial.println(F("READY ARDUINO_NANO_AGENT_SERIAL; SEND MAN"));
}

void loop() {
  while (Serial.available() > 0) {
    const char received = static_cast<char>(Serial.read());

    if (received == '\n') {
      finishCommand();
    } else if (received != '\r') {
      if (discardUntilNewline) {
        continue;
      }

      if (commandLength < MAX_COMMAND_LENGTH) {
        commandBuffer[commandLength++] = received;
      } else {
        commandLength = 0;
        discardUntilNewline = true;
        Serial.println(F("ERROR COMMAND_TOO_LONG"));
      }
    }
  }
}
