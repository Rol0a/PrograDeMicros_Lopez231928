/*=========================================================
* PROYECTO
* Creado: Rodrigo López [231928]
* Autor : Marcos Rodrigo López Agustín [231928]
* Descripción: Reloj 24h / Fecha / Alarma
=========================================================*/

.include "M328PDEF.inc"

/*=========================================================
=                    DATA SECTION (SRAM)                 =*/
.dseg
.org SRAM_START

// -------- DISPLAY DIGITS --------
DISPLAY_01:     .BYTE 1
DISPLAY_02:     .BYTE 1
DISPLAY_03:     .BYTE 1
DISPLAY_04:     .BYTE 1

// -------- CLOCK STORAGE --------
COUNT_SEC:      .BYTE 1      // 0–59
COUNT_MIN:      .BYTE 1      // 0–59
COUNT_HOUR:     .BYTE 1      // 0–23

// -------- DATE STORAGE --------
DAY:            .BYTE 1      // 1–31
MONTH:          .BYTE 1      // 1–12

// -------- ALARM STORAGE --------
ALARM_MIN:      .BYTE 1
ALARM_HOUR:     .BYTE 1

// -------- SYSTEM CONTROL --------
MUX_SEL:        .BYTE 1
TICKS_10MS:     .BYTE 1

FLAG_UP:        .BYTE 1
FLAG_DOWN:      .BYTE 1
FLAG_MODE:      .BYTE 1
FLAG_CONFIRM:   .BYTE 1

BLINK_FLAG:     .BYTE 1
BLINK_COUNT:    .BYTE 1

ALARM_ACTIVE:   .BYTE 1


/*=========================================================
=              REGISTER DEFINITIONS                      =*/
.def MODE     = R20      // 0=CLOCK,1=CLOCK_EDIT,2=DATE,3=DATE_EDIT,4=ALARM,5=ALARM_EDIT
.def ACTION   = R21      // Selected digit in edit mode
.def DECREASE = R22
.def INCREASE = R23


/*=========================================================
=                INTERRUPT VECTORS                       =*/
.cseg
.org 0x0000
RJMP INIT

.org 0x0008
RJMP PCINT_ISR

.org 0x001C
RJMP TIMER0_ISR

/*=========================================================
=                   STACK INITIALIZATION                 = */
INIT:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    RJMP CONFIG

/*=========================================================
=                   GENERAL CONFIGURATION                = */
CONFIG:

// ---- Clock prescaler → 1 MHz ----
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16
    LDI R16, 0b00000100
    STS CLKPR, R16

// ---- Disable USART ----
    LDI R16, 0x00
    STS UCSR0B, R16


/*=========================================================
=                   PORT CONFIGURATION                   =*/

// ---- Multiplex transistors and Mode Representations (PORTB) ----
    LDI R16, 0x7F
    OUT DDRB, R16
    LDI R16, 0b00010001
    OUT PORTB, R16

// ---- 7-Segment segments (PORTD) ----
    LDI R16, 0xFF
    OUT DDRD, R16
    OUT PORTD, R16

// ---- Buttons (PORTC) ----
    LDI R16, 0x00
    OUT DDRC, R16
    LDI R16, 0x0F
    OUT PORTC, R16


/*=========================================================
=                 PIN CHANGE INTERRUPT                   =*/
    LDI R16, (1 << PCIE1)
    STS PCICR, R16
    LDI R16, (1 << PCINT8)|(1 << PCINT9)|(1 << PCINT10)|(1 << PCINT11)
    STS PCMSK1, R16

/*=========================================================
=                 TIMER0 CONFIGURATION                   =*/
    RCALL TIMER0_SETUP

/*=========================================================
=                 VARIABLE INITIALIZATION                =*/
    CLR MODE
    CLR ACTION
    CLR R16

    STS DISPLAY_01, R16
    STS DISPLAY_02, R16
    STS DISPLAY_03, R16
    STS DISPLAY_04, R16

    STS COUNT_SEC, R16
    STS COUNT_MIN, R16
    STS COUNT_HOUR, R16

    STS DAY, R16
    STS MONTH, R16

    STS ALARM_MIN, R16
    STS ALARM_HOUR, R16

    STS MUX_SEL, R16
    STS TICKS_10MS, R16
    STS FLAG_UP, R16
    STS FLAG_DOWN, R16
    STS FLAG_MODE, R16
    STS FLAG_CONFIRM, R16
    STS BLINK_FLAG, R16
    STS BLINK_COUNT, R16
    STS ALARM_ACTIVE, R16

    SEI


/*=========================================================
=                      MAIN LOOP                         =*/
MAIN_LOOP:

