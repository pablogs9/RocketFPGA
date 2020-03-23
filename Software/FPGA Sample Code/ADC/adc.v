module adc #(
	parameter OUTSIZE = 16
)(	
	output wire pot_1,
	output wire pot_2,
	output wire capacitor,
	input wire osc,			// 49.152 MHz
	input wire sense,
	output reg [OUTSIZE-1:0] out,
);
localparam sense_division = 2;  
localparam capacitor_division = sense_division + OUTSIZE + 1; // 46.875 Hz -> 10 uF

wire aux;
reg [OUTSIZE-1:0] counter;
reg done = 0;

reg [capacitor_division:0] divider;
always @(posedge osc) begin
    divider <= divider + 1;
end

assign capacitor = divider[capacitor_division];

// This can be done with Vcc and GND
assign pot_1 = 1'b1;
assign pot_2 = 1'b0;

SB_IO #(
  .PIN_TYPE(6'b000000), 
  .IO_STANDARD("SB_LVDS_INPUT")
) _io (
 .PACKAGE_PIN(sense),
 .INPUT_CLK (divider[sense_division]),
 .D_IN_0 (aux)
);

always @(posedge divider[sense_division]) begin
    if (!divider[capacitor_division]) begin
      counter <= 0;
      done <= 0;
    end else if (!done) begin
      if (aux) begin
          counter <= counter + 1;
      end else begin
        done <= 1;
        out <= counter;
      end
    end
end

endmodule