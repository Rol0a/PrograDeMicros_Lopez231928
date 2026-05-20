#ifndef UART_H_
#define UART_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>

extern volatile char uart_data;
extern volatile uint8_t uart_flag;

void UART_init(void);

void UART_sendChar(char character);

void UART_sendString(char *text);

#endif