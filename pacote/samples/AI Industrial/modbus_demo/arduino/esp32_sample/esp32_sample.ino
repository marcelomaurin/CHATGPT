#include <ModbusRTUSlave.h>

/*
  ESP32 como módulo I/O Modbus RTU via USB/Serial

  Mapa:
    Coils[0..NUM_PINS-1]              = escrita digital
    DiscreteInputs[0..NUM_PINS-1]     = leitura digital
    HoldingRegisters[0..NUM_PINS-1]   = modo dos pinos
    HoldingRegisters[40..40+NUM_PINS-1] = PWM dos pinos
    InputRegisters[0..5]              = leitura analógica (pinos ADC1: 32, 33, 34, 35, 36, 39)

  Modos:
    0 = desativado / INPUT
    1 = INPUT
    2 = INPUT_PULLUP
    3 = OUTPUT
    4 = PWM (apenas pinos suportados/não-input-only)

  Observações para ESP32:
    - Pinos 34, 35, 36 e 39 são INPUT ONLY (não suportam OUTPUT nem PULLUP interno).
    - Evitamos pinos de flash SPI (6..11) e Serial0 (1, 3).
*/

#define SLAVE_ID 1
#define BAUDRATE 9600

// Lista de GPIOs válidos e seguros para o ESP32 DevKit
const uint8_t pinsMap[] = {
  2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34, 35, 36, 39
};
#define NUM_PINS (sizeof(pinsMap) / sizeof(pinsMap[0]))

// Mapeamento dos canais analógicos (ADC1)
const uint8_t adcMap[] = {
  32, 33, 34, 35, 36, 39
};
#define NUM_ADC (sizeof(adcMap) / sizeof(adcMap[0]))

ModbusRTUSlave modbus(Serial);

bool coils[NUM_PINS];
bool discreteInputs[NUM_PINS];

uint16_t holdingRegisters[100];
uint16_t inputRegisters[NUM_ADC];

uint16_t lastMode[NUM_PINS];

bool isInputOnlyPin(uint8_t pin) {
  // GPIOs 34..39 no ESP32 são apenas de entrada
  return pin == 34 || pin == 35 || pin == 36 || pin == 39;
}

void setup() {
  for (uint8_t i = 0; i < NUM_PINS; i++) {
    coils[i] = false;
    discreteInputs[i] = false;
    holdingRegisters[i] = 0;
    lastMode[i] = 999;
  }

  for (uint8_t i = 40; i < 40 + NUM_PINS; i++) {
    holdingRegisters[i] = 0;
  }

  for (uint8_t i = 0; i < NUM_ADC; i++) {
    inputRegisters[i] = 0;
  }

  modbus.configureCoils(coils, NUM_PINS);
  modbus.configureDiscreteInputs(discreteInputs, NUM_PINS);
  modbus.configureHoldingRegisters(holdingRegisters, 100);
  modbus.configureInputRegisters(inputRegisters, NUM_ADC);

  Serial.begin(BAUDRATE);
  modbus.begin(SLAVE_ID, BAUDRATE);
}

void loop() {
  atualizarEntradas();

  modbus.poll();

  aplicarSaidas();
}

void atualizarEntradas() {
  for (uint8_t i = 0; i < NUM_PINS; i++) {
    uint8_t pin = pinsMap[i];
    discreteInputs[i] = digitalRead(pin);
  }

  for (uint8_t i = 0; i < NUM_ADC; i++) {
    inputRegisters[i] = analogRead(adcMap[i]);
  }
}

void aplicarSaidas() {
  for (uint8_t i = 0; i < NUM_PINS; i++) {
    uint8_t pin = pinsMap[i];
    uint16_t modo = holdingRegisters[i];

    if (modo != lastMode[i]) {
      configurarModo(pin, modo, i);
      lastMode[i] = modo;
    }

    if (modo == 3 && !isInputOnlyPin(pin)) {
      digitalWrite(pin, coils[i] ? HIGH : LOW);
    }

    if (modo == 4 && !isInputOnlyPin(pin)) {
      uint16_t pwm = holdingRegisters[40 + i];

      if (pwm > 255) {
        pwm = 255;
        holdingRegisters[40 + i] = 255;
      }

      // analogWrite é mapeado internamente para canais LEDC no ESP32 Core >= 2.0
      analogWrite(pin, pwm);
    }
  }
}

void configurarModo(uint8_t pin, uint16_t modo, uint8_t index) {
  switch (modo) {
    case 0:
    case 1:
      pinMode(pin, INPUT);
      break;

    case 2:
      if (!isInputOnlyPin(pin)) {
        pinMode(pin, INPUT_PULLUP);
      } else {
        pinMode(pin, INPUT);
        holdingRegisters[index] = 1; // Força para input simples
      }
      break;

    case 3:
      if (!isInputOnlyPin(pin)) {
        pinMode(pin, OUTPUT);
      } else {
        pinMode(pin, INPUT);
        holdingRegisters[index] = 1;
      }
      break;

    case 4:
      if (!isInputOnlyPin(pin)) {
        pinMode(pin, OUTPUT);
      } else {
        pinMode(pin, INPUT);
        holdingRegisters[index] = 1;
      }
      break;

    default:
      holdingRegisters[index] = 0;
      pinMode(pin, INPUT);
      break;
  }
}
