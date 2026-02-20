/* * Laboratorio 3 *
* Creado: Rodrigo López [231928] 
* Autor : Marcos Rodrigo López Agustín [231928] 
* Descripción: Entrega de PreLab3
*/ 

/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.include "M328PDEF.inc" // Include definitions specific to ATMega328P

.dseg
.org SRAM_START
// Declaración de variables para el contador y flags para los botones
C_LED: .byte 1
INCREASE_BOTON: .byte 1
DECREASE_BOTON: .byte 1

.cseg
.org 0x0000

/****************************************/
// Configuración de la pila

RESET:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    RJMP SETUP

/****************************************/
// Configuracion MCU

SETUP:
// Deshabilitar USART
LDI     R16, 0x00
STS     UCSR0B, R16

//Configuración de CLK (Prescaler)
LDI		R16, 0b00000100		// lo mismo que decir (1<<CLKPS2) 
STS		CLKPR, R16			// set prescaler to 16F_cpu = 1MHz

// Configura los pines para que sean OUTPUTS (salidas de los leds)
LDI R16, 0x0F
OUT DDRB, R16

LDI R16, 0xFF
OUT DDRD, R16

//Configuración de las entradas para los botones
CBI DDRC, 0
SBI PORTC, 0
CBI DDRC, 1
SBI PORTC, 1

//Configura la salidas de cada LED
LDI R20, 0x00
LDI R21, 0x00
OUT PORTB, R20
OUT PORTD, R21

// Inicializacion del Timer0
LDI R16, (1 << CS01) | (1 << CS00)
OUT TCCR0B, R16
LDI R16, 100 
OUT TCNT0, R16

// Habilitar Interrupciones 
LDI R16, (1 << PCIE1) 
STS PCICR, R16

LDI R16, (1 << PCINT8) | (1 << PCINT9) //Se habilita para mis pines de entrada
STS PCMSK1, R16

// Se inicializan las variables que existen
LDI R16, 0x00
STS C_LED, R16
STS INCREASE_BOTON, R16
STS DECREASE_BOTON, R16

SEI	

//Guardar Números en RAM para llamar después
display_7seg: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47
LDI ZH, HIGH(display_7seg<<1)
LDI ZL, LOW(display_7seg<<1)
LPM R17, Z
OUT PORTD, R17

/****************************************/
// Loop Infinito

MAIN_LOOP:
INC_READ:
	//Lectura inicial del primer botón
	LDS R16, INCREASE_BOTON
	CPI R16, 1
	BRNE DEC_READ
	//Cargar valor de Incremento al Contador
	LDS R16, C_LED
	INC R16
	ANDI R16, 0x0F
	STS C_LED, R16
	OUT PORTB, R16

	// LIMPIAR BANDERAS DE DECREMENTO
	LDI R16, 0x00
	STS INCREASE_BOTON, R16
DEC_READ:
	LDS R16, DECREASE_BOTON
	CPI R16, 1
	BRNE MAIN_LOOP
	//Cargar valores de decremento al contador
	LDS R16, C_LED
	DEC R16
	ANDI R16, 0x0F
	STS C_LED, R16
	OUT PORTB, R16

	// LIMPIAR BANDERAS DE DECREMENTO
	LDI R16, 0x00
	STS DECREASE_BOTON, R16

/****************************************/
// NON-INTERRUPT ROUTINES

/****************************************/
// Interrupt routines
INTERRUPT_INC:
	// GUARDAR VALORES PREVIOS DE R16 Y LO QUE HAYA EN SREG
	PUSH R16
	IN R16, SREG
	PUSH R16
	PUSH R17
	
	// HACER LECTURA DE VALORES EN EL BOTÓN
	IN R16, PINC
	SBIS PINC, 0 // Skip Bit if Bit0 Set in Register
	RJMP CHECK_DECREMENT

	// Rutina para aumentar los valores dentro del contador
	LDS R17, C_LED
	DEC R17
	ANDI R17, 0x0F
	STS C_LED, R17
	OUT PORTB, R17

CHECK_DECREMENT:
	SBIS PINC, 1 // Skip if Bit1 is Set
	RJMP ISR_END // Terminar rutina en caso ninguna esté apretada

	//Rutina para disminuir los valores dentro del contador
    LDS  R17, C_LED
    DEC  R17
    ANDI R17, 0x0F
    STS  C_LED, R17
    OUT  PORTB, R17

ISR_END:
	POP R17
	POP R16
	OUT SREG, R16
	POP R16
	RETI