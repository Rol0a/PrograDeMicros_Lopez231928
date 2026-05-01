/*
 * Lab6_PrograDeMicros_LopezA231928.c
 *
 * Created: 24/4/2026 13:32:28
 * Author : mlopez
  * Description:
  * UART send/receive + display received data on LEDs
 */ 

#define F_CPU 16000000UL
#include <avr/io.h>
#include <stdint.h>

/****************************************/
// Function Prototypes
void UART_init(void);
void UART_send(char data);
void UART_sendString(char *txt);

uint8_t UART_available(void);
char UART_read(void);

void output_to_leds(char value);
void delay_soft(void);

/****************************************/
// Main Function
int main(void)
{
    UART_init();

    // Configure LEDs
    DDRB = 0xFF; // Bits 0–5
    DDRD |= (1 << PD2) | (1 << PD3); // Bits 6–7

    while (1)
    {
        // Send string
        UART_sendString("Lorem Simposium");

        // Check if data received
        if (UART_available())
        {
            char rx = UART_read();
            output_to_leds(rx);
        }

        delay_soft();
    }
}

/****************************************/
// UART Initialization
void UART_init(void)
{
    uint16_t ubrr = 103; // 9600 baud @ 16MHz

    UBRR0H = (uint8_t)(ubrr >> 8);
    UBRR0L = (uint8_t)ubrr;

    UCSR0B = (1 << RXEN0) | (1 << TXEN0); // Enable RX & TX
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); // 8-bit data
}

/****************************************/
// Send one byte
void UART_send(char data)
{
    while (!(UCSR0A & (1 << UDRE0)));
    UDR0 = data;
}

/****************************************/
// Send string
void UART_sendString(char *txt)
{
    uint8_t i = 0;
    while (txt[i] != '\0')
    {
        UART_send(txt[i]);
        i++;
    }
}

/****************************************/
// Check if data available
uint8_t UART_available(void)
{
    return (UCSR0A & (1 << RXC0));
}

/****************************************/
// Read received byte
char UART_read(void)
{
    return UDR0;
}

/****************************************/
// Output received byte to LEDs
void output_to_leds(char value)
{
    // Bits 0–5 ? PORTB
    PORTB = value & 0x3F;

    // Bit 6 ? PD2
    if (value & (1 << 6))
        PORTD |= (1 << PD2);
    else
        PORTD &= ~(1 << PD2);

    // Bit 7 ? PD3
    if (value & (1 << 7))
        PORTD |= (1 << PD3);
    else
        PORTD &= ~(1 << PD3);
}

/****************************************/
// Simple delay
void delay_soft(void)
{
    for (volatile uint32_t i = 0; i < 250000; i++);	
}