#include "PWM_8bits.h"

void PWM_8bits_init(void)
{
	DDRD |= (1 << DDD6) | (1 << DDD5);
	DDRB |= (1 << DDB3);
	DDRD |= (1 << DDD3);

	TCCR0A = (1 << COM0A1) |
	         (1 << COM0B1) |
	         (1 << WGM01) |
	         (1 << WGM00);

	TCCR0B = (1 << CS02) |
	         (1 << CS00);

	OCR0A = 21;
	OCR0B = 21;

	TCCR2A = (1 << COM2A1) |
	         (1 << COM2B1) |
	         (1 << WGM20) |
	         (1 << WGM21);

	TCCR2B = (1 << CS22);

	OCR2A = 21;
	OCR2B = 21;
}

void PWM8_setDuty0(uint8_t duty)
{
	OCR0A = duty;
}

void PWM8_setDuty1(uint8_t duty)
{
	OCR0B = duty;
}

void PWM8_setDuty2(uint8_t duty)
{
	OCR2A = duty;
}

void PWM8_setDuty3(uint8_t duty)
{
	OCR2B = duty;
}