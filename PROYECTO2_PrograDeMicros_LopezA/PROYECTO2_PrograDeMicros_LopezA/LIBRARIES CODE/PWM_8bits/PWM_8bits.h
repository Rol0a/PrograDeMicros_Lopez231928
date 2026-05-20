#ifndef PWM_8BITS_H_
#define PWM_8BITS_H_

#include <avr/io.h>
#include <stdint.h>

void PWM_8bits_init(void);

void PWM8_setDuty0(uint8_t duty);
void PWM8_setDuty1(uint8_t duty);
void PWM8_setDuty2(uint8_t duty);
void PWM8_setDuty3(uint8_t duty);

#endif