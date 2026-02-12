/* * Laboratorio 1 *
* Creado: Rodrigo López [231928] 
* Autor : Marcos Rodrigo López Agustín [231928] 
* Descripción: Entrega de Laboratorio 1, con programación en Assembler en una Arduino Nano. El objetivo del laboratorio es hacer un sumador de 4 bits. 
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

//Configuración de CLK
LDI		R16, 0b00000100		// lo mismo que decir (1<<CLKPS2) 
STS		CLKPR, R16			// set prescaler to 16F_cpu = 1MHz

// Configura los pines para que sean OUTPUTS (salidas de los leds)
LDI R16, 0x0F
OUT DDRB, R16

LDI R16, 0xFF
OUT DDRD, R16

//Configuración de las entradas para los botones
// PC0 definido para evitar flotación
CBI DDRC, 0
SBI PORTC, 0

// Botones en PC1–PC5
CBI DDRC, 1
SBI PORTC, 1
CBI DDRC, 2
SBI PORTC, 2
CBI DDRC, 3
SBI PORTC, 3
CBI DDRC, 4
SBI PORTC, 4
CBI DDRC, 5
SBI PORTC, 5

//Configura la salidas de cada LED
LDI R20, 0x00
LDI R21, 0x00
OUT PORTB, R20
OUT PORTD, R21

/****************************************/
// Loop Infinito
//Con anti rebote

MAIN_LOOP:

    IN R16, PINC
    ANDI R16, 0b00000010     // PC1
    BREQ REBOTE_BOT1
    RJMP SIG_BOTON2

SIG_BOTON2:
    IN R16, PINC
    ANDI R16, 0b00000100     // PC2
    BREQ REBOTE_BOT2
    RJMP SIG_BOTON3

SIG_BOTON3:
    IN R16, PINC
    ANDI R16, 0b00001000     // PC3
    BREQ REBOTE_BOT3
    RJMP SIG_BOTON4

SIG_BOTON4:
    IN R16, PINC
    ANDI R16, 0b00010000     // PC4
    BREQ REBOTE_BOT4
    RJMP SIG_BOTON5

SIG_BOTON5:
    IN R16, PINC
    ANDI R16, 0b00100000     // PC5
    BREQ REBOTE_BOT5
    RJMP MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

REBOTE_BOT1:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00000010
    BRNE SIG_BOTON2
    CALL SUMUP
    RJMP MAIN_LOOP

SUMUP:
    INC R20
    ANDI R20, 0x0F
    OUT PORTB, R20
    RET

REBOTE_BOT2:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00000100
    BRNE SIG_BOTON3
    CALL DECREASE
    RJMP MAIN_LOOP

DECREASE:
    DEC R20
    ANDI R20, 0x0F
    OUT PORTB, R20
    RET

REBOTE_BOT3:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00001000
    BRNE SIG_BOTON4
    CALL SUMA2
    RJMP MAIN_LOOP

SUMA2:
    INC R21
    ANDI R21, 0x0F
    MOV R22, R21
    SWAP R22
    ANDI R22, 0xF0
    OUT PORTD, R22
    RET


REBOTE_BOT4:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00010000
    BRNE SIG_BOTON5
    CALL RESTA2
    RJMP MAIN_LOOP

RESTA2:
    DEC R21
    ANDI R21, 0x0F
    MOV R22, R21
    SWAP R22
    ANDI R22, 0xF0
    OUT PORTD, R22
    RET

REBOTE_BOT5:
    CALL DELAY
    IN R16, PINC
    ANDI R16, 0b00100000
    BREQ BOT5_EXEC
    RJMP MAIN_LOOP

BOT5_EXEC:
    CALL SUMATODO
    RJMP MAIN_LOOP

SUMATODO:
    MOV R23, R21
    ANDI R23, 0x0F
    MOV R24, R20
    ANDI R24, 0x0F
    ADD R23, R24
    BRCS CARRY_ON
    RJMP CARRY_OFF

CARRY_OFF:
    CBI PORTB, 4
    ANDI R23, 0x0F
    IN R25, PORTD
    ANDI R25, 0xF0
    OR R25, R23
    OUT PORTD, R25
    RET

CARRY_ON:
    SBI PORTB, 4
    ANDI R23, 0x0F
    IN R25, PORTD
    ANDI R25, 0xF0
    OR R25, R23
    OUT PORTD, R25
    RET

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
