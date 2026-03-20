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
FLAG_MINUTE:	.BYTE 1

BLINK_FLAG:     .BYTE 1
BLINK_COUNT:    .BYTE 1

ALARM_ACTIVE:   .BYTE 1
PREV_PINC: .BYTE 1

HALFSEC_CNT: .BYTE 1 
SEC_CNT:     .BYTE 1   


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

.org 0x0016
RJMP TIMER1_ISR

.org 0x0020
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
    LDI R16, 0x7F // 00111111, PB0-3 son salidas para transistores, PB4 es salida para alarma y PB5 salida para un LED de modo.
    OUT DDRB, R16
    LDI R16, 0b00000001
    OUT PORTB, R16

// ---- 7-Segment segments (PORTD) ----
    LDI R16, 0xFF
    OUT DDRD, R16
    OUT PORTD, R16

// ---- Buttons (PORTC) ----
    LDI R16, 0x30 // 0b00110000, PORTC4 y PORTC5 son Salidas
    OUT DDRC, R16
    LDI R16, 0x0F // 0b00011111, Se indica que las entradas son Pull Ups y que se inicia con el MODO 1 activado
    OUT PORTC, R16

	// NOTA: PC4 es el LED Amarillo (Modo Reloj), PC5 es el LED Verde (Modo Alarma), PB5 es el LED Azul (Modo Fecha)
/*=========================================================
=                 PIN CHANGE INTERRUPT                   =*/
    LDI R16, (1 << PCIE1)
    STS PCICR, R16
    LDI R16, (1 << PCINT8)|(1 << PCINT9)|(1 << PCINT10)|(1 << PCINT11)
    STS PCMSK1, R16

/*=========================================================
=                 TIMER0 CONFIGURATION                   =*/
    RCALL TIMER0_SETUP
	RCALL TIMER1_SETUP
/*=========================================================
=                 VARIABLE INITIALIZATION                =*/
    LDI MODE, 0x02
    CLR ACTION
    CLR R16

    STS DISPLAY_01, R16
    STS DISPLAY_02, R16
    STS DISPLAY_03, R16
    STS DISPLAY_04, R16
/* QUE INICIE EN CERO
    STS COUNT_SEC, R16
    STS COUNT_MIN, R16
    STS COUNT_HOUR, R16
	*/
// ----HACER QUE EL CLOCK INICIE CON UN VALOR ----
	LDI R16, 58
	STS COUNT_MIN, R16

	LDI R16, 23
	STS COUNT_HOUR, R16

	CLR R16
	STS COUNT_SEC, R16

  //STS DAY, R16
 // STS MONTH, R16

/* QUE INICIE EN UNA FECHA ESPECIFICA */
	LDI R16, 20
	STS DAY, R16

	LDI R16, 6
	STS MONTH, R16 

// ----HACER QUE EL RELOJ INICIE CON UN VALOR -----
 /*STS ALARM_MIN, R16
    STS ALARM_HOUR, R16 */
	LDI R16, 0
	STS ALARM_MIN, R16

	LDI R16, 0
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

	IN   R16, PINC
    STS  PREV_PINC, R16
    SEI


/*=========================================================
=                      MAIN LOOP                         =*/
MAIN_LOOP:

// ORDEN DE FUNCIONES QUE TIENE EL CODIGO
    RCALL MODE_MANAGER
    RCALL EDIT_ENGINE
    RCALL ALARM_MANAGER

// LLAMADO DE LOGICA DE MULTIPLEX
    RCALL DISPLAY_MANAGER     // Llamado a los valores dentro de los displays
    RCALL MUX_HANDLER         // Llamado al multiplexado correcto

	LDS R17, FLAG_MODE
	CPI R17, 1
	BRNE NO_TEST

	CBI PORTB, PB5   // LED ON

NO_TEST:
    RJMP MAIN_LOOP

//			   NON-INTERRUPT ROUTINES                     //
/*=========================================================
=                DISPLAY MANAGER                         =*/
DISPLAY_MANAGER:
	PUSH R16

    MOV R16, MODE

// -------- CLOCK --------
    CPI R16, 0
    BREQ LOAD_CLOCK

    CPI R16, 1
    BREQ LOAD_CLOCK

// -------- DATE --------
    CPI R16, 2
    BREQ LOAD_DATE

    CPI R16, 3
    BREQ LOAD_DATE

