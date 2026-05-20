#include "EEPROM.h"

void EEPROM_write(uint16_t address, uint8_t data)
{
	while (EECR & (1 << EEPE));

	EEAR = address;

	EEDR = data;

	EECR |= (1 << EEMPE);

	EECR |= (1 << EEPE);
}

uint8_t EEPROM_read(uint16_t address)
{
	while (EECR & (1 << EEPE));

	EEAR = address;

	EECR |= (1 << EERE);

	return EEDR;
}