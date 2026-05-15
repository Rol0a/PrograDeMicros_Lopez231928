#include "ADC.h"

volatile uint16_t adc_values[6] = {0};
volatile uint8_t adc_channel = 0;

void ADC_init(void)
{
	ADMUX = (1 << REFS0);

	ADCSRA = (1 << ADEN) |
	         (1 << ADIE) |
	         (1 << ADPS2) |
	         (1 << ADPS1) |
	         (1 << ADPS0);

	DIDR0 = 0x3F;

	ADCSRA |= (1 << ADSC);
}

ISR(ADC_vect)
{
	adc_values[adc_channel] = ADC;

	adc_channel++;

	if (adc_channel >= 6)
	{
		adc_channel = 0;
	}

	ADMUX = (ADMUX & 0xF0) |
	        (adc_channel & 0x0F);

	ADCSRA |= (1 << ADSC);
}