// ---- 1. Multiplex Logic and update display values depending on MODE ----
    LDS R16, MUX_SEL
    CBI PORTC, PC0
    CBI PORTC, PC1
    CBI PORTC, PC2
    CBI PORTC, PC3

    CPI R16, 0
    BREQ SHOW_D0

    CPI R16, 1
    BREQ SHOW_D1

    CPI R16, 2
    BREQ SHOW_D2
    RJMP SHOW_D3


SHOW_D0:
    SBI PORTC, PC0
    RJMP DRAW

SHOW_D1:
    SBI PORTC, PC1
    RJMP DRAW

SHOW_D2:
    SBI PORTC, PC2
    RJMP DRAW

SHOW_D3:
    SBI PORTC, PC3

DRAW:
    CALL UPDATE_DISPLAY
	RCALL DISPLAY_MANAGER

// ---- 2. Process mode state machine ----
    RCALL MODE_MANAGER

// ---- 3. Alarm comparison and buzzer ----
    RCALL ALARM_MANAGER

    RJMP MAIN_LOOP

//			   NON-INTERRUPT ROUTINES                     //
/*=========================================================
=                DISPLAY MANAGER                         =*/
DISPLAY_MANAGER:
// Depending on MODE:
//   Load CLOCK digits into DISPLAY_x
//   Load DATE digits into DISPLAY_x
//   Load ALARM digits into DISPLAY_x
// If edit mode:
//   Blink selected digit using BLINK_FLAG
UPDATE_DISPLAY:

    PUSH R16
    PUSH R17
    PUSH ZL
    PUSH ZH

    LDS R20, MUX_SEL

    CPI R20, 0
    BREQ LOAD_D0

    CPI R20, 1
    BREQ LOAD_D1

    CPI R20, 2
    BREQ LOAD_D2

    LDS R16, DISPLAY_04
    RJMP FETCH_SEG

LOAD_D0:
    LDS R16, DISPLAY_01
    RJMP FETCH_SEG

LOAD_D1:
    LDS R16, DISPLAY_02
    RJMP FETCH_SEG

LOAD_D2:
    LDS R16, DISPLAY_03

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

/*=========================================================
=                MODE MANAGER (FSM)                      =*/
MODE_MANAGER:
// If FLAG_MODE:
//   MODE++
//   Reset ACTION
// If MODE is EDIT:
//   Call EDIT_ENGINE
RET


/*=========================================================
=                EDIT ENGINE                             =*/
EDIT_ENGINE:
// If FLAG_UP:
//   Increment selected value
//   Validate limits
// If FLAG_DOWN:
//   Decrement selected value
//   Validate limits
// If FLAG_CONFIRM:
//   ACTION++
//   If ACTION==4 → exit edit mode
RET


/*=========================================================
=                CLOCK INCREMENT (1s)                    =*/
CLOCK_INCREMENT:
// Increment COUNT_SEC
// If 60 → reset and increment COUNT_MIN
// If 60 → reset and increment COUNT_HOUR
// If 24 → reset to 0
RET


/*=========================================================
=                ALARM MANAGER                           =*/
ALARM_MANAGER:
// Compare COUNT_HOUR/MIN with ALARM_HOUR/MIN
// If equal → set ALARM_ACTIVE
// Toggle buzzer using BLINK_FLAG
RET

//			     INTERRUPT ROUTINES                      //
/*=========================================================
=                TIMER0 ISR                              =*/
TIMER0_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; 10ms counter
    LDS R16, TICKS_10MS
    INC R16
    STS TICKS_10MS, R16

    ; Multiplex counter 0–3
    LDS R16, MUX_SEL
    INC R16
    CPI R16, 4
    BRLO STORE_MUX
    CLR R16

STORE_MUX:
    STS MUX_SEL, R16

    POP R16
    OUT SREG, R16
    POP R16
    RETI

/*=========================================================
=                PIN CHANGE ISR                          =*/
PCINT_ISR:
// PC0 → FLAG_UP
// PC1 → FLAG_DOWN
// PC2 → FLAG_MODE
// PC3 → FLAG_CONFIRM
RETI


/*=========================================================
=                TIMER0 SETUP                            =*/
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


/*=========================================================
=                PROGRAM MEMORY TABLES                   =*/

// ---- Segment table (0–9) ----
SEG_TAB:
.DB 0x7E,0x30,0x6D,0x79,0x33,0x5B,0x5F,0x70,0x7F,0x7B

// ---- Month Maximum Day Table (index = month-1) ----
// Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
MONTH_MAX_DAY:
.DB 31,28,31,30,31,30,31,31,30,31,30,31