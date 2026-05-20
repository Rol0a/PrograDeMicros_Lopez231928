#include "PWM_16bits.h"

void PWM_16bits_init(void)
{
	DDRB |= (1 << DDB1) | (1 << DDB2);

	TCCR1A = (1 << COM1A1) |
	         (1 << COM1B1) |
	         (1 << WGM11);

	TCCR1B = (1 << WGM13) |
	         (1 << WGM12) |
	         (1 << CS11);

	ICR1 = 39999;

	OCR1A = 3000;
	OCR1B = 3000;
}

void PWM16_setDutyA(uint16_t duty)
{
	OCR1A = duty;
}

void PWM16_setDutyB(uint16_t duty)
{
	OCR1B = duty;
}