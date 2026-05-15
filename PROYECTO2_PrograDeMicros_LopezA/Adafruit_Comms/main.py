# Import standard python modules.
import sys
import time

# MQTT Client from Adafruit IO
from Adafruit_IO import MQTTClient

# =========================================================
# ADAFRUIT IO CONFIGURATION
# =========================================================

ADAFRUIT_IO_USERNAME = "user"
ADAFRUIT_IO_KEY = "nosecomopushearesto"

# =========================================================
# FEED DEFINITIONS
# =========================================================

# Sliders from dashboard -> Python
FEED_SERVO1 = "SERVO1"
FEED_SERVO2 = "SERVO2"
FEED_SERVO3 = "SERVO3"
FEED_SERVO4 = "SERVO4"

# Gauges from Python -> Dashboard
FEED_SERVO1_ACTUAL = "SERVO1_ACTUAL"
FEED_SERVO2_ACTUAL = "SERVO2_ACTUAL"
FEED_SERVO3_ACTUAL = "SERVO3_ACTUAL"
FEED_SERVO4_ACTUAL = "SERVO4_ACTUAL"

# =========================================================
# GLOBAL VARIABLES
# =========================================================

servo1 = 90
servo2 = 90
servo3 = 90
servo4 = 90

# =========================================================
# CALLBACK FUNCTIONS
# =========================================================

def connected(client):
    """
    Called when connected to Adafruit IO.
    """

    print("Connected to Adafruit IO")

    # Subscribe to feeds
    client.subscribe(FEED_SERVO1)
    client.subscribe(FEED_SERVO2)
    client.subscribe(FEED_SERVO3)
    client.subscribe(FEED_SERVO4)

    print("Subscribed to servo feeds")


def disconnected(client):
    """
    Called when disconnected from Adafruit IO.
    """

    print("Disconnected from Adafruit IO")

    sys.exit(1)


def message(client, feed_id, payload):
    """
    Called every time a feed receives data.
    """

    global servo1
    global servo2
    global servo3
    global servo4

    print(f"Feed: {feed_id}")
    print(f"Value: {payload}")

    value = int(payload)

    # =====================================================
    # SERVO 1
    # =====================================================

    if feed_id == FEED_SERVO1:

        servo1 = value

        print(f"Servo 1 updated -> {servo1}")

        # Echo to gauge
        client.publish(FEED_SERVO1_ACTUAL, servo1)

    # =====================================================
    # SERVO 2
    # =====================================================

    elif feed_id == FEED_SERVO2:

        servo2 = value

        print(f"Servo 2 updated -> {servo2}")

        client.publish(FEED_SERVO2_ACTUAL, servo2)

    # =====================================================
    # SERVO 3
    # =====================================================

    elif feed_id == FEED_SERVO3:

        servo3 = value

        print(f"Servo 3 updated -> {servo3}")

        client.publish(FEED_SERVO3_ACTUAL, servo3)

    # =====================================================
    # SERVO 4
    # =====================================================

    elif feed_id == FEED_SERVO4:

        servo4 = value

        print(f"Servo 4 updated -> {servo4}")

        client.publish(FEED_SERVO4_ACTUAL, servo4)


# =========================================================
# MQTT CLIENT SETUP
# =========================================================

client = MQTTClient(
    ADAFRUIT_IO_USERNAME,
    ADAFRUIT_IO_KEY
)

# Attach callbacks
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# Connect to Adafruit IO
client.connect()

# Run MQTT in background
client.loop_background()

# =========================================================
# MAIN LOOP
# =========================================================

while True:

    print("System running...")

    print(f"Servo1 = {servo1}")
    print(f"Servo2 = {servo2}")
    print(f"Servo3 = {servo3}")
    print(f"Servo4 = {servo4}")

    print("--------------------------------")

    time.sleep(3)