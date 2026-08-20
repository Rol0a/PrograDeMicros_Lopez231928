# Programación de Microcontroladores — ATmega328P

<p align="center">
  <strong>Laboratorios de programación de bajo nivel, periféricos e infraestructura embebida sobre arquitectura AVR.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/MCU-ATmega328P-00599C?style=for-the-badge" alt="ATmega328P">
  <img src="https://img.shields.io/badge/Platform-Arduino%20Nano-00979D?style=for-the-badge&logo=arduino&logoColor=white" alt="Arduino Nano">
  <img src="https://img.shields.io/badge/Language-AVR%20Assembly-6E4C13?style=for-the-badge" alt="AVR Assembly">
  <img src="https://img.shields.io/badge/Embedded-Bare%20Metal-555555?style=for-the-badge" alt="Bare Metal">
</p>

---

## Descripción

Este repositorio reúne los laboratorios y proyectos desarrollados para **Programación de Microcontroladores**, utilizando principalmente el microcontrolador **ATmega328P**.

Los laboratorios están orientados al desarrollo de firmware de bajo nivel mediante **AVR Assembly**, trabajando directamente con registros, memoria y periféricos internos del microcontrolador.

El objetivo no es únicamente lograr que un periférico funcione, sino comprender cómo el software interactúa directamente con el hardware:

- Arquitectura AVR y programación en Assembly
- Manipulación directa de registros
- GPIO
- Timers/Counters
- Interrupciones
- ADC
- PWM
- UART/USART
- Manejo de memoria y stack
- Rutinas y subrutinas
- Infraestructura reutilizable para firmware en Assembly

La secuencia de laboratorios desarrolla progresivamente una base para construir sistemas embebidos de mayor complejidad.

---

# Tecnologías

<p align="center">
  <img src="https://img.shields.io/badge/Microchip-ATmega328P-EE1F25?style=flat-square&logo=microchip&logoColor=white" alt="ATmega328P">
  <img src="https://img.shields.io/badge/AVR-Assembly-333333?style=flat-square" alt="AVR Assembly">
  <img src="https://img.shields.io/badge/Arduino-Nano-00979D?style=flat-square&logo=arduino&logoColor=white" alt="Arduino Nano">
  <img src="https://img.shields.io/badge/Embedded-Bare%20Metal-555555?style=flat-square" alt="Bare Metal">
  <img src="https://img.shields.io/badge/Git-Version%20Control-F05032?style=flat-square&logo=git&logoColor=white" alt="Git">
  <img src="https://img.shields.io/badge/GitHub-Repository-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub">
</p>

---

# Arquitectura de aprendizaje

Los laboratorios siguen una progresión desde operaciones básicas sobre la arquitectura AVR hasta el desarrollo de infraestructura embebida reutilizable.

```text
                    Application
                         │
                         ▼
                AVR Assembly Code
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
         ADC            PWM            UART
          │              │              │
          └──────────────┼──────────────┘
                         │
                         ▼
               Timers / Interrupts
                         │
                         ▼
               Register Manipulation
                         │
                         ▼
                    GPIO / I/O
                         │
                         ▼
                    ATmega328P
```

Cada etapa introduce nuevos recursos del microcontrolador y los integra con los conceptos desarrollados anteriormente.

---

# Contenido de los laboratorios

## 1. AVR Assembly

Los primeros ejercicios establecen las bases para trabajar directamente con la arquitectura AVR.

Los conceptos incluyen:

- instrucciones AVR;
- registros de propósito general;
- registros especiales;
- operaciones aritméticas;
- operaciones lógicas;
- manipulación de bits;
- comparaciones;
- saltos condicionales;
- loops;
- subrutinas;
- stack;
- acceso a memoria.

El objetivo es comprender cómo las instrucciones ejecutadas por el procesador producen directamente el comportamiento observado en el hardware.

---

## 2. GPIO — Entrada y salida digital

La manipulación de **GPIO** constituye una de las primeras interacciones directas con el hardware.

```text
AVR Assembly
     │
     ▼
┌──────────┐
│   DDRx   │  ← Dirección
├──────────┤
│  PORTx   │  ← Salida / Pull-up
├──────────┤
│   PINx   │  ← Entrada
└────┬─────┘
     │
     ▼
Physical GPIO
```

Esto permite controlar y leer dispositivos como:

- LEDs;
- botones;
- switches;
- señales digitales;
- actuadores simples.

La configuración se realiza directamente mediante registros del ATmega328P.

---

# ADC — Analog-to-Digital Converter

El **ADC** permite convertir señales analógicas externas en valores digitales procesables por el microcontrolador.

```text
Analog Signal
      │
      ▼
┌─────────────┐
│ Multiplexer │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     ADC     │
└──────┬──────┘
       │
       ▼
Digital Result
       │
       ▼
AVR Firmware
```

