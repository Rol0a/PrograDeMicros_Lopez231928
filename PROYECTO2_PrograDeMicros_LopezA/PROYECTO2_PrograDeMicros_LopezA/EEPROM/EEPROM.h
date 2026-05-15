#ifndef EEPROM_H_
#define EEPROM_H_

#include <avr/io.h>
#include <stdint.h>

void EEPROM_write(uint16_t address, uint8_t data);

uint8_t EEPROM_read(uint16_t address);

#endif