#include "UART.h"

volatile char uart_data = 0;
volatile uint8_t uart_flag = 0;

void UART_init(void)
{
	DDRD |= (1 << DDD1);

	DDRD &= ~(1 << DDD0);

	UCSR0A = 0;

	UCSR0B = (1 << RXCIE0) |
	         (1 << RXEN0) |
	         (1 << TXEN0);

	UCSR0C = (1 << UCSZ01) |
	         (1 << UCSZ00);

	UBRR0 = 103;
}

void UART_sendChar(char character)
{
	while (!(UCSR0A & (1 << UDRE0)));

	UDR0 = character;
}

void UART_sendString(char *text)
{
	uint8_t i = 0;

	while (text[i] != '\0')
	{
		UART_sendChar(text[i]);

		i++;
	}
}