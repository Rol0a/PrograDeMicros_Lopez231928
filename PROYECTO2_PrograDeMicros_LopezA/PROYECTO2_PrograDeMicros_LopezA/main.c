/*
 * PROYECTO2_PrograDeMicros_LopezA.c
 *
 * Created: 4/5/2026 23:44:18
 * Author : Rodrigo López
 * Descripción: 
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>

#include "ADC/ADC.h"
#include "PWM_8bits/PWM_8bits.h"
#include "PWM_16bits/PWM_16bits.h"
#include "UART/UART.h"
#include "EEPROM/EEPROM.h"

/****************************************/
// Variables Globales

volatile uint16_t adc_values[6] = {0};

volatile uint8_t servo0_pos = 127;
volatile uint8_t servo1_pos = 127;
volatile uint8_t servo2_pos = 127;
volatile uint8_t servo3_pos = 127;
volatile uint8_t servo4_pos = 127;
volatile uint8_t servo5_pos = 127;

typedef enum
{
	MODO_MANUAL,
	MODO_UART,
	MODO_EEPROM

} modo_t;

volatile modo_t current_mode = MODO_MANUAL;

char uart_buffer[10];
volatile char uart_data = 0;
volatile uint8_t uart_flag = 0;
uint8_t uart_index = 0;

/****************************************/
// Function prototypes

void setup(void);

void manual_mode(void);
void uart_mode(void);
void eeprom_mode(void);

void POSICION0(void);
void POSICION1(void);
void POSICION2(void);
void POSICION3(void);

void setServo(uint8_t servo, uint8_t value);

void process_uart_command(void);

void save_pose(uint8_t pose);
void load_pose(uint8_t pose);

void EEPROM_menu(void);

/****************************************/
// Main Function

int main(void)
{
	cli();

	setup();

	sei();

	UART_sendString("LISTO\r\n");

	while (1)
	{
		if (uart_flag)
		{
			if (uart_data == 'U')
			{
				uart_flag = 0;
				uart_index = 0;

				current_mode = MODO_UART;

				UART_sendString("\r\nModo UART\r\n");
			}

			else if (uart_data == 'M')
			{
				uart_flag = 0;
				uart_index = 0;

				current_mode = MODO_MANUAL;

				UART_sendString("\r\nModo Manual\r\n");
			}

			else if (uart_data == 'E')
			{
				uart_flag = 0;
				uart_index = 0;

				current_mode = MODO_EEPROM;

				EEPROM_menu();
			}

			else if (current_mode != MODO_UART &&
			current_mode != MODO_EEPROM)
			{
				uart_flag = 0;
			}
		}

		switch (current_mode)
		{
			case MODO_MANUAL:
			manual_mode();
			break;

			case MODO_UART:
			uart_mode();
			break;

			case MODO_EEPROM:
			eeprom_mode();
			break;
		}
	}
}

/****************************************/
// NON-Interrupt subroutines

void setup(void)
{
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS1) | (1 << CLKPS0);

	ADC_init();

	PWM_8bits_init();

	PWM_16bits_init();

	UART_init();
}

void manual_mode(void)
{
	uint8_t pwm8 = 0;
	uint16_t pwm16 = 0;

	pwm8 = 8 + ((uint32_t)adc_values[0] * 27) / 1023;
	PWM8_setDuty0(pwm8);

	pwm8 = 8 + ((uint32_t)adc_values[1] * 27) / 1023;
	PWM8_setDuty1(pwm8);

	pwm16 = 1000 + ((uint32_t)adc_values[2] * 3500) / 1023;
	PWM16_setDutyA(pwm16);

	pwm16 = 1000 + ((uint32_t)adc_values[3] * 3500) / 1023;
	PWM16_setDutyB(pwm16);

	pwm8 = 8 + ((uint32_t)adc_values[4] * 27) / 1023;
	PWM8_setDuty2(pwm8);

	pwm8 = 8 + ((uint32_t)adc_values[5] * 27) / 1023;
	PWM8_setDuty3(pwm8);

	servo0_pos = adc_values[0] / 4;
	servo1_pos = adc_values[1] / 4;
	servo2_pos = adc_values[2] / 4;
	servo3_pos = adc_values[3] / 4;
	servo4_pos = adc_values[4] / 4;
	servo5_pos = adc_values[5] / 4;
}

void uart_mode(void)
{
	if (uart_flag)
	{
		uart_flag = 0;

		if (uart_data == '\r' || uart_data == '\n')
		{
			if (uart_index > 0)
			{
				uart_buffer[uart_index] = '\0';

				process_uart_command();

				uart_index = 0;
			}
		}

		else
		{
			if (uart_index < 9)
			{
				uart_buffer[uart_index] = uart_data;
				uart_index++;
			}

			else
			{
				uart_index = 0;

				UART_sendString("Buffer lleno\r\n");
			}
		}
	}
}

