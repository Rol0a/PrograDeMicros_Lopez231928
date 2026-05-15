#ifndef PWM_16BITS_H_
#define PWM_16BITS_H_

#include <avr/io.h>
#include <stdint.h>

void PWM_16bits_init(void);

void PWM16_setDutyA(uint16_t duty);
void PWM16_setDutyB(uint16_t duty);

#endif