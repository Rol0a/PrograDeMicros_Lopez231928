/* * Laboratorio 2 *
* Creado: Rodrigo López [231928] 
* Autor : Marcos Rodrigo López Agustín [231928] 
* Descripción: Entrega de Laboratorio 2. El objetivo del laboratorio es ejecutar un Display de 7 segmentos y un contador binario que tenga un aumento cada 100ms/
*/ 

/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.include "M328PDEF.inc" // Include definitions specific to ATMega328P

.dseg
.org SRAM_START
//variable_name: .byte 1 // Memory alocation for variable_name: .byte (byte size)

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
LDI R16, 0x01F
OUT DDRB, R16

LDI R16, 0xFF
OUT DDRD, R16

//Configuración de las entradas para los botones
// Botones en PC0–PC1
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
/****************************************/
// Loop Infinito

MAIN_LOOP:
	IN R16, TIFR0 // Carga el registro TIFR0 al Registro 16, El registro TIFR0 es una flag de overflow
	SBRS R16, TOV0 // Skip if Bit in Register is Set
	RJMP MAIN_LOOP

	SBI TIFR0, TOV0 // Clear de la flag de Overflow del Timer0
	LDI R16, 100 // Recarga el Timer para que vuelva a tener el contador
	OUT TCNT0, R16 // Saca el valor de R16 (recargo del timer) para que vuelva a iniciar a contar ahi

	INC R17 // Va contando cuantas veces hace overflow
	CPI R17, 10 // Compara que hayan 10 Overflows (100ms)
	BRNE MAIN_LOOP // Branck if Equal to

    INC R20 // Incremento en el contador
	ANDI R20, 0x0F // Mask de los bits superiores
    OUT PORTB, R20 // Sacar por el puerto se salida 
	RJMP MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
/*Con anti rebote
    IN R16, PINC
    ANDI R16, 0b00000001     // PC0
    BREQ REBOTE_BOT1
    RJMP SIG_BOTON2

SIG_BOTON2:
    IN R16, PINC
    ANDI R16, 0b00000010     // PC1
    BREQ REBOTE_BOT2
    RJMP MAIN_LOOP

REBOTE_BOT1:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00000001
    BRNE SIG_BOTON2
    CALL CLOCK_COUNT
    RJMP MAIN_LOOP

CLOCK_COUNT:


REBOTE_BOT2:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00000001
    BRNE SIG_BOTON3
    CALL PORDEF_
    RJMP MAIN_LOOP

PORDEF_:

*/ 

/****************************************/
// Interrupt routines
//Para evitar el rebote unicamente se añadió una rutina que evita que se pueda presionar el mismo botón varias veces.

DELAY:
    LDI R17, 0xFF
	LDI R18, 0xFF
	LDI R19, 0x10
LOOP:
    DEC R17
    BRNE LOOP
	DEC R18
    BRNE LOOP
	DEC R19
    BRNE LOOP
    RET