module pwm (clk,duty,out);

input clk;
input[7:0] duty;
output out;

reg[7:0] counter;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign out = (duty == 0) ? 0 : (counter <= duty);
endmodule
