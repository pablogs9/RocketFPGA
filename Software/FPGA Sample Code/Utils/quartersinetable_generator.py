# BITSIZE = B
# TABLESIZE = W
# reg [BITSIZE-1:0] quartertable [0:((1<<TABLESIZE)-1)];
# initial $readmemh("file.hex", quartertable);

import math
import sys

B = int(sys.argv[1])
W = int(sys.argv[2])
N = int(math.pow(2,W))

max_val = int((2**(B-1))-(2*1e6))

K = 1
N = N+K

i = 0
for k in range(K,N):
    phase = (math.pi/2) * (k/(N-1))
    value = max_val * math.sin(phase)

    if i%8 == 0:
        print("{:s}@{:08x} ".format("" if i == 0 else "\n",i),end='')
    print("{:06x} ".format(int(value)),end='')
    i = i + 1

print("")

used_bits = int(B*N)
EBR_blocks = 30
EBR_size = 4096
available_RAM = EBR_blocks * EBR_size

print("Generating quarter sine table of {:d} bits and {:d} samples (W = {:d})".format(B,N,W),file=sys.stderr)
print("Used memory: {:d} bits ({:0.2f} %)".format(used_bits,100*used_bits/available_RAM),file=sys.stderr)