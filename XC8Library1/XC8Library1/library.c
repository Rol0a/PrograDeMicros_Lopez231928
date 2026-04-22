/*
 * library.c
 *
 * Created: 4/17/2026 10:06:44 AM
 *  Author: mlope
 */ 

#include <xc.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "adc.h"

static volatile uint16_t adc_value = 0;
static volatile uint8_t adc_ready = 0;

void ADC_init(ADC_config_t *config)
{
	/******** ADMUX ********/
	ADMUX = 0;

	// Reference selection
	switch (config->reference)
	{
		case ADC_REF_AREF:
		break;
		case ADC_REF_AVCC:
		ADMUX |= (1 << REFS0);
		break;
		case ADC_REF_INTERNAL:
		ADMUX |= (1 << REFS0) | (1 << REFS1);
		break;
	}

	// Data alignment
	if (config->adjust == ADC_LEFT_ADJ)
	ADMUX |= (1 << ADLAR);

	// Channel selection
	ADMUX |= (config->channel & 0x07);

	/******** ADCSRA ********/
	ADCSRA = 0;

	// Enable ADC
	ADCSRA |= (1 << ADEN);

	// Prescaler
	ADCSRA |= (config->prescaler & 0x07);

	// Interrupt
	if (config->interrupt == ADC_INTERRUPT_ENABLE)
	ADCSRA |= (1 << ADIE);
}

void ADC_start(void)
{
	ADCSRA |= (1 << ADSC);
}

uint16_t ADC_read(void)
{
	adc_ready = 0;
	return adc_value;
}

uint8_t ADC_isReady(void)
{
	return adc_ready;
}

/******** ISR ********/
ISR(ADC_vect)
{
	// Read depending on alignment
	if (ADMUX & (1 << ADLAR))
	{
		adc_value = ADCH;  // 8-bit
	}
	else
	{
		adc_value = ADC;   // 10-bit
	}

	adc_ready = 1;
}