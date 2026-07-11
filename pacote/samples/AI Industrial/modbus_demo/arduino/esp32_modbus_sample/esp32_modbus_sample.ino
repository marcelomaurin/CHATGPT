#include <ModbusRTUSlave.h>

/*
  ESP32 as a Modbus RTU I/O module over USB/Serial.

  Map:
    Coils[0..13]            = digital write on mapped GPIOs
    DiscreteInputs[0..13]   = digital read on mapped GPIOs
    HoldingRegisters[0..13] = mode for each GPIO slot
    HoldingRegisters[20..33]= PWM value for each GPIO slot
    InputRegisters[0..7]    = analog reads on ADC1

  Modes:
    0 = disabled / INPUT
    1 = INPUT
    2 = INPUT_PULLUP
    3 = OUTPUT
    4 = PWM

  Note:
    This sketch uses safe general-purpose ESP32 GPIOs.
    If you want external RS485, switch Serial to Serial2 and set the UART pins.
*/

#define SLAVE_ID 1
#define BAUDRATE 9600

ModbusRTUSlave modbus(Serial);

static const uint8_t DIGITAL_SLOT_COUNT = 14;
static const uint8_t ANALOG_SLOT_COUNT = 8;
static const uint8_t INVALID_PIN = 255;

// Output-capable GPIOs that are safe for a basic ESP32 DevKit style board.
static const uint8_t DIGITAL_PINS[DIGITAL_SLOT_COUNT] = {
  4, 5, 13, 14, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27
};

// ADC1 inputs. The last two slots are reserved on common ESP32-WROOM boards.
static const uint8_t ANALOG_PINS[ANALOG_SLOT_COUNT] = {
  36, 39, 34, 35, 32, 33, INVALID_PIN, INVALID_PIN
};

bool coils[DIGITAL_SLOT_COUNT];
bool discreteInputs[DIGITAL_SLOT_COUNT];
uint16_t holdingRegisters[40];
uint16_t inputRegisters[ANALOG_SLOT_COUNT];
uint16_t lastMode[DIGITAL_SLOT_COUNT];

static inline uint8_t slotToPin(uint8_t slot)
{
  return DIGITAL_PINS[slot];
}

void configurarModo(uint8_t slot, uint16_t modo)
{
  const uint8_t pin = slotToPin(slot);

  switch (modo) {
    case 0:
    case 1:
      pinMode(pin, INPUT);
      break;

    case 2:
      pinMode(pin, INPUT_PULLUP);
      break;

    case 3:
    case 4:
      pinMode(pin, OUTPUT);
      break;

    default:
      holdingRegisters[slot] = 0;
      pinMode(pin, INPUT);
      break;
  }
}

void atualizarEntradas()
{
  for (uint8_t slot = 0; slot < DIGITAL_SLOT_COUNT; slot++) {
    discreteInputs[slot] = digitalRead(slotToPin(slot));
  }

  for (uint8_t slot = 0; slot < ANALOG_SLOT_COUNT; slot++) {
    if (ANALOG_PINS[slot] != INVALID_PIN) {
      inputRegisters[slot] = analogRead(ANALOG_PINS[slot]);
    } else {
      inputRegisters[slot] = 0;
    }
  }
}

void aplicarSaidas()
{
  for (uint8_t slot = 0; slot < DIGITAL_SLOT_COUNT; slot++) {
    const uint8_t pin = slotToPin(slot);
    uint16_t modo = holdingRegisters[slot];

    if (modo != lastMode[slot]) {
      configurarModo(slot, modo);
      lastMode[slot] = modo;
    }

    if (modo == 3) {
      digitalWrite(pin, coils[slot] ? HIGH : LOW);
    } else if (modo == 4) {
      uint16_t pwm = holdingRegisters[20 + slot];

      if (pwm > 255) {
        pwm = 255;
        holdingRegisters[20 + slot] = 255;
      }

      analogWrite(pin, pwm);
    }
  }
}

void setup()
{
  for (uint8_t slot = 0; slot < DIGITAL_SLOT_COUNT; slot++) {
    coils[slot] = false;
    discreteInputs[slot] = false;
    holdingRegisters[slot] = 0;
    lastMode[slot] = 999;
  }

  for (uint8_t slot = 20; slot < 34; slot++) {
    holdingRegisters[slot] = 0;
  }

  for (uint8_t slot = 0; slot < ANALOG_SLOT_COUNT; slot++) {
    inputRegisters[slot] = 0;
  }

  analogReadResolution(12);

  modbus.configureCoils(coils, DIGITAL_SLOT_COUNT);
  modbus.configureDiscreteInputs(discreteInputs, DIGITAL_SLOT_COUNT);
  modbus.configureHoldingRegisters(holdingRegisters, 40);
  modbus.configureInputRegisters(inputRegisters, ANALOG_SLOT_COUNT);

  Serial.begin(BAUDRATE);
  modbus.begin(SLAVE_ID, BAUDRATE);
}

void loop()
{
  atualizarEntradas();
  modbus.poll();
  aplicarSaidas();
}
