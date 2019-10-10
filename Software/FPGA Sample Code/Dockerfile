FROM debian

RUN apt update && apt install -y build-essential libeigen3-dev clang bison flex libreadline-dev gawk tcl-dev libffi-dev git mercurial graphviz xdot pkg-config python python3 libftdi-dev python3-dev libboost-all-dev cmake

WORKDIR /

RUN git clone https://github.com/cliffordwolf/icestorm.git icestorm
RUN git clone https://github.com/YosysHQ/nextpnr nextpnr
RUN git clone https://github.com/cliffordwolf/yosys.git yosys

WORKDIR /icestorm
RUN make -j$(nproc) && make install

WORKDIR /nextpnr
RUN cmake -DARCH=ice40 -DBUILD_PYTHON=OFF -DBUILD_GUI=OFF -DSTATIC_BUILD=ON -DCMAKE_INSTALL_PREFIX=/usr/local .
RUN make -j$(nproc) && make install

WORKDIR /yosys
RUN make -j$(nproc) && make install

WORKDIR /
RUN rm -rf /icestorm /yosys /nextpnr 
RUN git clone https://github.com/pablogs9/RocketFPGA.git
WORKDIR /RocketFPGA/Software/FPGA Sample Code/Blink
RUN make





# RUN git clone https://github.com/pablogs9/RocketFPGA
# RUN git clone https://github.com/NgoHungCuong/vnproch551.git

# WORKDIR /RocketFPGA/Software/CH551 Bootloader
# RUN make
# WORKDIR /vnproch551
# RUN ./build.sh

# ENTRYPOINT ["./vnproch551", "/RocketFPGA/Software/CH551 Bootloader/bin/main.bin"]

