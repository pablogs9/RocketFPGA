module PWM (clk,duty,out);

input clk;
input[4:0] duty;
output out;

reg[4:0] counter;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign out = counter < duty;
endmodule
