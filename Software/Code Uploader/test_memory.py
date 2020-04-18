#! /usr/bin/env python
import serial
import time
import argparse
import sys
import datetime
import random
import math

MEMORY_LENGTH = 4194304 # 32 Mbit * 1024 * 1024 / 8 bit per Byte = 4194304 Bytes
SECTOR_SIZE = 4*1024  # 4 KB sectors

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Flash FPGA board')
    parser.add_argument('-d', '--dev', dest='port', type=str, required=True, 
                        help='Serial port where to write to')
    parser.add_argument('-b', dest='baudrate', type=int,  default=115200,
                        help='Baudrate of the serial port (default 115200)')
    if sys.version_info[0] < 3:
        raise Exception("Must be using Python 3")
    args = parser.parse_args()
    
    # --------------------------------------------
    # --- Open serial port in programming mode ---
    # --------------------------------------------

    try:
        ser = serial.Serial(args.port,args.baudrate)
        ser.rts = 0
    except serial.serialutil.SerialException:
        print("The port '{}' could not be oppended at {} bauds".format(port, baudrate))
        exit()

    # -------------------------
    # --- Delete all memory ---
    # -------------------------

    print("Deleting all flash memory")
    ser.write(bytearray([ord('Z')]))

    # Reading bootloader version
    ser.write(bytearray([ord('V')]))

    while(ser.in_waiting == 0):
        pass

    time.sleep(0.5)
    version_string = (ser.read(ser.in_waiting)).decode('UTF-8')

    print("Done. Found bootloader: {:s}".format(version_string),end="")
    
    # -----------------------
    # --- Read all memory ---
    # -----------------------

    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(0).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('R')]))
    ser.write(int(MEMORY_LENGTH).to_bytes(4, byteorder='little'))
    mem = []

    i = 0
    start_time = time.time()
    while i < MEMORY_LENGTH:
        d = ser.read(ser.in_waiting)
        i = i + len(d)
        mem.extend(d)
        print("Reading: {:.2f}%".format(100*i/MEMORY_LENGTH),end="\r")
    reading_time = time.time() - start_time
    print("Readed {:.2f} KB in {:.2f}s ({:.2f} KB/s)".format(MEMORY_LENGTH/1024, reading_time, (MEMORY_LENGTH/1024)/reading_time))

    print("Checking all bytes are set to 0xFF: ", end="")
    test_pass = True
    for e in mem:
        if e is not 0xFF:
            test_pass = False
            break
    
    print("{:s}".format("OK" if test_pass else "FAIL"))

    if not test_pass:
        filename = "failed_zero_read_memory_dump_" + str(datetime.datetime.now()) + ".bin"
        print("Dumping readed data to: {:s}".format(filename))
        with open(filename,"wb+") as f:
            f.write(bytearray(mem))

    # ------------------------
    # --- Write all memory ---
    # ------------------------

    print("Writing pattern (WARNING THIS CONSUMES WRITE/ERASE CYCLES)")

    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(0).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('W')]))
    ser.write(int(MEMORY_LENGTH).to_bytes(4, byteorder='little'))
    mem = []

    start_time = time.time()
    for i in range(MEMORY_LENGTH):
        ser.write([i % 256])
        print("Writing: {:.2f}%".format(100*i/MEMORY_LENGTH), end="\r")
    writing_time = time.time() - start_time
    print("Wrote {:.2f} KB in {:.2f}s ({:.2f} KB/s)".format(MEMORY_LENGTH/1024, writing_time, (MEMORY_LENGTH/1024)/writing_time))
    
    print("Verifiyng pattern... ")
    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(0).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('R')]))
    ser.write(int(MEMORY_LENGTH).to_bytes(4, byteorder='little'))
    mem = []
    
    i = 0
    start_time = time.time()
    while i < MEMORY_LENGTH:
        d = ser.read(ser.in_waiting)
        i = i + len(d)
        mem.extend(d)
        print("Reading: {:.2f}%".format(100*i/MEMORY_LENGTH),end="\r")
    reading_time = time.time() - start_time
    print("Readed {:.2f} KB in {:.2f}s ({:.2f} KB/s)".format(MEMORY_LENGTH/1024, reading_time, (MEMORY_LENGTH/1024)/reading_time))

    print("Pattern verification: ", end="")
    test_pass = True
    for i,e in enumerate(mem):
        if e is not i%256:
            test_pass = False
            break
    
    print("{:s}".format("OK" if test_pass else "FAIL"))

    if not test_pass:
        filename = "failed_pattern_read_memory_dump_" + str(datetime.datetime.now()) + ".bin"
        print("Dumping readed pattern to: {:s}".format(filename))
        with open(filename,"wb+") as f:
            f.write(bytearray(mem))

    # ---------------------------
    # --- Delete some sectors ---
    # ---------------------------

    n_sectors = math.floor(MEMORY_LENGTH/SECTOR_SIZE)
    sectors = list(range(n_sectors))
    random.shuffle(sectors)

    sectors_to_delete = sectors[0:math.floor(n_sectors/2)]
    print("Removing sectors {:s}".format(str(sectors_to_delete)))
    for s in sectors_to_delete:
        ser.write(bytearray([ord('S')]))
        ser.write(int(s).to_bytes(2, byteorder='little'))
        ser.write(int(s+1).to_bytes(2, byteorder='little'))
    
    print("Verifiyng sector erased... ")
    # Writing start address
    ser.write(bytearray([ord('M')]))
    ser.write(int(0).to_bytes(4, byteorder='little'))

    # Writing len
    ser.write(bytearray([ord('R')]))
    ser.write(int(MEMORY_LENGTH).to_bytes(4, byteorder='little'))
    mem = []
    
    i = 0
    start_time = time.time()
    while i < MEMORY_LENGTH:
        d = ser.read(ser.in_waiting)
        i = i + len(d)
        mem.extend(d)
        print("Reading: {:.2f}%".format(100*i/MEMORY_LENGTH),end="\r")
    reading_time = time.time() - start_time
    print("Readed {:.2f} KB in {:.2f}s ({:.2f} KB/s)".format(MEMORY_LENGTH/1024, reading_time, (MEMORY_LENGTH/1024)/reading_time))

    print("Erased sector verification: ", end="")
    test_pass = True
    for i,e in enumerate(mem):
        if math.floor(i/SECTOR_SIZE) not in sectors_to_delete and e is not i%256:
            test_pass = False
            break
        elif math.floor(i/SECTOR_SIZE) in sectors_to_delete and e is not 0xFF:
            test_pass = False
            break
    
    print("{:s}".format("OK" if test_pass else "FAIL"))

    if not test_pass:
        filename = "failed_sectors_erasing_read_memory_dump_" + str(datetime.datetime.now()) + ".bin"
        print("Dumping readed pattern to: {:s}".format(filename))
        with open(filename,"wb+") as f:
            f.write(bytearray(mem))