Los laboratorios permiten estudiar conceptos como:

- selección del canal analógico;
- referencia de voltaje;
- configuración del ADC;
- inicio de conversión;
- detección de conversión terminada;
- lectura del resultado;
- procesamiento de datos adquiridos.

Esto introduce la adquisición de sensores analógicos dentro de sistemas embebidos.

---

# Timers y Counters

Los **Timers/Counters** proporcionan una base de tiempo controlada por hardware.

```text
System Clock
     │
     ▼
 Prescaler
     │
     ▼
Timer/Counter
     │
     ├────► Overflow
     │
     ├────► Compare Match
     │
     └────► PWM
```

Su utilización permite reducir la dependencia de retardos implementados exclusivamente mediante software.

Los timers sirven posteriormente como infraestructura para:

- generación de PWM;
- medición de tiempo;
- eventos periódicos;
- interrupciones;
- generación de señales.

---

# PWM — Pulse Width Modulation

La **modulación por ancho de pulso** permite generar una señal digital periódica cuyo ciclo de trabajo puede ser controlado mediante hardware.

```text
        ┌───────┐
        │       │
────────┘       └────────
        <------>
        Duty Cycle
```

Conceptualmente:

```text
Clock
  │
  ▼
Timer
  │
  ▼
Compare Register
  │
  ▼
PWM Generator
  │
  ▼
Output Pin
```

PWM constituye una herramienta fundamental para aplicaciones como:

- control de intensidad de LEDs;
- generación de señales;
- control de actuadores;
- control de motores;
- sistemas de potencia.

---

# UART / USART

Los laboratorios también introducen comunicación serial utilizando el periférico **UART/USART** del ATmega328P.

```text
ATmega328P                     Computer / MCU
┌────────────┐                 ┌─────────────┐
│            │                 │             │
│        TXD ├────────────────►│ RX          │
│            │                 │             │
│        RXD │◄────────────────┤ TX          │
│            │                 │             │
└────────────┘                 └─────────────┘
```

Esto introduce conceptos como:

- transmisión serial;
- recepción serial;
- baud rate;
- registros de datos;
- flags de estado;
- polling;
- interrupciones asociadas a comunicación.

UART también constituye una herramienta importante para **debugging y telemetría** en sistemas embebidos.

---

# Interrupciones

Las interrupciones permiten que el procesador responda a eventos sin revisar continuamente el estado de cada periférico.

```text
        Main Program
             │
             │
             │     Hardware Event
             │           │
             │           ▼
             │      Interrupt
             │           │
             │           ▼
             │          ISR
             │           │
             ◄───────────┘
             │
             ▼
      Continue Program
```

Los laboratorios permiten introducir conceptos como:

- vectores de interrupción;
- Interrupt Service Routines (ISR);
- preservación del contexto;
- eventos asíncronos;
- interrupciones de timers;
- interrupciones de periféricos.

Este paradigma permite construir firmware más eficiente y reactivo.

---

# Infraestructura embebida en Assembly

Uno de los objetivos importantes del conjunto de laboratorios es pasar de programas aislados hacia una estructura reutilizable de firmware.

```text
┌──────────────────────────────────────┐
│             Application              │
├──────────────────────────────────────┤
│        Peripheral Routines           │
├─────────┬─────────┬─────────┬────────┤
│  GPIO   │   ADC   │   PWM   │  UART  │
├─────────┴─────────┴─────────┴────────┤
│ Timers │ Interrupts │ Register Setup │
├──────────────────────────────────────┤
│          AVR Assembly Layer          │
├──────────────────────────────────────┤
│              ATmega328P              │
└──────────────────────────────────────┘
```

Esto implica desarrollar progresivamente:

- rutinas de inicialización;
- configuración centralizada de registros;
- constantes;
- subrutinas reutilizables;
- configuración de periféricos;
- funciones de comunicación;
- manejo de interrupciones;
- separación entre hardware y lógica de aplicación.

Aunque no representa un **HAL completo**, esta organización introduce principios utilizados en arquitecturas profesionales de firmware.

---

# Laboratorios

El repositorio contiene una secuencia de laboratorios que incrementan progresivamente la interacción con el ATmega328P.

```text
PrograDeMicros_Lopez231928/
│
├── Lab0_PrograDeMicros_LopezA231928/
├── Lab1_PrograDeMicros_LopezA231928/
├── Lab2_PrograDeMicros_LópezA231928/
├── Lab3_PrograDeMicros_LópezA231928/
├── Lab4_PrograDeMicros_LopezA231928/
├── Lab5_PrograDeMicros_LopezA231928/
├── Lab6_PrograDeMicros_LopezA231928/
│
├── PROYECTO1_PrograDeMicros_LópezA/
├── PROYECTO2_PrograDeMicros_LopezA/
│
├── TesteoTemp/
├── XC8Library1/
│
├── m328p configuration file.txt
│
└── README.md
```

