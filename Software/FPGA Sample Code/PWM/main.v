module main(
 input OSC, //20 MHz clock
 output LED
);


reg [30:0] divider;
parameter dividerBit = 18;
wire subclock;

assign subclock = divider[dividerBit];

reg[4:0] duty;
reg reverse;
wire LEDWire;

PWM PWM1(
  .clk(OSC), 
  .duty(duty), 
  .out(LEDWire)
);

always @(posedge OSC) begin
    divider <= divider + 1;
end

always @(posedge subclock) begin

    if (duty == 18) begin
        reverse <= 1;
    end else if (duty == 1) begin 
        reverse <= 0;
    end  

    if (reverse == 0) begin
        duty <= (duty + 1);
    end else begin 
        duty <= (duty - 1);
    end  
end

assign LED = LEDWire;

endmodule