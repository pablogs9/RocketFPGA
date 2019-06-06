import spidev
import time
import RPi.GPIO as gpio

gpio.setmode(gpio.BCM)

gpio.setup(7, gpio.OUT)
gpio.output(7, True)

gpio.setup(44, gpio.OUT)
gpio.output(44, False)
time.sleep(0.1)
gpio.output(44, True)

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 5000000


def writePWM(ch,val):
    gpio.output(7, False)
    spi.xfer2([ch,val])
    gpio.output(7, True)

while True:
    for val in range(256):
        writePWM(1,256-val)
        writePWM(2,val)
        time.sleep(0.01)

    for val in range(256):
        writePWM(2,256-val)
        writePWM(1,val)
        time.sleep(0.01)