// -------- ALARM --------
    CPI R16, 4
    BREQ LOAD_ALARM

    CPI R16, 5
    BREQ LOAD_ALARM

    RJMP DISPLAY_EXIT

// =========================
LOAD_CLOCK:
    // Example split HH:MM
    LDS R16, COUNT_HOUR
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_01, R17
    STS DISPLAY_02, R18

    LDS R16, COUNT_MIN
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_03, R17
    STS DISPLAY_04, R18
    RJMP APPLY_BLINK

// =========================
LOAD_DATE:
    LDS R16, DAY
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_01, R17
    STS DISPLAY_02, R18

    LDS R16, MONTH
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_03, R17
    STS DISPLAY_04, R18
    RJMP APPLY_BLINK

// =========================
LOAD_ALARM:
    LDS R16, ALARM_HOUR
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_01, R17
    STS DISPLAY_02, R18

    LDS R16, ALARM_MIN
    RCALL SPLIT_DIGITS_2
    STS DISPLAY_03, R17
    STS DISPLAY_04, R18

// =========================
APPLY_BLINK:

// Only in edit modes (odd modes)
    MOV R16, MODE
    ANDI R16, 0x01
    BREQ DISPLAY_EXIT

    LDS R16, BLINK_FLAG
    CPI R16, 0
    BRNE DISPLAY_EXIT

// Turn OFF selected digit
    MOV R16, ACTION
    CPI R16, 0
    BREQ BLANK_D0
    CPI R16, 1
    BREQ BLANK_D1
    CPI R16, 2
    BREQ BLANK_D2
    CPI R16, 3
    BREQ BLANK_D3
    RJMP DISPLAY_EXIT

BLANK_D0: CLR R16 // blank = 0
    STS DISPLAY_01, R16
    RJMP DISPLAY_EXIT

BLANK_D1:
    STS DISPLAY_02, R16
    RJMP DISPLAY_EXIT

BLANK_D2:
    STS DISPLAY_03, R16
    RJMP DISPLAY_EXIT

BLANK_D3:
    STS DISPLAY_04, R16

DISPLAY_EXIT:
    POP R16
    RET
MUX_HANDLER:

    PUSH R16

// ---- Turn OFF all digits ----
	CBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3

// ---- Select active digit ----
    LDS R16, MUX_SEL

    CPI R16, 0
    BREQ MUX_D0

    CPI R16, 1
    BREQ MUX_D1

    CPI R16, 2
    BREQ MUX_D2

// ---- Default → D3 ----
MUX_D3:
    SBI PORTB, PB3
    LDS R16, DISPLAY_04
    RJMP LOAD_SEGMENTS

MUX_D0:
    SBI PORTB, PB0
    LDS R16, DISPLAY_01
    RJMP LOAD_SEGMENTS

MUX_D1:
    SBI PORTB, PB1
    LDS R16, DISPLAY_02
    RJMP LOAD_SEGMENTS

MUX_D2:
    SBI PORTB, PB2
    LDS R16, DISPLAY_03

LOAD_SEGMENTS:
    RCALL SEGMENT_LOOKUP

    POP R16
    RET

SEGMENT_LOOKUP:

    PUSH ZL
    PUSH ZH

    LDI ZH, HIGH(SEG_TAB<<1)
    LDI ZL, LOW(SEG_TAB<<1)

    ADD ZL, R16
    BRCC NO_CARRY
    INC ZH
NO_CARRY:

    LPM R16, Z
    OUT PORTD, R16

    POP ZH
    POP ZL
    RET

SPLIT_DIGITS_2:

    PUSH R16
    PUSH R19

    CLR R17

DIV10_LOOP:
    CPI R16, 10
    BRLO DONE_DIV
    SUBI R16, 10
    INC R17
    RJMP DIV10_LOOP

DONE_DIV:
    MOV R18, R16

    POP R19
    POP R16
    RET
/*=========================================================
=                MODE MANAGER (FSM)                      =*/
MODE_MANAGER: // Checkeo de si la bandera fue activada o no
    LDS R16, FLAG_MODE
    CPI R16, 1
    BRNE EXIT_MODE

    CLR R16
    STS FLAG_MODE, R16

    INC MODE
    CPI MODE, 6
    BRLO OK
    CLR MODE

OK:
    CLR ACTION
    RCALL UPDATE_MODE_LEDS

