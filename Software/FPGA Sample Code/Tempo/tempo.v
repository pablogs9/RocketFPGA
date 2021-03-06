module tempo #(
	parameter BPM = 60,
	parameter GENERATE_CLOCK = 1,
)(	
	input wire clock_in,
	output reg clock_out,

    output reg whole,
    output reg half,
    output reg quarter,
    output reg eighth,
    output reg sixteenth,
    output reg thirtysecond,
    output reg sixtyfourth,
);

localparam COUNTER_BPM = $rtoi(60.0/((32*BPM)*0.0002));

wire internal_clock;
reg osc_10kz;

// assign internal_clock = (GENERATE_CLOCK == 1) ? osc_10kz : clock_in;
// // assign clock_out = internal_clock;

// if ( GENERATE_CLOCK == 1) begin
SB_LFOSC OSC10KHZ ( 
    .CLKLFEN(1'b1), 
    .CLKLFPU(1'b1), 
    .CLKLF(osc_10kz)
);
// end

reg [21:0] counter = 0;
reg [21:0] ref = COUNTER_BPM;
reg [7:0] tempo_counter = 0;

always @( posedge osc_10kz ) begin
    if (counter == ref) begin
        counter <= 0;
        tempo_counter <= tempo_counter + 1;
    end else begin
        counter <= counter + 1;
    end
end

// always @( negedge tempo_counter[0] ) begin
//     whole        <= (tempo_counter[7:0] == 8'b10000000) ? 1'b1 : 1'b0; 
//     half         <= (tempo_counter[6:0] == 7'b1000000) ? 1'b1 : 1'b0; 
//     quarter      <= tempo_counter[5];  
//     eighth       <= (tempo_counter[4:0] == 5'b10000) ? 1'b1 : 1'b0; 
//     sixteenth    <= (tempo_counter[3:0] == 4'b1000) ? 1'b1 : 1'b0; 
//     thirtysecond <= (tempo_counter[2:0] == 3'b100) ? 1'b1 : 1'b0; 
//     sixtyfourth  <= (tempo_counter[1:0] == 2'b10) ? 1'b1 : 1'b0; 
// end

// assign whole        = (tempo_counter[7:0] == 8'b10000000) ? 1'b1 : 1'b0; 
// assign half         = (tempo_counter[6:0] == 7'b1000000) ? 1'b1 : 1'b0; 
assign quarter      = tempo_counter[5];
// assign eighth       = (tempo_counter[4:0] == 5'b10000) ? 1'b1 : 1'b0; 
// assign sixteenth    = (tempo_counter[3:0] == 4'b1000) ? 1'b1 : 1'b0; 
// assign thirtysecond = (tempo_counter[2:0] == 3'b100) ? 1'b1 : 1'b0; 
// assign sixtyfourth  = (tempo_counter[1:0] == 2'b10) ? 1'b1 : 1'b0; 

endmodule