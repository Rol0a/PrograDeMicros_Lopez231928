import sys
import time
import serial

from Adafruit_IO import MQTTClient

from config import (
    ADAFRUIT_IO_USERNAME,
    ADAFRUIT_IO_KEY,
    SERIAL_PORT,
    BAUDRATE
)

# =========================================================
# FEED KEYS
# =========================================================

FEED_RX = "atwalk-rx"
FEED_TX = "atwalk-tx"

FEED_MODE = "mode"
FEED_SAVE = "save-pos"

# =========================================================
# FEEDBACK FEEDS
# =========================================================

FEED_SERVO0_FB = "servo0-feedback"
FEED_SERVO1_FB = "servo1-feedback"
FEED_SERVO2_FB = "servo2-feedback"
FEED_SERVO3_FB = "servo3-feedback"

FEED_MODE_FB = "mode-feedback"

# =========================================================
# SERVO FEEDS
#
# Feed -> Servo Number
#
# S0 -> OCR2A
# S1 -> OCR2B
# S2 -> OCR1A
# S3 -> OCR1B
# =========================================================

SERVO_FEEDS = {
    "ocr2a": 0,
    "ocr2b": 1,
    "ocr1a": 2,
    "ocr1b": 3
}

# =========================================================
# FEEDBACK MAPPING
# =========================================================

FEEDBACK_FEEDS = {
    0: FEED_SERVO0_FB,
    1: FEED_SERVO1_FB,
    2: FEED_SERVO2_FB,
    3: FEED_SERVO3_FB
}

# =========================================================
# GLOBAL VARIABLES
# =========================================================

servo_values = {
    0: 0,
    1: 0,
    2: 0,
    3: 0
}

current_mode = 0

# =========================================================
# SERIAL COMMUNICATION
# =========================================================

def enviar_arduino(comando):

    comando = str(comando).strip()

    if comando == "":
        return

    print("================================")
    print("Enviando a Arduino:")
    print(comando)
    print("================================")

    myArduino.write(
        (comando + "\n").encode("utf-8")
    )

# =========================================================
# MQTT CALLBACKS
# =========================================================

def connected(client):

    print("================================")
    print("Conectado a Adafruit IO")
    print("================================")

    # =====================================================
    # GENERAL FEEDS
    # =====================================================

    client.subscribe(FEED_RX)
    client.subscribe(FEED_MODE)
    client.subscribe(FEED_SAVE)

    print("Suscrito:", FEED_RX)
    print("Suscrito:", FEED_MODE)
    print("Suscrito:", FEED_SAVE)

    # =====================================================
    # SERVO FEEDS
    # =====================================================

    for feed in SERVO_FEEDS:

        client.subscribe(feed)

        print("Suscrito:", feed)

    print("================================")
    print("Sistema listo")
    print("================================")

# =========================================================

def disconnected(client):

    print("Desconectado")

    sys.exit(1)

# =========================================================

def message(client, feed_id, payload):

    global servo_values

    print("--------------------------------")
    print("Feed:", feed_id)
    print("Payload:", payload)
    print("--------------------------------")

    # =====================================================
    # RAW UART COMMANDS
    # =====================================================

    if feed_id == FEED_RX:

        enviar_arduino(payload)

        return

    # =====================================================
    # MODE BUTTON
    # Sends:
    # M
    # =====================================================

    if feed_id == FEED_MODE:

        # Only react on press
        if payload == "1":

            enviar_arduino("M")

        return

    # =====================================================
    # EEPROM SAVE BUTTON
    # Sends:
    # S
    # =====================================================

    if feed_id == FEED_SAVE:

        if payload == "1":

            enviar_arduino("S")

        return

    # =====================================================
    # SERVO CONTROL
    # Sends:
    # S0:120
    # =====================================================

    if feed_id in SERVO_FEEDS:

        servo = SERVO_FEEDS[feed_id]

        try:

            valor = int(float(payload))

        except:

            print("Valor inválido")

            return

        # =================================================
        # LIMIT RANGE 0-180
        # =================================================

        valor = max(0, min(180, valor))

        servo_values[servo] = valor

        print(f"Servo {servo} -> {valor}")

        # =================================================
        # BUILD UART COMMAND
        # =================================================

        comando = f"S{servo}:{valor}"

        enviar_arduino(comando)

        return

# =========================================================
# PROCESS ARDUINO TELEMETRY
# =========================================================

def procesar_telemetria(respuesta):

    global current_mode
    global servo_values

    # =====================================================
    # SERVO FEEDBACK
    # FORMAT:
    # P0:120
    # =====================================================

    if respuesta.startswith("P"):

        try:

            partes = respuesta.split(":")

            servo = int(partes[0][1:])

            valor = int(partes[1])

            if servo in FEEDBACK_FEEDS:

                servo_values[servo] = valor

                client.publish(
                    FEEDBACK_FEEDS[servo],
                    valor
                )

                print(
                    f"Feedback Servo {servo}: "
                    f"{valor}"
                )

        except Exception as e:

            print("Error telemetría servo:", e)

    # =====================================================
    # MODE FEEDBACK
    # FORMAT:
    # MODE:1
    # =====================================================

    elif respuesta.startswith("MODE:"):

        try:

            modo = int(
                respuesta.split(":")[1]
            )

            current_mode = modo

            client.publish(
                FEED_MODE_FB,
                modo
            )

            print(f"Modo actual: {modo}")

        except Exception as e:

            print("Error telemetría modo:", e)

    # =====================================================
    # OTHER UART MESSAGES
    # =====================================================

    else:

        client.publish(
            FEED_TX,
            respuesta
        )

# =========================================================
# MAIN PROGRAM
# =========================================================

try:

    print("================================")
    print("Abriendo puerto serial...")
    print("================================")

    myArduino = serial.Serial(
        port=SERIAL_PORT,
        baudrate=BAUDRATE,
        timeout=0.1
    )

    time.sleep(2)

    print("================================")
    print("Serial conectado")
    print("================================")

    # =====================================================
    # MQTT SETUP
    # =====================================================

    print("================================")
    print("Conectando MQTT...")
    print("================================")

    client = MQTTClient(
        ADAFRUIT_IO_USERNAME,
        ADAFRUIT_IO_KEY
    )

    client.on_connect = connected

    client.on_disconnect = disconnected

    client.on_message = message

    client.connect()

    client.loop_background()

    print("================================")
    print("MQTT iniciado")
    print("================================")

    # =====================================================
    # MAIN LOOP
    # =====================================================

    while True:

        # =================================================
        # READ SERIAL RESPONSES
        # =================================================

        if myArduino.in_waiting > 0:

            respuesta = (
                myArduino.readline()
                .decode(
                    "utf-8",
                    errors="ignore"
                )
                .strip()
            )

            if respuesta:

                print("Arduino:", respuesta)

                procesar_telemetria(
                    respuesta
                )

        # =================================================
        # DEBUG STATUS
        # =================================================

        print("============== ESTADO ==============")

        print(f"Modo actual: {current_mode}")

        for servo in servo_values:

            print(
                f"Servo {servo} = "
                f"{servo_values[servo]} grados"
            )

        print("====================================")

        time.sleep(1)

# =========================================================
# EXIT
# =========================================================

except KeyboardInterrupt:

    print("Programa terminado")

except Exception as e:

    print("================================")
    print("ERROR:", e)
    print("================================")

finally:

    try:

        if myArduino.is_open:

            myArduino.close()

            print("Puerto serial cerrado")

    except:

        pass