EXIT_MODE:
    RET
	// CAMBIAR DE LED QUE SE ESTA USANDO 
UPDATE_MODE_LEDS:

    PUSH R16
    PUSH R17

    IN   R16, PORTC
    ANDI R16, 0b11001111     // LIMPIAR REGISTROS
    OUT  PORTC, R16

    CBI PORTB, PB5           // LIMPIAR REGISTROS

// Revisar modos de display
    MOV  R16, MODE
    ANDI R16, 0x01           
    BREQ SET_BASE_LED        

// Revisar modos de parpadeo
    LDS  R16, BLINK_FLAG
    CPI  R16, 0
    BREQ EXIT_UPDATE         

// Modos de Display 
SET_BASE_LED:

    CPI MODE, 2
    BRLO MODE_CLOCK

    CPI MODE, 4
    BRLO MODE_DATE

// Confirmacion de Displays de Modos
MODE_ALARM:
    SBI PORTC, PC5
    RJMP EXIT_UPDATE

MODE_DATE:
    SBI PORTB, PB5
    RJMP EXIT_UPDATE

MODE_CLOCK:
    SBI PORTC, PC4

EXIT_UPDATE:
    POP R17
    POP R16
    RET
/*=========================================================
=                EDIT ENGINE                             =*/
EDIT_ENGINE:

    MOV R16, MODE
    CPI R16, 1
    BREQ DO_EDIT

    CPI R16, 3
    BREQ DO_EDIT

    CPI R16, 5
    BREQ DO_EDIT

    RET

DO_EDIT:
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
RET

/*=========================================================
=                ALARM MANAGER                           =*/
ALARM_MANAGER:
    PUSH R16
    PUSH R17

// ---- Compare HOURS ----
    LDS R16, COUNT_HOUR
    LDS R17, ALARM_HOUR
    CP  R16, R17
    BRNE ALARM_OFF

// ---- Compare MINUTES ----
    LDS R16, COUNT_MIN
    LDS R17, ALARM_MIN
    CP  R16, R17
    BRNE ALARM_OFF

// ---- MATCH → ACTIVATE ALARM ----
ALARM_ON:
    LDI R16, 1
    STS ALARM_ACTIVE, R16

// ---- Output on PB4 ----
    LDS R16, BLINK_FLAG
    CPI R16, 0
    BREQ ALARM_LOW

    SBI PORTB, PB4
    RJMP ALARM_EXIT

ALARM_LOW:
    CBI PORTB, PB4
    RJMP ALARM_EXIT

// ---- NO MATCH ----
ALARM_OFF:
    CLR R16
    STS ALARM_ACTIVE, R16
    CBI PORTB, PB4

ALARM_EXIT:
    POP R17
    POP R16
    RET

/*=========================================================
=                DATE MANAGER                           =*/
DATE_INCREMENT:
    PUSH R16
    PUSH R17
    PUSH ZL
    PUSH ZH

// Incremento de día de manera automatica.
    LDS R16, DAY
    INC R16

// Llamado de tabla donde se encuentran los días máximos de cada mes.
    LDS R17, MONTH
    DEC R17                 // index = MONTH - 1

    LDI ZH, HIGH(MONTH_MAX_DAY<<1)
    LDI ZL, LOW(MONTH_MAX_DAY<<1)

    ADD ZL, R17
    CLR R17
    ADC ZH, R17

    LPM R17, Z              // R17 = max day

    CP R16, R17
    BRLO STORE_DAY          // if DAY < MAX → store

// Overflow de día
    LDI R16, 1
    STS DAY, R16

// Incremento AUTOMATICO de mes
    LDS R16, MONTH
    INC R16
    CPI R16, 13
    BRLO STORE_MONTH

// Overflow de Meses para evitar que pase de 12
    LDI R16, 1

STORE_MONTH:
    STS MONTH, R16
    RJMP DATE_EXIT

STORE_DAY:
    STS DAY, R16

DATE_EXIT:
    POP ZH
    POP ZL
    POP R17
    POP R16
    RET

//			     INTERRUPT ROUTINES                      //
/*=========================================================
=                TIMER0 ISR                              =*/
TIMER0_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16

    // Logica para Multiplex de un tick cada 10ms.
    LDS R16, TICKS_10MS
    INC R16
    STS TICKS_10MS, R16

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
=                TIMER1 ISR                              =*/
TIMER1_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

