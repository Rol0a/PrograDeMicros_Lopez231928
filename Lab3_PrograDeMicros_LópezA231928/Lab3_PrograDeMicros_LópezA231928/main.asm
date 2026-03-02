/* * Laboratorio 3 *
* Creado: Rodrigo López [231928] 
* Autor : Marcos Rodrigo López Agustín [231928] 
* Descripción: Generación de contador de minutos (00–59) mediante
* multiplexado en dos displays de 7 segmentos y contador binario
* de 4 bits controlado por interrupciones por cambio de estado.
*/

/****************************************/
// Definición de Registros y Variables

.include "M328PDEF.inc"

.dseg
.org SRAM_START

LED_BIN:        .BYTE 1      // Contador binario 4 bits
DIG_UNI:        .BYTE 1      // Dígito unidades
DIG_DEC:        .BYTE 1      // Dígito decenas
MUX_SEL:        .BYTE 1      // Selector de display
TICKS_10MS:     .BYTE 1      // Acumulador de 10ms
FLAG_UP:        .BYTE 1      // Bandera incremento
FLAG_DOWN:      .BYTE 1      // Bandera decremento

/****************************************/

.cseg
.org 0x0000

/****************************************/
// Vectores de Interrupción

RJMP INIT
.org 0x0008
RJMP PCINT_ISR
.org 0x001C
RJMP TIMER0_ISR

/****************************************/
// Inicialización de Pila

INIT:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    RJMP CONFIG

/****************************************/
// Configuración General

CONFIG:
    // Prescaler principal → 1 MHz
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100
    STS CLKPR, R16

    // Deshabilitar USART
    LDI R16, 0x00
    STS UCSR0B, R16

/****************************************/
// Configuración de Puertos

    ; LEDs binarios
    LDI R16, 0x0F
    OUT DDRB, R16
    CLR R16
    OUT PORTB, R16

    ; Display segmentos
    LDI R16, 0xFF
    OUT DDRD, R16
    OUT PORTD, R16

    ; PC0-PC1 botones / PC2-PC3 multiplex
    LDI R16, 0b00001100
    OUT DDRC, R16
    LDI R16, 0b00001011 // Pull-Down y configuración de que transistor empieza encendido
    OUT PORTC, R16

/****************************************/
// Pin Change Interrupt

    LDI R16, (1 << PCIE1) // Configuración de máscara y de que pines son reconocidos para interrupción
    STS PCICR, R16
    LDI R16, (1 << PCINT8) | (1 << PCINT9)
    STS PCMSK1, R16

/****************************************/
// Timer0 Configuración

    CALL TIMER0_SETUP

/****************************************/
// Inicializar Variables

    CLR R16
    STS LED_BIN, R16
    STS DIG_UNI, R16
    STS DIG_DEC, R16
    STS MUX_SEL, R16
    STS TICKS_10MS, R16
    STS FLAG_UP, R16
    STS FLAG_DOWN, R16

    SEI

/****************************************/
// Loop Principal

MAIN_LOOP:
    // LOGICA DE MULTIPLEXOR
    LDS R16, MUX_SEL
    CPI R16, 1
    BREQ SHOW_UNI

    SBI PORTC, PC2
    CBI PORTC, PC3
    RJMP DRAW

SHOW_UNI:
    SBI PORTC, PC3
    CBI PORTC, PC2

DRAW: // ES PARA MOSTRAR DISPLAY
    CALL UPDATE_DISPLAY

/****************************************/
// Lógica de conteo 1 segundo

    LDS R16, TICKS_10MS
    CPI R16, 100
    BRNE CHECK_BUTTONS

    CLR R16
    STS TICKS_10MS, R16

    LDS R16, DIG_UNI
    LDS R17, DIG_DEC

    INC R16
    CPI R16, 10
    BRNE STORE_TIME

    CLR R16
    INC R17
    CPI R17, 6
    BRNE STORE_TIME

    CLR R17

STORE_TIME:
    STS DIG_UNI, R16
    STS DIG_DEC, R17

/****************************************/
// Botones

CHECK_BUTTONS:

    ; Incremento
    LDS R16, FLAG_UP
    CPI R16, 1
    BRNE CHECK_DOWN

    LDS R16, LED_BIN
    INC R16
    ANDI R16, 0x0F
    STS LED_BIN, R16
    OUT PORTB, R16
    CLR R16
    STS FLAG_UP, R16

CHECK_DOWN:

    ; Decremento
    LDS R16, FLAG_DOWN
    CPI R16, 1
    BRNE MAIN_LOOP

    LDS R16, LED_BIN
    DEC R16
    ANDI R16, 0x0F
    STS LED_BIN, R16
    OUT PORTB, R16
    CLR R16
    STS FLAG_DOWN, R16

    RJMP MAIN_LOOP

/****************************************/
// Subrutinas de interrupción

TIMER0_SETUP:
    LDI R16, (1 << WGM01)
    OUT TCCR0A, R16
    LDI R16, (1 << CS01) | (1 << CS00)
    OUT TCCR0B, R16
    LDI R16, 156
    OUT OCR0A, R16
    LDI R16, (1 << OCIE0A)
    STS TIMSK0, R16
    CLR R16
    OUT TCNT0, R16
    RET

/****************************************/
// Multiplex Display

UPDATE_DISPLAY:

    PUSH R16
    PUSH R17
    PUSH ZL
    PUSH ZH

    LDS R20, MUX_SEL
    CPI R20, 0
    BREQ LOAD_UNI

    LDS R16, DIG_DEC
    RJMP FETCH_SEG

LOAD_UNI:
    LDS R16, DIG_UNI

FETCH_SEG:
    LDI ZH, HIGH(SEG_TAB<<1)
    LDI ZL, LOW(SEG_TAB<<1)

    ADD ZL, R16
    CLR R17
    ADC ZH, R17

    LPM R16, Z
    OUT PORTD, R16

    POP ZH
    POP ZL
    POP R17
    POP R16
    RET

/****************************************/
// ISR – TIMER0 

TIMER0_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16

    LDS R16, TICKS_10MS
    INC R16
    STS TICKS_10MS, R16

    LDS  R16, MUX_SEL
    LDI  R17, 1
    EOR  R16, R17
    STS  MUX_SEL, R16

    POP R16
    OUT SREG, R16
    POP R16
    RETI

/****************************************/
// ISR – PIN CHANGE

PCINT_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16

    IN R16, PINC
    SBRS R16, PC0
    RJMP SET_UP_FLAG

    SBRS R16, PC1
    RJMP SET_DOWN_FLAG
    RJMP EXIT_PCINT

SET_UP_FLAG:
    LDI R16, 1
    STS FLAG_UP, R16
    RJMP EXIT_PCINT

SET_DOWN_FLAG:
    LDI R16, 1
    STS FLAG_DOWN, R16

EXIT_PCINT:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

/****************************************/
// Tabla de segmentos

SEG_TAB:
.DB 0x7E,0x30,0x6D,0x79,0x33,0x5B,0x5F,0x70,0x7F,0x7B