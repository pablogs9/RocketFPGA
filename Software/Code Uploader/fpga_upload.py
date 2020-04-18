#! /usr/bin/env python
import serial
import time
import argparse
import sys
import math

SECTOR_SIZE = 4*1024  # 4 KB sectors

def writeBytes(ser, d, offset):
    # Erasing required sectors
    first_sector = math.floor(offset/SECTOR_SIZE)
    last_sector = math.floor((offset + len(d))/SECTOR_SIZE) + 1

    print("Erasing memory from 0x{:06X} to 0x{:06X}".format(first_sector, last_sector))

    if not (offset/SECTOR_SIZE).is_integer():
        print("WARNING: erasing sectors previous to required offset")
        print("Erasing starts at: {:d}".format(math.floor(offset/SECTOR_SIZE)*SECTOR_SIZE))

    ser.write(bytearray([ord('S')]))
    ser.write(int(first_sector).to_bytes(2, byteorder='little'))
    ser.write(int(last_sector).to_bytes(2, byteorder='little'))

    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(offset).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('W')]))
    ser.write(len(d).to_bytes(4, byteorder='little'))

    # Writing data
    for i,c in enumerate(d):
        ser.write([c])
        print("Writing: {:.2f}%".format(100*i/len(d)), end="\r")

def readBytes(ser,l, offset):
    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(offset).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('R')]))
    ser.write(int(l).to_bytes(4, byteorder='little'))
    value = []
    i = 0
    while i < l:
        d = ser.read(ser.in_waiting)
        i = i + len(d)
        value.extend(d)
        print("Reading: {:.2f}%".format(100*i/l),end="\r")

    return value



def start_flash(port, baudrate, file, offset, no_verify):
    try:
        ser = serial.Serial(port,baudrate)
        ser.rts = 0
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
    writeBytes(ser, txdata, offset)
    writting_time = time.time()-now
    print("Writing time {:.2f}s ({:.2f} KB/s)".format(writting_time, (len(txdata)/1024)/writting_time))

    time.sleep(0.1)
    
    if not no_verify:
        now = time.time()
        rxdata = readBytes(ser, dlen, offset)
        reading_time = time.time()-now
        print("Reading time {:.2f}s ({:.2f} KB/s)".format(reading_time, (len(rxdata)/1024)/reading_time))
        print("DATA VERIFIED: " + str(all([x == y for (x,y) in zip(txdata,list(rxdata))])))
    
    ser.write(bytearray([ord('A')]))
    ser.close() 
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Flash FPGA board')
    parser.add_argument('-d', '--dev', dest='port', type=str,required=True, 
                        help='Serial port where to write to')
    parser.add_argument('-b', dest='baudrate', type=int,  default=115200,
                        help='Baudrate of the serial port (default 115200)')
    parser.add_argument('-f', dest='file', type=str, required=True,
                        help='bitestream to flash')
    parser.add_argument('--debug', dest='debug', action='store_true',
                        help='enable debug')
    parser.add_argument('-o', dest='offset', type=int,  default=0,
                        help='SPI memory offset (default 0)')
    parser.add_argument('--no-verify',  action='store_true',
                    help='Use this flag to skip verification')
    if sys.version_info[0] < 3:
        raise Exception("Must be using Python 3")
    args = parser.parse_args()
    
    # start_flash(args.port, args.baudrate, args.file, args.no_verify)
    start_flash(args.port, args.baudrate, args.file, args.offset, args.no_verify)