// Cuando se esta en un modo impar (edicion) manda señal para titilar de manera visible.
    LDS R16, BLINK_FLAG
    LDI R17, 1
    EOR R16, R17
    STS BLINK_FLAG, R16

// Logica de guardado de segundo habilitado por el Timer1
    LDS R16, HALFSEC_CNT
    INC R16
    CPI R16, 4
    BRLO T1_STORE_HALF // Cuenta la cantidad de interrupciones que tiene (hace una interrupcion cada 0.25ms)

    CLR R16
    STS HALFSEC_CNT, R16 // Cuenta los medios segundos

    LDS R16, SEC_CNT // Cuenta los segundos completos.
    INC R16
    CPI R16, 60
    BRLO T1_STORE_SEC

// Incremento AUTOMATICO de minuto
    CLR R16
    STS SEC_CNT, R16

    LDS R16, COUNT_MIN
    INC R16
    CPI R16, 60
    BRLO T1_STORE_MIN

// incremento AUTOMTICO de hora
    CLR R16
    STS COUNT_MIN, R16

    LDS R16, COUNT_HOUR
    INC R16
    CPI R16, 24
    BRLO T1_STORE_HOUR

// Cambio de Dia (Overflow al pasar de 23h)
    CLR R16
    STS COUNT_HOUR, R16

    RCALL DATE_INCREMENT
    RJMP EXIT_T1

T1_STORE_HOUR:
    STS COUNT_HOUR, R16
    RJMP EXIT_T1

T1_STORE_MIN:
    STS COUNT_MIN, R16
    RJMP EXIT_T1

T1_STORE_SEC:
    STS SEC_CNT, R16
    RJMP EXIT_T1

T1_STORE_HALF:
    STS HALFSEC_CNT, R16

EXIT_T1:
    POP R16
    OUT SREG, R16
    POP R17
    POP R16
    RETI

/*=========================================================
=                PIN CHANGE ISR                          =*/
PCINT_ISR:
    // Practicas generales de ISR.
   sbi portb, pb5
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    // Lee los inputs
    IN   R16, PINC
    ANDI R16, 0x0F      // Ignora PC4-PC5

    // Loica Inversa de PullUp, si detecta 0 entonces marca.
    COM  R16
    ANDI R16, 0x0F

    // PC0 → FLAG_UP
    SBRS R16, 0
    RJMP CHECK_PC1
    LDI  R17, 1
    STS  FLAG_UP, R17
    RJMP EXIT_PCINT

CHECK_PC1:
    // PC1 → FLAG_DOWN
    SBRS R16, 1
    RJMP CHECK_PC2
    LDI  R17, 1
    STS  FLAG_DOWN, R17
    RJMP EXIT_PCINT

CHECK_PC2:
    // PC2 → FLAG_MODE
    SBRS R16, 2
    RJMP CHECK_PC3
    LDI  R17, 1
    STS  FLAG_MODE, R17
    RJMP EXIT_PCINT

CHECK_PC3:
    // PC3 → FLAG_CONFIRM
    SBRS R16, 3
    RJMP EXIT_PCINT
    LDI  R17, 1
    STS  FLAG_CONFIRM, R17

EXIT_PCINT:
    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI

/*=========================================================
=                TIMER0 Y TIMER1 SETUP                     =*/
TIMER0_SETUP:
    // Configurar CTC con Prescaler de 64 con una comparacion de 62 e interrupciones habilitadas
    LDI R16, (1 << WGM01)
    OUT TCCR0A, R16

    LDI R16, (1 << CS01) | (1 << CS00)
    OUT TCCR0B, R16

    LDI R16, 62
    OUT OCR0A, R16

    LDI R16, (1 << OCIE0A)
    STS TIMSK0, R16

    CLR R16
    OUT TCNT0, R16
RET
  // Configura CTC con Prescaler de 1024 con valor de comparacion de 488 e interrupciones habilitadas
TIMER1_SETUP:
    LDI R16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
    STS TCCR1B, R16

    LDI R16, LOW(488)
    STS OCR1AL, R16
    LDI R16, HIGH(488)
    STS OCR1AH, R16

    LDI R16, (1 << OCIE1A)
    STS TIMSK1, R16

    CLR R16
    STS TCNT1H, R16
    STS TCNT1L, R16

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