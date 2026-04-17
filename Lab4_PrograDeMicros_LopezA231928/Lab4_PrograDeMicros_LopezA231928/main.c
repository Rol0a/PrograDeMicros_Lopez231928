
/* * 
	Lab4_PrograDeMicros_LopezA231928 
	Author: Rodrigo Lopez 
	Description: Pre-Lab, Laboratorio y Post-Lab. Lectura de ADC, Interrupciones, Timers. 
*/ /****************************************/

/****************************************/
// Libraries
#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Global Variables

#define TIMER1_COMPARE_VALUE 0x004E   // Valor de CTC para 5ms

volatile uint8_t adc_value = 0;          // Lectura del ADC
volatile uint8_t led_counter = 0;        // Contador de LEDS (Valor)

volatile uint8_t flag_btn_increment = 0; // Increment button flag
volatile uint8_t flag_btn_decrement = 0; // Decrement button flag

volatile uint8_t prev_PC0 = 1;           // Valor anterior del botón 0
volatile uint8_t prev_PC1 = 1;           // Valor anterior del botón 1

volatile uint8_t active_transistor = 0;  // 0=LEDs, 1=Units display, 2=Tens display

// Mostrar inicialmente 00
volatile uint8_t pattern_units = 0x7E;
volatile uint8_t pattern_tens  = 0x7E;

/****************************************/
// TABLA DE VALORES DE DISPLAY

const uint8_t SEGMENT_MAP[16] = {
0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47
};

/****************************************/
// Function Prototypes

void setup(void);
void init_ADC(void);
void init_Timer1(void);
void init_PinChange(void);

/****************************************/
// Main Function

int main(void)
{
	cli();                  // Deshabilitar interrupciones
	setup();                // Configurar puertos y salidas
	init_PinChange();       // Enable pin change interrupts
	init_ADC();             // Configurar ADC
	init_Timer1();          // Configurar Timer1
	sei();                  // Habilitar interrupciones
	
	// Primera Lectura de ADC
	ADCSRA |= (1 << ADSC);
	
	while (1)
	{
		// Lógica de Botones
		if (flag_btn_increment)
		{
			flag_btn_increment = 0;
			led_counter++;
		}

		if (flag_btn_decrement)
		{
			flag_btn_decrement = 0;
			led_counter--;
		}
	}
}

/****************************************/
// Setup function (I/O configuration)

void setup(void)
{
	// Set system clock to 1 MHz (prescaler = 16)
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS2);

	// Disable UART
	UCSR0B = 0x00;

	// PORTD -> Output (LEDs + 7-segment segments)
	DDRD = 0xFF;
	PORTD = 0xFF; // Todo inicia apagado.

	// PORTB -> Output (control de transistores)
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3);
	PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3));

	// PORTC -> Inputs
	// PC0, PC1: buttons (with pull-up)
	// PC2: analog input (ADC)
	DDRC &= ~((1 << PC0) | (1 << PC1) | (1 << PC2));
	PORTC |= (1 << PC0) | (1 << PC1); // Enable pull-ups
}

/****************************************/
// Pin Change Interrupt Initialization

void init_PinChange(void)
{
	PCICR |= (1 << PCIE1);                 // Enable PCINT[14:8] (PORTC)
	PCMSK1 |= (1 << PCINT8) | (1 << PCINT9); // Enable PC0 and PC1 interrupts
}

/****************************************/
// Timer1 Initialization (CTC mode)

void init_Timer1(void)
{
	TCCR1B = 0;

	TCCR1B |= (1 << WGM12); // CTC mode
	TCCR1B |= (1 << CS11) | (1 << CS10); // Prescaler = 64

	OCR1A = TIMER1_COMPARE_VALUE; // Valor de Comparación

	TIMSK1 |= (1 << OCIE1A); // Comparación
	TCNT1 = 0; // Reiniciar contador
}

/****************************************/
// ADC Initialization

void init_ADC(void)
{
	ADMUX = 0;

	// Referencia de Voltaje, Left Section Selector, ADC2 Mux Selector.
	ADMUX |= (1 << REFS0) | (1 << ADLAR) | (1 << MUX1);

	ADCSRA = 0;

	// Enable ADC, prescaler = 8 (125 kHz ADC clock)
	ADCSRA |= (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0);

	ADCSRA |= (1 << ADIE); // Enable ADC interrupt
}

/****************************************/
// Interrupt Service Routines

// Pin Change Interrupt (botón)
ISR(PCINT1_vect)
{
	uint8_t current_state = PINC;

	// --- PC0 (Decrement button) ---
	uint8_t current_PC0 = (current_state >> PC0) & 1;

	// Antirrebote en código
	if ((prev_PC0 == 0) && (current_PC0 == 1))
	{
		flag_btn_decrement = 1;
	}
	prev_PC0 = current_PC0;

	// --- PC1 (Increment button) ---
	uint8_t current_PC1 = (current_state >> PC1) & 1;

	if ((prev_PC1 == 0) && (current_PC1 == 1))
	{
		flag_btn_increment = 1;
	}
	prev_PC1 = current_PC1;
}

/****************************************/
// Timer1 Compare Interrupt (Multiplexing + Logic)

ISR(TIMER1_COMPA_vect)
{
	// Todos inician apagados.
	PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3));

	// Multiplexado que hace el cambio
	switch (active_transistor)
	{
		case 0: // LEDs
		PORTD = ~led_counter;
		PORTB |= (1 << PB1);
		break;

		case 1: // Display de Unidades
		PORTD = pattern_units;
		PORTB |= (1 << PB2);
		break;

		case 2: // Display de Decenas
		PORTD = pattern_tens;
		PORTB |= (1 << PB3);
		break;
	}

	// Multiplexado
	active_transistor++;
	if (active_transistor == 3)
	{
		active_transistor = 0;
	}

	// Compara el valor del ADC con el valor dentro del contador de Botón.
	if (adc_value > led_counter)
	{
		PORTB |= (1 << PB0);  // Enciende Alarma
	}
	else
	{
		PORTB &= ~(1 << PB0); // Apaga Alarma
	}
}

/****************************************/
// Lectura y Conversión de ADC (ISR)

ISR(ADC_vect)
{
	adc_value = ADCH; // Lee los valores del ADC

	// Divide los valores para los displays en los nibbles a mostrar
	uint8_t high_nibble = (adc_value >> 4) & 0x0F;
	uint8_t low_nibble  = adc_value & 0x0F;

	// Hace un match con la lista de los valores
	pattern_tens  = SEGMENT_MAP[high_nibble];
	pattern_units = SEGMENT_MAP[low_nibble];

	// Inicia nuevos valores para ADC
	ADCSRA |= (1 << ADSC);
}