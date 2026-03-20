.include "M328PDEF.inc"

/*======================
=       SRAM          =
======================*/
.dseg
.org SRAM_START

PREV_STATE: .BYTE 1   ; previous state of PC0-PC3

/*======================
=       CODE          =
======================*/
.cseg
.org 0x0000
    RJMP INIT

; --- Pin Change Interrupt Vector (PORTC = PCINT1) ---
.org 0x0008
    RJMP PCINT1_ISR

/*======================
=       INIT          =
======================*/
INIT:
    ; ---- Stack Pointer ----
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16

    ; ---- Configure LEDs as outputs ----
    SBI DDRC, PC4
    SBI DDRC, PC5
    SBI DDRB, PB5

    ; ---- Configure buttons as inputs ----
    CBI DDRC, PC0
    CBI DDRC, PC1
    CBI DDRC, PC2
    CBI DDRC, PC3

    ; Enable pull-ups
    SBI PORTC, PC0
    SBI PORTC, PC1
    SBI PORTC, PC2
    SBI PORTC, PC3

    ; ---- Save initial state ----
    IN R16, PINC
    ANDI R16, 0x0F
    STS PREV_STATE, R16

    ; ---- Enable PCINT for PC0-PC3 ----
    LDI R16, (1<<PCINT8)|(1<<PCINT9)|(1<<PCINT10)|(1<<PCINT11)
    STS PCMSK1, R16

    ; Enable PCINT1 group
    LDI R16, (1<<PCIE1)
    STS PCICR, R16

    ; ---- Global Interrupt Enable ----
    SEI

MAIN:
    RJMP MAIN

/*======================
=   PCINT1 ISR        =
======================*/
PCINT1_ISR:
    PUSH R16
    PUSH R17

    ; Read current state
    IN R16, PINC
    ANDI R16, 0x0F

    ; Load previous state
    LDS R17, PREV_STATE

    ; Detect change
    EOR R16, R17        ; bits that changed

    ; Save new state
    IN R17, PINC
    ANDI R17, 0x0F
    STS PREV_STATE, R17

    ; ---- Check each button ----

    ; BTN1 (PC0)
    SBRS R16, 0
    RJMP CHECK_BTN2
    SBI PINC, PC4       ; toggle PC4

CHECK_BTN2:
    ; BTN2 (PC1)
    SBRS R16, 1
    RJMP CHECK_BTN3
    SBI PINC, PC5       ; toggle PC5

CHECK_BTN3:
    ; BTN3 (PC2)
    SBRS R16, 2
    RJMP CHECK_BTN4
    SBI PINB, PB5       ; toggle PB5

CHECK_BTN4:
    ; BTN4 (PC3)
    SBRS R16, 3
    RJMP END_ISR
    SBI PINC, PC4       ; reuse PC4

END_ISR:
    POP R17
    POP R16
    RETI