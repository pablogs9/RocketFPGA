module memory #(
	parameter BITSIZE = 24,
  parameter ADDRLEN = 16,
)(	

    input wire clk,

    input wire [ADDRLEN-1:0] addr,
    input wire [BITSIZE-1:0] datain,
    output reg [BITSIZE-1:0] dataout,
    	
    input wire wren,
);

localparam MEMLEN = ADDRLEN - 2;

wire [3:0] chipselect;

assign chipselect[0] = (addr[ADDRLEN-1:ADDRLEN-2] == 2'b00);
assign chipselect[1] = (addr[ADDRLEN-1:ADDRLEN-2] == 2'b01);
assign chipselect[2] = (addr[ADDRLEN-1:ADDRLEN-2] == 2'b10);
assign chipselect[3] = (addr[ADDRLEN-1:ADDRLEN-2] == 2'b11);

wire [BITSIZE-1:0] outbuff [0:3];
assign dataout = outbuff[addr[ADDRLEN-1:ADDRLEN-2]];

SB_SPRAM256KA M1 (
  .ADDRESS (addr[MEMLEN-1:0]), 
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
  .ADDRESS (addr[MEMLEN-1:0]), 
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
  .ADDRESS (addr[MEMLEN-1:0]), 
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
  .ADDRESS (addr[MEMLEN-1:0]), 
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