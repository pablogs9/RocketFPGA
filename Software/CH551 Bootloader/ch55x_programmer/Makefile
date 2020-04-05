CPP=g++
LIBS=-lusb-1.0
SRCS=main.cpp KT_BinIO.cpp KT_ProgressBar.cpp
OBJS=$(SRCS:.cpp=.o)
TARGET=vnproch551
INSTALL_DIR=/usr/bin
$(TARGET): $(OBJS)
	$(CPP) $(OBJS) $(LIBS) -o $@ 

%.o:%.cpp
	$(CPP) -c $< -o $@
all:
	$(TARGET)
install: $(TARGET)
	cp $(TARGET) $(INSTALL_DIR)
	cp 90-ch551-bl.rules /etc/udev/rules.d
	udevadm control --reload-rules
clean:
	rm $(TARGET) *.o
.PHONY: all clean install
