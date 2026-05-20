#ifndef ADC_H_
#define ADC_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>

extern volatile uint16_t adc_values[6];
extern volatile uint8_t adc_channel;

void ADC_init(void);

#endif