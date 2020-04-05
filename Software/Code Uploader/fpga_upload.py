#! /usr/bin/env python
import serial
import time
import argparse
import sys

def writeBytes(ser, d):
    ser.write(bytearray([ord('W')]))
    ser.write(len(d).to_bytes(4, byteorder='little'))
    for i,c in enumerate(d):
        ser.write([c])
        if i == 1:
            print("Erasing memory")
        else:
            print("Writing: {:.2f}%".format(100*i/len(d)), end="\r")
        # ack = ser.read()

def readBytes(ser,l):
    ser.write(bytearray([ord('R')]))
    ser.write(l.to_bytes(4, byteorder='little'))
    value = []
    for i in range(l):
        d = ser.read()
        value.append(d)
        print("Reading: {:.2f}%".format(100*i/l),end="\r")

    return value



def start_flash(port, baudrate, file, no_verify):
    try:
        ser = serial.Serial(port,baudrate)
        ser.rts = 1
    except serial.serialutil.SerialException:
        print("The port '{}' could not be oppended at {} bauds".format(port, baudrate))
        exit()
    try:
        f = open(file, "rb")
    except FileNotFoundError:
        print("File {} not found in path".format(file))
        exit()

    txdata = f.read()
    dlen = len(txdata)
    print("Loading File: {:s} -- {:0.2f} KB".format(file,len(txdata)/1024))

    now = time.time()
    writeBytes(ser, txdata)
    print("Writing time {:.2f} s".format(time.time()-now))

    time.sleep(0.1)
    now = time.time()
    if not no_verify:
        data = readBytes(ser,dlen)
        print("Reading time {:.2f} s".format(time.time()-now))
        print("DATA VERIFIED: " + str(all([x == ord(y) for (x,y) in zip(txdata,data)])))
    
    ser.write(bytearray([ord('A')]))
    ser.close() 
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Flash FPGA board')
    parser.add_argument('-d', '--dev', dest='port', type=str,required=True, 
                        help='Serial port where to write to')
    parser.add_argument('-b', dest='baudrate', type=int,  default=57600,
                        help='Baudrate of the serial port (default 57600)')
    parser.add_argument('-f', dest='file', type=str, required=True,
                        help='bitestream to flash')
    parser.add_argument('--no-verify',  action='store_true',
                    help='Use this flag to skip verification')
    if sys.version_info[0] < 3:
        raise Exception("Must be using Python 3")
    args = parser.parse_args()
    start_flash(args.port, args.baudrate, args.file, args.no_verify)

