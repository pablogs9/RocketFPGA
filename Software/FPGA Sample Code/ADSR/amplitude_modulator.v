module amplitude_modulator #(
  parameter DATA_BITS = 12,
  parameter AMPLITUDE_BITS = 8
)
(
  input signed [DATA_BITS-1:0]       din,
  input [AMPLITUDE_BITS-1:0]  amplitude,
  input                       clk,
  output wire signed [DATA_BITS-1:0]  dout
);

  // cajole amplitude into a signed value so that verilog
  // uses signed arithmetic in the multiply below
  wire signed [AMPLITUDE_BITS:0] amp_signed;
  assign amp_signed = { 1'b0, amplitude[AMPLITUDE_BITS-1:0] }; // amplitude with extra MSB (0)

  reg signed [DATA_BITS+AMPLITUDE_BITS-1:0] scaled_din;  // intermediate value with extended precision

  always @(posedge clk) begin
    scaled_din <= (din * amp_signed);
  end

  assign dout = scaled_din[DATA_BITS+AMPLITUDE_BITS-1 -: DATA_BITS];

endmodule