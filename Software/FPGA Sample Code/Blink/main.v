module main(
 input OSC,
 output LED
);

reg [30:0] ledDivider;
parameter ledVelocity = 22;

always @(posedge OSC) begin
    ledDivider <= ledDivider + 1;  
end

assign LED = ledDivider[ledVelocity];

endmodule