/*
 * Lab5_PrograDeMicros_LópezA231928.c
 *
 * Created: 17/4/2026 07:32:31
 * Author: Rodrigo L.
 * Description: Lectura de ADC y creación de señal PWM para servomotores
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

// Variables Globales

volatile uint16_t adc0 = 0;
volatile uint16_t adc1 = 0;
volatile uint16_t adc2 = 0;
volatile uint8_t channel = 0;
volatile uint8_t value = 0;
volatile uint8_t pwm_counter = 0;
volatile uint8_t duty_cycle = 0;

/****************************************/
// Function prototypes
void setup(void);
void init_ADC0(void);
void init_ADC1(void);
void init_ADC2(void);
void init_PWM2(void);
void init_PWM1(void);
void init_Timer0_PWM(void);
/****************************************/
// Main Function

int main(void)
{
	cli();
	setup();
	init_Timer0_PWM();
	init_PWM1();
	init_PWM2();
	init_ADC0();
	sei();
	ADCSRA |= (1 << ADSC);
	
	while (1)
	{

	}
}
/****************************************/
// NON-Interrupt subroutines
void setup(void)
{
	// Set system clock to 2 MHz (prescaler = 8)
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS1) | (1 << CLKPS0);

	// Configuración de canales a utilizar de PWM (OC0A, OC1A, OC2A)
	DDRD  |= (1 << PD6);
	DDRB |= (1 << PB1);
	DDRB |= (1  << PB3);
	
	PORTD = 0x00; // Todo inicia apagado.
	PORTB = 0x00; 
}

void init_Timer0_PWM(void)
{
	TCCR0A = (1 << WGM01); // CTC mode
	TCCR0B = (1 << CS00); // prescaler = 1
	OCR0A = 50;

	TIMSK0 = (1 << OCIE0A); // Enable interrupt
}

void init_PWM1(void)
{
	// Fast PWM
	TCCR1A |= (1 << COM1A1) | (1 << WGM11);
	TCCR1B |= (1 << WGM12) | (1 << WGM13);

	// Prescaler 8
	TCCR1B |= (1 << CS11);

	ICR1 = 5000; // Limitador de Frecuencia para 20ms

	OCR1A = 250; // 
}
void init_PWM2(void)
{
	TCCR2A = 0;
	TCCR2B = 0;
	
	TCCR2A |= (1 << WGM20) | (1 << WGM21); // Configuración de FAST PWM y No invertido
	TCCR2A |= (1 << COM2A1);
	
	TCCR2B |= (1 << CS01) | (1 << CS00); // PreScaler de 64 Lo que signifca que son ticks de 8ms
	
	OCR2A =  250;
}

void init_ADC2(void)
{
	ADMUX = 0;

	// Referencia de Voltaje, Left Section Selector, ADC2 Mux Selector.
	ADMUX |= (1 << REFS0) | (1 << MUX1);

	ADCSRA = 0;

	// Enable ADC, prescaler = 8 (125 kHz ADC clock)
	ADCSRA |= (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0);

	ADCSRA |= (1 << ADIE); // Enable ADC interrupt
}

void init_ADC1(void)
{
	ADMUX = 0;

	// Referencia de Voltaje, Left Section Selector, ADC1 Mux Selector.
	ADMUX |= (1 << REFS0) | (1 << MUX0);

	ADCSRA = 0;

	// Enable ADC, prescaler = 8 (125 kHz ADC clock)
	ADCSRA |= (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0);

	ADCSRA |= (1 << ADIE); // Enable ADC interrupt
}

void init_ADC0(void)
{
	ADMUX = 0;

	// Referencia de Voltaje, Left Section Selector, ADC0 Mux Selector.
	ADMUX |= (1 << REFS0);

	ADCSRA = 0;

	// Enable ADC, prescaler = 8 (125 kHz ADC clock)
	ADCSRA |= (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0);

	ADCSRA |= (1 << ADIE); // Enable ADC interrupt
}
/****************************************/
// Interrupt routines


ISR(ADC_vect)
{
	uint16_t value = ADC;

	if (channel == 0)
	{
		adc0 = value;
		OCR1A = 125 + ((uint32_t)adc0 * 500) / 1023;

		ADMUX = (ADMUX & 0xF0) | 1; // ADC1
		channel = 1;
	}
	else if (channel == 1)
	{
		adc1 = value;
		OCR2A = ((uint32_t)adc1 * 255) / 1023;

		ADMUX = (ADMUX & 0xF0) | 2; // ADC2
		channel = 2;
	}
	else if (channel == 2)
	{
		adc2 = value;

		duty_cycle = ((uint32_t)adc2 * 255) / 1023;

		ADMUX = (ADMUX & 0xF0) | 0; // back to ADC0
		channel = 0;
	}

	ADCSRA |= (1 << ADSC);
}

ISR(TIMER0_COMPA_vect)
{
	pwm_counter++;

	if (pwm_counter < duty_cycle)
	PORTD |= (1 << PD6);   // ON
	else
	PORTD &= ~(1 << PD6);  // OFF
}