void process_uart_command(void)
{
	uint8_t servo = 0;
	uint16_t value = 0;
	uint8_t i = 0;

	if (uart_buffer[0] == 'N')
	{
		POSICION0();

		UART_sendString("POSICION0a\r\n");

		return;
	}

	if (uart_buffer[0] == 'I')
	{
		POSICION1();

		UART_sendString("POSICION1\r\n");

		return;
	}

	if (uart_buffer[0] == 'D')
	{
		POSICION2();

		UART_sendString("POSICION2\r\n");

		return;
	}

	if (uart_buffer[0] == 'R')
	{
		POSICION3();

		UART_sendString("POSICION3\r\n");

		return;
	}

	if (uart_buffer[0] != 'S')
	{
		UART_sendString("Comando invalido\r\n");

		return;
	}

	if (uart_buffer[1] < '0' || uart_buffer[1] > '5')
	{
		UART_sendString("Servo invalido\r\n");

		return;
	}

	if (uart_buffer[2] != ':')
	{
		UART_sendString("Formato invalido\r\n");

		return;
	}

	servo = uart_buffer[1] - '0';

	i = 3;

	while (uart_buffer[i] >= '0' &&
	uart_buffer[i] <= '9')
	{
		value = (value * 10) +
		(uart_buffer[i] - '0');

		i++;
	}

	if (value > 255)
	{
		value = 255;
	}

	setServo(servo, value);

	UART_sendString("Movimiento realizado\r\n");
}

void eeprom_mode(void)
{
	if (uart_flag)
	{
		uart_flag = 0;

		if (uart_data == '\r' || uart_data == '\n')
		{
			if (uart_index > 0)
			{
				uart_buffer[uart_index] = '\0';

				if (uart_buffer[0] == 'G')
				{
					save_pose(uart_buffer[1] - '0');
				}

				else if (uart_buffer[0] == 'L')
				{
					load_pose(uart_buffer[1] - '0');
				}

				else
				{
					UART_sendString("Comando invalido\r\n");
				}

				uart_index = 0;
			}
		}

		else
		{
			if (uart_index < 9)
			{
				uart_buffer[uart_index] = uart_data;

				uart_index++;
			}
		}
	}
}

void POSICION0(void)
{
	setServo(0, 255);
	setServo(1, 0);
	setServo(2, 160);
	setServo(3, 120);
	setServo(4, 0);
	setServo(5, 160);
}

void POSICION1(void)
{
	setServo(0, 0);
	setServo(1, 0);
	setServo(2, 100);
	setServo(3, 100);
	setServo(4, 90);
	setServo(5, 160);
}

void POSICION2(void)
{
	setServo(0, 255);
	setServo(1, 255);
	setServo(2, 200);
	setServo(3, 120);
	setServo(4, 20);
	setServo(5, 100);
}

void POSICION3(void)
{
	setServo(0, 180);
	setServo(1, 100);
	setServo(2, 160);
	setServo(3, 120);
	setServo(4, 100);
	setServo(5, 40);
}

void setServo(uint8_t servo, uint8_t value)
{
	uint8_t pwm8 = 0;
	uint16_t pwm16 = 0;

	switch (servo)
	{
		case 0:

		pwm8 = 8 + ((uint32_t)value * 27) / 255;

		PWM8_setDuty0(pwm8);

		servo0_pos = value;

		break;

		case 1:

		pwm8 = 8 + ((uint32_t)value * 27) / 255;

		PWM8_setDuty1(pwm8);

		servo1_pos = value;

		break;

		case 2:

		pwm16 = 1000 + ((uint32_t)value * 3500) / 255;

		PWM16_setDutyA(pwm16);

		servo2_pos = value;

		break;

		case 3:

		pwm16 = 1000 + ((uint32_t)value * 3500) / 255;

		PWM16_setDutyB(pwm16);

		servo3_pos = value;

		break;

		case 4:

		pwm8 = 8 + ((uint32_t)value * 27) / 255;

		PWM8_setDuty2(pwm8);

		servo4_pos = value;

		break;

		case 5:

		pwm8 = 8 + ((uint32_t)value * 27) / 255;

		PWM8_setDuty3(pwm8);

		servo5_pos = value;

		break;
	}
}

void save_pose(uint8_t pose)
{
	uint16_t address = pose * 6;

	EEPROM_write(address + 0, servo0_pos);
	EEPROM_write(address + 1, servo1_pos);
	EEPROM_write(address + 2, servo2_pos);
	EEPROM_write(address + 3, servo3_pos);
	EEPROM_write(address + 4, servo4_pos);
	EEPROM_write(address + 5, servo5_pos);

	UART_sendString("Posicion guardada\r\n");
}

void load_pose(uint8_t pose)
{
	uint16_t address = pose * 6;

	setServo(0, EEPROM_read(address + 0));
	setServo(1, EEPROM_read(address + 1));
	setServo(2, EEPROM_read(address + 2));
	setServo(3, EEPROM_read(address + 3));
	setServo(4, EEPROM_read(address + 4));
	setServo(5, EEPROM_read(address + 5));

	UART_sendString("Posicion cargada\r\n");
}

void EEPROM_menu(void)
{
	UART_sendString("\r\nModo EEPROM\r\n");

	UART_sendString("G0 Guardar pose 0\r\n");
	UART_sendString("G1 Guardar pose 1\r\n");
	UART_sendString("G2 Guardar pose 2\r\n");
	UART_sendString("G3 Guardar pose 3\r\n");

	UART_sendString("L0 Leer pose 0\r\n");
	UART_sendString("L1 Leer pose 1\r\n");
	UART_sendString("L2 Leer pose 2\r\n");
	UART_sendString("L3 Leer pose 3\r\n");
}

/****************************************/
// Interrupt routines

ISR(USART_RX_vect)
{
	uart_data = UDR0;

	uart_flag = 1;
}