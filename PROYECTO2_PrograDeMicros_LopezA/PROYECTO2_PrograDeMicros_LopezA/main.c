/*
 * PROYECTO2_PrograDeMicros_LopezA.c
 *
 * Created: 4/5/2026 23:44:18
 * Author : Rodrigo López
 * Descripción:
 */

// LIBRARIES

#define F_CPU 2000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "ADC/ADC.h"
#include "PWM_8bits/PWM_8bits.h"
#include "PWM_16bits/PWM_16bits.h"
#include "UART/UART.h"
#include "EEPROM/EEPROM.h"

/****************************************/
// EEPROM ADDRESSES

#define EEPROM_MOTOR0_ADDR      0x00
#define EEPROM_MOTOR1_ADDR      0x01

#define EEPROM_MOTOR2_LOW       0x02
#define EEPROM_MOTOR2_HIGH      0x03

#define EEPROM_MOTOR3_LOW       0x04
#define EEPROM_MOTOR3_HIGH      0x05

/****************************************/
// MODES

#define MODE_MANUAL     0
#define MODE_UART       1
#define MODE_EEPROM     2

/****************************************/
// GLOBAL VARIABLES

volatile uint8_t current_mode = MODE_MANUAL;

/****************************************/
// PWM VARIABLES

volatile uint8_t pwm_motor0 = 0;
volatile uint8_t pwm_motor1 = 0;

volatile uint16_t pwm_motor2 = 0;
volatile uint16_t pwm_motor3 = 0;

/****************************************/
// UART VARIABLES

char uart_buffer[16];

volatile uint8_t uart_index = 0;

/****************************************/
// FUNCTION PROTOTYPES

void setup(void);

/* MODES */
void mode_manual(void);
void mode_uart(void);
void mode_eeprom(void);

/* UART */
void check_uart(void);
void process_uart_command(void);

/* MODE LEDS */
void update_mode_leds(void);

/* EEPROM */
void save_current_positions(void);
void load_saved_positions(void);

/* SERVO */
void set_servo(uint8_t servo,
               uint8_t angle);

uint8_t map_servo_8bit(uint8_t angle);

uint16_t map_servo_16bit(uint8_t angle);

/* TELEMETRY */
void send_servo_positions(void);

uint8_t pwm_to_angle_8bit(uint8_t pwm);

uint8_t pwm_to_angle_16bit(uint16_t pwm);

/****************************************/
// MAIN FUNCTION

int main(void)
{
    cli();

    setup();

    ADC_init();

    PWM_8bits_init();

    PWM_16bits_init();

    UART_init();

    sei();

    while (1)
    {
        /****************************************/
        // ALWAYS CHECK UART

        check_uart();

        /****************************************/
        // UPDATE LEDs

        update_mode_leds();

        /****************************************/
        // MODE STATE MACHINE

        switch (current_mode)
        {
            case MODE_MANUAL:

                mode_manual();

                break;

            case MODE_UART:

                mode_uart();

                break;

            case MODE_EEPROM:

                mode_eeprom();

                break;

            default:

                current_mode = MODE_MANUAL;

                break;
        }
    }
}

/****************************************/
// SETUP

void setup(void)
{
    /****************************************/
    // CLOCK = 2 MHz

    CLKPR = (1 << CLKPCE);

    CLKPR = (1 << CLKPS1);

    /****************************************/
    // MODE LEDs

    DDRD |= (1 << DDD4) |
             (1 << DDD5) |
             (1 << DDD6);

    PORTD &= ~((1 << PORTD4) |
               (1 << PORTD5) |
               (1 << PORTD6));
}

/****************************************/
// MODE 0
// MANUAL CONTROL

void mode_manual(void)
{
    /****************************************/
    // MOTOR 0 -> OCR2A

    pwm_motor0 =
        31 +
        ((uint32_t)adc_values[0] * 125) / 1023;

    PWM8_setDuty2(pwm_motor0);

    /****************************************/
    // MOTOR 1 -> OCR2B

    pwm_motor1 =
        31 +
        ((uint32_t)adc_values[1] * 125) / 1023;

    PWM8_setDuty3(pwm_motor1);

    /****************************************/
    // MOTOR 2 -> OCR1A

    pwm_motor2 =
        125 +
        ((uint32_t)adc_values[2] * 500) / 1023;

    PWM16_setDutyA(pwm_motor2);

    /****************************************/
    // MOTOR 3 -> OCR1B

    pwm_motor3 =
        125 +
        ((uint32_t)adc_values[3] * 500) / 1023;

    PWM16_setDutyB(pwm_motor3);
}

