# docker run -it -v $(pwd):/root/Software debian
FROM debian

RUN apt update && apt install -y sdcc binutils git  make g++ build-essential libusb-1.0-0-dev
RUN git clone https://github.com/pablogs9/RocketFPGA
RUN git clone https://github.com/hfegetude/vnproch551

WORKDIR /RocketFPGA/Software/CH551 Bootloader
RUN make
WORKDIR /vnproch551
RUN ./build.sh

ENTRYPOINT ["./vnproch551", "/RocketFPGA/Software/CH551 Bootloader/bin/main.bin"]

