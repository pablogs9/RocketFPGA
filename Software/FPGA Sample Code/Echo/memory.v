module memory (	

    input wire clk,

    input wire [MEMLEN-1:0] addr,
    input wire [DATALEN-1:0] datain,
    output reg [DATALEN-1:0] dataout,
    	
    input wire wren,
);

localparam ADDRLEN = 14;
localparam DATALEN = 16;
localparam MEMLEN = ADDRLEN + 2;

wire [3:0] chipselect;

assign chipselect[0] = addr[MEMLEN-1:MEMLEN-3] === 2'b00;
assign chipselect[1] = addr[MEMLEN-1:MEMLEN-3] === 2'b01;
assign chipselect[2] = addr[MEMLEN-1:MEMLEN-3] === 2'b10;
assign chipselect[3] = addr[MEMLEN-1:MEMLEN-3] === 2'b11;

wire [DATALEN-1:0] outbuff [4:0];
assign dataout = outbuff[addr[MEMLEN-1:MEMLEN-3]];

SB_SPRAM256KA M1 (
  .ADDRESS (addr[ADDRLEN-1:0]), 
  .DATAIN (datain), 
  .DATAOUT (outbuff[0]),
  .MASKWREN (4'b1111),
  .WREN (wren),
  .CHIPSELECT (chipselect[0]),
  .CLOCK (clk),
  .STANDBY (1'b0),
  .SLEEP (1'b0),
  .POWEROFF (1'b1)
);

SB_SPRAM256KA M2 (
  .ADDRESS (addr[ADDRLEN-1:0]), 
  .DATAIN (datain), 
  .DATAOUT (outbuff[1]),
  .MASKWREN (4'b1111),
  .WREN (wren),
  .CHIPSELECT (chipselect[1]),
  .CLOCK (clk),
  .STANDBY (1'b0),
  .SLEEP (1'b0),
  .POWEROFF (1'b1)
);

SB_SPRAM256KA M3 (
  .ADDRESS (addr[ADDRLEN-1:0]), 
  .DATAIN (datain), 
  .DATAOUT (outbuff[2]),
  .MASKWREN (4'b1111),
  .WREN (wren),
  .CHIPSELECT (chipselect[2]),
  .CLOCK (clk),
  .STANDBY (1'b0),
  .SLEEP (1'b0),
  .POWEROFF (1'b1)
);

SB_SPRAM256KA M4 (
  .ADDRESS (addr[ADDRLEN-1:0]), 
  .DATAIN (datain), 
  .DATAOUT (outbuff[3]),
  .MASKWREN (4'b1111),
  .WREN (wren),
  .CHIPSELECT (chipselect[3]),
  .CLOCK (clk),
  .STANDBY (1'b0),
  .SLEEP (1'b0),
  .POWEROFF (1'b1)
);

endmodule