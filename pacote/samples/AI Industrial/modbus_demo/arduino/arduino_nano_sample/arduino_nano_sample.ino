#include <ModbusRTUSlave.h>

/*
  Arduino Nano como módulo I/O Modbus RTU via USB/Serial

  Mapa:
    Coils[0..13]              = escrita digital D0..D13
    DiscreteInputs[0..13]     = leitura digital D0..D13
    HoldingRegisters[0..13]   = modo dos pinos D0..D13
    HoldingRegisters[20..33]  = PWM dos pinos D0..D13
    InputRegisters[0..7]      = leitura analógica A0..A7

  Modos:
    0 = desativado / INPUT
    1 = INPUT
    2 = INPUT_PULLUP
    3 = OUTPUT
    4 = PWM

  Observação:
    D0 e D1 são usados pela Serial USB no Nano.
    Não use D0/D1 como I/O normal neste firmware.
*/

#define SLAVE_ID 1
#define BAUDRATE 9600

ModbusRTUSlave modbus(Serial);

bool coils[14];
bool discreteInputs[14];

uint16_t holdingRegisters[40];
uint16_t inputRegisters[8];

uint16_t lastMode[14];

bool isProtectedPin(uint8_t pin) {
  // D0 RX e D1 TX são usados pela Serial USB.
  return pin == 0 || pin == 1;
}

bool isPWMPin(uint8_t pin) {
  // PWM no Arduino Nano clássico:
  return pin == 3 || pin == 5 || pin == 6 || pin == 9 || pin == 10 || pin == 11;
}

void setup() {
  for (uint8_t i = 0; i < 14; i++) {
    coils[i] = false;
    discreteInputs[i] = false;
    holdingRegisters[i] = 0;
    lastMode[i] = 999;
  }

  for (uint8_t i = 20; i < 34; i++) {
    holdingRegisters[i] = 0;
  }

  for (uint8_t i = 0; i < 8; i++) {
    inputRegisters[i] = 0;
  }

  modbus.configureCoils(coils, 14);
  modbus.configureDiscreteInputs(discreteInputs, 14);
  modbus.configureHoldingRegisters(holdingRegisters, 40);
  modbus.configureInputRegisters(inputRegisters, 8);

  Serial.begin(BAUDRATE);
  modbus.begin(SLAVE_ID, BAUDRATE);
}

void loop() {
  atualizarEntradas();

  modbus.poll();

  aplicarSaidas();
}

void atualizarEntradas() {
  for (uint8_t pin = 0; pin < 14; pin++) {
    if (!isProtectedPin(pin)) {
      discreteInputs[pin] = digitalRead(pin);
    } else {
      discreteInputs[pin] = false;
    }
  }

  inputRegisters[0] = analogRead(A0);
  inputRegisters[1] = analogRead(A1);
  inputRegisters[2] = analogRead(A2);
  inputRegisters[3] = analogRead(A3);
  inputRegisters[4] = analogRead(A4);
  inputRegisters[5] = analogRead(A5);
  inputRegisters[6] = analogRead(A6);
  inputRegisters[7] = analogRead(A7);
}

void aplicarSaidas() {
  for (uint8_t pin = 0; pin < 14; pin++) {
    if (isProtectedPin(pin)) {
      continue;
    }

    uint16_t modo = holdingRegisters[pin];

    if (modo != lastMode[pin]) {
      configurarModo(pin, modo);
      lastMode[pin] = modo;
    }

    if (modo == 3) {
      digitalWrite(pin, coils[pin] ? HIGH : LOW);
    }

    if (modo == 4) {
      if (isPWMPin(pin)) {
        uint16_t pwm = holdingRegisters[20 + pin];

        if (pwm > 255) {
          pwm = 255;
          holdingRegisters[20 + pin] = 255;
        }

        analogWrite(pin, pwm);
      } else {
        holdingRegisters[20 + pin] = 0;
      }
    }
  }
}

void configurarModo(uint8_t pin, uint16_t modo) {
  switch (modo) {
    case 0:
      pinMode(pin, INPUT);
      break;

    case 1:
      pinMode(pin, INPUT);
      break;

    case 2:
      pinMode(pin, INPUT_PULLUP);
      break;

    case 3:
      pinMode(pin, OUTPUT);
      break;

    case 4:
      if (isPWMPin(pin)) {
        pinMode(pin, OUTPUT);
      } else {
        holdingRegisters[pin] = 0;
        pinMode(pin, INPUT);
      }
      break;

    default:
      holdingRegisters[pin] = 0;
      pinMode(pin, INPUT);
      break;
  }
}
