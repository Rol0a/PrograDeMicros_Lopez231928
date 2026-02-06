/*
* PreLab1
*
* Creado: Rodrigo López [231928]
* Autor : Marcos Rodrigo López Agustín [231928]
* Descripción: Entrega de Laboratorio 1, con programación en Assembler en una Arduino Nano. El objetivo del laboratorio es hacer un sumador de 4 bits.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
    LDI R16, 0x0F
	OUT DDRB, R16
	CBI DDRD, 2
	SBI PORTD, 2
	CBI DDRD, 3
	SBI PORTD, 3

	LDI R20, 0x00
	OUT PORTB, R20
/****************************************/
// Loop Infinito
MAIN_LOOP:
    SBIS PIND, 2
	CALL INCREMENTO

	SBIS PIND, 3
	CALL DECREMENTO

	RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
INCREMENTO:
	INC R20
	ANDI R20, 0x0F
	OUT PORTB, R20
	CALL DELAY
	RET

DECREMENTO:
	DEC R20
	ANDI R20, 0x0F
	OUT PORTB, R20
	CALL DELAY
	RET
/****************************************/
// Interrupt routines
DELAY:
	LDI R17, 0x20
	LDI R18, 0xFF
	LDI R19, 0xFF

LOOP2:
	DEC R19
	BRNE LOOP2
	
	DEC R18
	BRNE LOOP2

	DEC R17
	BRNE LOOP2

	RET
/****************************************/