Los laboratorios representan diferentes etapas de interacción con el microcontrolador, mientras que los proyectos integran múltiples conceptos desarrollados durante el curso.

---

# Hardware

## ATmega328P

El microcontrolador principal utilizado es el **ATmega328P**, perteneciente a la arquitectura AVR de 8 bits.

Durante los laboratorios se interactúa directamente con sus recursos internos.

| Recurso | Aplicación |
|---|---|
| CPU AVR | Ejecución de instrucciones Assembly |
| GPIO | Entrada y salida digital |
| ADC | Adquisición de señales analógicas |
| Timers/Counters | Temporización y conteo |
| PWM | Generación de señales moduladas |
| UART/USART | Comunicación serial |
| Interrupts | Manejo de eventos asíncronos |
| SRAM | Variables y stack |
| Flash | Almacenamiento del programa |

---

# Plataforma de desarrollo

La plataforma utilizada es principalmente **Arduino Nano**, aprovechando el ATmega328P integrado en la placa.

Sin embargo, el enfoque de los laboratorios no consiste en utilizar únicamente las abstracciones de Arduino.

En cambio:

```text
Arduino-style abstraction

digitalWrite()
analogRead()
Serial.begin()
analogWrite()

          ↓

--------------------------------

Direct AVR interaction

DDRx
PORTx
ADMUX
ADCSRA
TCCRnA
TCCRnB
OCRnx
UBRR
UCSRn
UDR
```

Esto permite comprender qué ocurre internamente cuando frameworks de alto nivel configuran el microcontrolador.

---

# Objetivos de aprendizaje

La secuencia de laboratorios busca desarrollar la capacidad de:

1. Programar microcontroladores AVR mediante Assembly.
2. Comprender la arquitectura básica del ATmega328P.
3. Manipular registros directamente.
4. Configurar GPIO sin abstracciones de alto nivel.
5. Utilizar timers y counters.
6. Generar señales PWM.
7. Adquirir señales analógicas mediante ADC.
8. Implementar comunicación UART/USART.
9. Utilizar interrupciones y rutinas ISR.
10. Manejar memoria, stack y subrutinas.
11. Crear rutinas reutilizables para periféricos.
12. Integrar múltiples periféricos dentro de una aplicación embebida.

---

# Progresión del curso

La progresión técnica del repositorio puede representarse como:

```text
AVR Instructions
       │
       ▼
Register Manipulation
       │
       ▼
GPIO + Memory
       │
       ▼
Timers + Interrupts
       │
       ├─────────────┐
       ▼             ▼
      ADC           PWM
       │             │
       └──────┬──────┘
              ▼
             UART
              │
              ▼
   Embedded Infrastructure
              │
              ▼
      Integrated Projects
```

Esta progresión conecta programación en assembler con conceptos utilizados posteriormente en:

- Embedded Systems
- Firmware Engineering
- Electronics
- Mechatronics
- Robotics
- Digital Control
- Hardware/Software Integration

---

# Del registro al sistema embebido

Una parte fundamental del curso consiste en comprender que un sistema embebido completo se construye progresivamente desde operaciones muy pequeñas.

```text
Instruction
    ↓
Register
    ↓
Peripheral
    ↓
Driver / Routine
    ↓
Subsystem
    ↓
Application
    ↓
Embedded System
```

Por esta razón, los laboratorios no se limitan al resultado visible del circuito.

El objetivo es comprender la cadena completa entre:

**hardware → registros → instrucciones → firmware → comportamiento del sistema.**

---

# Aplicaciones posteriores

Los conocimientos desarrollados en estos laboratorios proporcionan una base para proyectos más avanzados relacionados con:

- control de motores;
- adquisición de sensores;
- sistemas de comunicación;
- control digital;
- robots móviles;
- sistemas mecatrónicos;
- firmware bare-metal;
- sistemas de tiempo real;
- diseño de drivers;
- integración hardware/software.

---

# Repositorio académico

Este repositorio documenta ejercicios, laboratorios y proyectos desarrollados como parte del curso de **Programación de Microcontroladores**.

Su propósito es servir como:

- evidencia del proceso de aprendizaje;
- documentación técnica;
- referencia para programación AVR;
- portafolio de desarrollo de sistemas embebidos.

> **Nota:** El código de este repositorio corresponde principalmente a ejercicios académicos y experimentales. Antes de reutilizarlo en sistemas críticos o aplicaciones de producción deben verificarse temporización, manejo de errores, condiciones de carrera, límites eléctricos y comportamiento ante fallos.