/****************************************/
// MODE 1
// UART CONTROL

void mode_uart(void)
{
    /*
     * UART controls PWM
     */
}

/****************************************/
// MODE 2
// EEPROM PLAYBACK

void mode_eeprom(void)
{
    static uint8_t loaded = 0;

    if (!loaded)
    {
        load_saved_positions();

        send_servo_positions();

        loaded = 1;
    }

    if (current_mode != MODE_EEPROM)
    {
        loaded = 0;
    }
}

/****************************************/
// UART RECEIVER

void check_uart(void)
{
    if (uart_flag)
    {
        uart_flag = 0;

        /****************************************/
        // END OF COMMAND

        if (uart_data == '\r' ||
            uart_data == '\n')
        {
            if (uart_index > 0)
            {
                uart_buffer[uart_index] = '\0';

                process_uart_command();

                uart_index = 0;

                /****************************************/
                // CLEAR BUFFER

                for (uint8_t j = 0;
                     j < 16;
                     j++)
                {
                    uart_buffer[j] = '\0';
                }
            }
        }

        /****************************************/
        // BUFFER RECEPTION

        else
        {
            if (uart_index < 15)
            {
                uart_buffer[uart_index] =
                    uart_data;

                uart_index++;
            }

            else
            {
                uart_index = 0;

                UART_sendString(
                    "Buffer lleno\r\n"
                );
            }
        }
    }
}

/****************************************/
// UART COMMAND PROCESSOR

void process_uart_command(void)
{
    uint8_t servo = 0;

    uint16_t angle = 0;

    uint8_t i = 0;

    /****************************************/
    // MODE CHANGE

    if (strcmp(uart_buffer, "M") == 0)
    {
        current_mode++;

        if (current_mode > 2)
        {
            current_mode = 0;
        }

        UART_sendString(
            "Modo cambiado\r\n"
        );

        send_servo_positions();

        return;
    }

    /****************************************/
    // EEPROM SAVE

    if (strcmp(uart_buffer, "S") == 0)
    {
        if (current_mode == MODE_MANUAL)
        {
            save_current_positions();

            UART_sendString(
                "EEPROM guardada\r\n"
            );
        }

        return;
    }

    /****************************************/
    // UART MODE REQUIRED

    if (current_mode != MODE_UART)
    {
        UART_sendString(
            "No UART mode\r\n"
        );

        return;
    }

    /****************************************/
    // COMMAND FORMAT
    // S0:120

    if (uart_buffer[0] != 'S')
    {
        UART_sendString(
            "Comando invalido\r\n"
        );

        return;
    }

    /****************************************/
    // SERVO VALIDATION

    if (uart_buffer[1] < '0' ||
        uart_buffer[1] > '3')
    {
        UART_sendString(
            "Servo invalido\r\n"
        );

        return;
    }

    /****************************************/
    // FORMAT VALIDATION

    if (uart_buffer[2] != ':')
    {
        UART_sendString(
            "Formato invalido\r\n"
        );

        return;
    }

    /****************************************/
    // SERVO NUMBER

    servo =
        uart_buffer[1] - '0';

    /****************************************/
    // ANGLE PARSER

    i = 3;

    while (uart_buffer[i] >= '0' &&
           uart_buffer[i] <= '9')
    {
        angle =
            (angle * 10) +
            (uart_buffer[i] - '0');

        i++;
    }

    /****************************************/
    // LIMIT ANGLE

    if (angle > 180)
    {
        angle = 180;
    }

    /****************************************/
    // APPLY SERVO

    set_servo(servo, angle);

    UART_sendString(
        "Servo actualizado\r\n"
    );

    send_servo_positions();
}

/****************************************/
// SERVO SETTER

void set_servo(uint8_t servo,
               uint8_t angle)
{
    switch (servo)
    {
        /****************************************/
        // OCR2A

        case 0:

            PWM8_setDuty2(
                map_servo_8bit(angle)
            );

            break;

        /****************************************/
        // OCR2B

        case 1:

            PWM8_setDuty3(
                map_servo_8bit(angle)
            );

            break;

        /****************************************/
        // OCR1A

        case 2:

            PWM16_setDutyA(
                map_servo_16bit(angle)
            );

            break;

        /****************************************/
        // OCR1B

        case 3:

            PWM16_setDutyB(
                map_servo_16bit(angle)
            );

            break;
    }
}

