#include <ModbusRTUSlave.h>

/*
  Arduino PinMap Modbus RTU Slave Firmware
  Maps board pins to Modbus Holding Registers:
    10..31    -> Pin Mode (0=Disabled, 1=INPUT, 2=INPUT_PULLUP, 3=OUTPUT, 4=PWM)
    50..71    -> Digital read/write values
    100..115  -> Analog input values (A0..A15)
    150..171  -> PWM values (0..255)
*/

#define SLAVE_ID 1
#define BAUDRATE 9600

ModbusRTUSlave modbus(Serial);

// Setup holdings array to accommodate registers up to 200
uint16_t holdingRegisters[200];
uint16_t lastMode[22]; // Track last set pin mode (D0..D13, A0..A7)

bool isProtectedPin(uint8_t pin) {
  // D0 (RX) and D1 (TX) are used by serial communication
  return pin == 0 || pin == 1;
}

bool isPWMPin(uint8_t pin) {
  // PWM pins on standard ATmega328P (Nano/Uno)
  return pin == 3 || pin == 5 || pin == 6 || pin == 9 || pin == 10 || pin == 11;
}

void setup() {
  // Initialize registers
  for (int i = 0; i < 200; i++) {
    holdingRegisters[i] = 0;
  }

  // Pre-fill pin modes as inputs
  for (int pin = 2; pin <= 21; pin++) {
    holdingRegisters[10 + pin] = 1; // 1 = INPUT
    lastMode[pin] = 1;
    pinMode(pin, INPUT);
  }

  modbus.configureHoldingRegisters(holdingRegisters, 200);

  Serial.begin(BAUDRATE);
  modbus.begin(SLAVE_ID, BAUDRATE);
}

void loop() {
  // 1. Update analog inputs to registers (A0..A7 on Nano mapped to Pin 14..21)
  for (int i = 0; i < 8; i++) {
    holdingRegisters[100 + i] = analogRead(i);
  }

  // 2. Update digital inputs to registers
  for (int pin = 2; pin <= 21; pin++) {
    uint16_t mode = holdingRegisters[10 + pin];
    if (mode == 1 || mode == 2) {
      holdingRegisters[50 + pin] = digitalRead(pin);
    }
  }

  // 3. Process Modbus request
  modbus.poll();

  // 4. Actuate outputs based on registers
  for (int pin = 2; pin <= 21; pin++) {
    if (isProtectedPin(pin)) continue;

    uint16_t mode = holdingRegisters[10 + pin];

    // Detect Pin Mode changes
    if (mode != lastMode[pin]) {
      switch (mode) {
        case 0: // Disabled
          pinMode(pin, INPUT);
          break;
        case 1: // INPUT
          pinMode(pin, INPUT);
          break;
        case 2: // INPUT_PULLUP
          pinMode(pin, INPUT_PULLUP);
          break;
        case 3: // OUTPUT
          pinMode(pin, OUTPUT);
          break;
        case 4: // PWM
          if (isPWMPin(pin)) {
            pinMode(pin, OUTPUT);
          } else {
            holdingRegisters[10 + pin] = 1; // Revert to INPUT if PWM not supported
            pinMode(pin, INPUT);
          }
          break;
      }
      lastMode[pin] = mode;
    }

    // Write digital value if output
    if (mode == 3) {
      digitalWrite(pin, holdingRegisters[50 + pin] ? HIGH : LOW);
    }

    // Write PWM value if PWM mode
    if (mode == 4 && isPWMPin(pin)) {
      analogWrite(pin, holdingRegisters[150 + pin] & 0xFF);
    }
  }
}
