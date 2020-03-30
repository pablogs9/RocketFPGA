# BITSIZE = B
# TABLESIZE = W
# reg [15:0] tones [0:95];
# initial $readmemh("file.hex", tones);

import math
import sys


FS = int(sys.argv[1])
PHASE = int(sys.argv[2])


k = 0
MAX = 140
for i in range(1,MAX):
    f = 440 * math.pow(2,(i-(MAX/2))/12)
    n = round(f*math.pow(2,PHASE)/FS)
    if k%8 == 0:
        print("{:s}@{:08x} ".format("" if k == 0 else "\n",k),end='')
    print("{:04x} ".format(int(n)),end='')
    print("f = {:f} k = {:d}".format(f,k), file=sys.stderr)

    k = k + 1

print("")

# print("Generating quarter sine table of {:d} bits and {:d} samples (W = {:d})".format(B,N,W),file=sys.stderr)
# print("Used memory: {:d} bits ({:0.2f} %)".format(used_bits,100*used_bits/available_RAM),file=sys.stderr)