/****************************************/
// MAP 8-BIT PWM

uint8_t map_servo_8bit(uint8_t angle)
{
    return 31 +
           ((uint32_t)angle * 125) / 180;
}

/****************************************/
// MAP 16-BIT PWM

uint16_t map_servo_16bit(uint8_t angle)
{
    return 125 +
           ((uint32_t)angle * 500) / 180;
}

/****************************************/
// EEPROM SAVE

void save_current_positions(void)
{
    EEPROM_write(
        EEPROM_MOTOR0_ADDR,
        OCR2A
    );

    EEPROM_write(
        EEPROM_MOTOR1_ADDR,
        OCR2B
    );

    EEPROM_write(
        EEPROM_MOTOR2_LOW,
        OCR1A & 0xFF
    );

    EEPROM_write(
        EEPROM_MOTOR2_HIGH,
        (OCR1A >> 8) & 0xFF
    );

    EEPROM_write(
        EEPROM_MOTOR3_LOW,
        OCR1B & 0xFF
    );

    EEPROM_write(
        EEPROM_MOTOR3_HIGH,
        (OCR1B >> 8) & 0xFF
    );
}

/****************************************/
// EEPROM LOAD

void load_saved_positions(void)
{
    uint16_t temp_motor2 = 0;

    uint16_t temp_motor3 = 0;

    PWM8_setDuty2(
        EEPROM_read(
            EEPROM_MOTOR0_ADDR
        )
    );

    PWM8_setDuty3(
        EEPROM_read(
            EEPROM_MOTOR1_ADDR
        )
    );

    temp_motor2 =
        EEPROM_read(
            EEPROM_MOTOR2_LOW
        );

    temp_motor2 |=
        ((uint16_t)
        EEPROM_read(
            EEPROM_MOTOR2_HIGH
        )) << 8;

    PWM16_setDutyA(temp_motor2);

    temp_motor3 =
        EEPROM_read(
            EEPROM_MOTOR3_LOW
        );

    temp_motor3 |=
        ((uint16_t)
        EEPROM_read(
            EEPROM_MOTOR3_HIGH
        )) << 8;

    PWM16_setDutyB(temp_motor3);
}

/****************************************/
// PWM TO ANGLE

uint8_t pwm_to_angle_8bit(uint8_t pwm)
{
    if (pwm < 31)
    {
        pwm = 31;
    }

    return
        ((uint32_t)(pwm - 31) * 180)
        / 125;
}

/****************************************/

uint8_t pwm_to_angle_16bit(uint16_t pwm)
{
    if (pwm < 125)
    {
        pwm = 125;
    }

    return
        ((uint32_t)(pwm - 125) * 180)
        / 500;
}

/****************************************/
// TELEMETRY

void send_servo_positions(void)
{
    char buffer[32];

    sprintf(
        buffer,
        "P0:%u\r\n",
        pwm_to_angle_8bit(OCR2A)
    );

    UART_sendString(buffer);

    sprintf(
        buffer,
        "P1:%u\r\n",
        pwm_to_angle_8bit(OCR2B)
    );

    UART_sendString(buffer);

    sprintf(
        buffer,
        "P2:%u\r\n",
        pwm_to_angle_16bit(OCR1A)
    );

    UART_sendString(buffer);

    sprintf(
        buffer,
        "P3:%u\r\n",
        pwm_to_angle_16bit(OCR1B)
    );

    UART_sendString(buffer);

    sprintf(
        buffer,
        "MODE:%u\r\n",
        current_mode
    );

    UART_sendString(buffer);
}

/****************************************/
// MODE LEDs

void update_mode_leds(void)
{
    PORTD &= ~((1 << PORTD4) |
               (1 << PORTD5) |
               (1 << PORTD6));

    switch (current_mode)
    {
        case MODE_MANUAL:

            PORTD |= (1 << PORTD4);

            break;

        case MODE_UART:

            PORTD |= (1 << PORTD5);

            break;

        case MODE_EEPROM:

            PORTD |= (1 << PORTD6);

            break;
    }
}