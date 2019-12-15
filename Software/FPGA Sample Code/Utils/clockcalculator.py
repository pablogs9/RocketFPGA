
def freq2IS(m):
    if m < 1E3:
        return "{:0.3f} Hz".format(m)
    elif m < 1E6:
        return "{:0.3f} kHz".format(m/1E3)
    elif m < 1E9:
        return "{:0.3f} MHz".format(m/1E6)

def time2IS(m):
    if m < 1E-9:
        return "{:0.3f} ps".format(m*1E12)
    elif m < 1E-6:
        return "{:0.3f} ns".format(m*1E9)
    elif m < 1E-3:
        return "{:0.3f} us".format(m*1E6)
    elif m < 1:
        return "{:0.3f} ms".format(m*1E3)
    else:
        return "{:0.3f} s".format(m)

mainfreq = 49152000

division = [(n,2**(n+1)) for n in range(30)]

for (n,d) in division:
    print("//N:{:d} {:s} -> {:s} ({:s})".format(n,freq2IS(mainfreq),freq2IS(mainfreq/d),time2IS(1/(mainfreq/d))))
    # print("reg [{:d}:0] divider;".format(n+1))
    # print("wire subclock;".format())
    # print("assign subclock = divider[dividerBit];".format())
    # '''always @(posedge OSC) begin
    #     divider <= divider + 1;
    # end'''