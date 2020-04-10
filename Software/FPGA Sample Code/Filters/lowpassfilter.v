 /* Example values for alpha based on Fc/Fs:
  *
  * ===================
  * Fc(-3dB)/Fs   alpha
  * -------------------
  *        0.01,  16
  *        0.02,  30
  *        0.03,  44
  *        0.04,  56
  *        0.05,  68
  *        0.06,  79
  *        0.07,  90
  *        0.08,  99
  *        0.09, 108
  *        0.09, 116
  *        0.10, 124
  *        0.11, 131
  *        0.12, 137
  *        0.13, 144
  *        0.15, 149
  *        0.16, 154
  *        0.17, 159
  *        0.18, 164
  *        0.19, 168
  *        0.20, 172
  *        0.21, 175
  *        0.22, 178
  *        0.23, 181
  *        0.24, 184
  *        0.25, 187
  *        0.26, 189
  *        0.27, 191
  *        0.28, 193
  *        0.29, 195
  *        0.30, 197
  *        0.31, 199
  *        0.32, 200
  */

module lowpassfilter #(
  parameter BITSIZE = 16
) (
  input clk,
  input wire signed [8:0] alpha,
  input wire signed [BITSIZE-1:0] in,  /* unfiltered data in */
  output reg signed [BITSIZE-1:0] out  /* filtered data out */
);

localparam HALF_SCALE = (2**(BITSIZE-1));

initial
begin
  out = 0;
  s_adder1_out = 0;
end

reg signed [BITSIZE:0] s_adder1_out;
reg signed [(BITSIZE*2)-1:0] sw_raw_mul_output;
reg signed [BITSIZE:0] s_mul_out;
reg signed [BITSIZE:0] tmp_out;

always @(posedge clk)
begin
  s_adder1_out = in - out;
  sw_raw_mul_output = (s_adder1_out * alpha) >>> 8;  // divide by 256 (amplitude)
  s_mul_out = sw_raw_mul_output[BITSIZE:0];
  tmp_out = (s_mul_out + out);
  out = tmp_out[BITSIZE-1:0];
end

endmodule
