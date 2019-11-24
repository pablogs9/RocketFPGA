
module SPI (
    output wire MOSI, 
    input wire MISO, 
    output wire SCK, 
    output wire CS, 

    //  Interface
    input wire RESET, 
    input wire CLK, 
    input wire [7:0] DATA,
    input wire TRG, 
    input wire RDY, 

) ;
reg [4:0] bit;
reg [7:0] inner_data;

always @(posedge TRG) begin
    inner_data <= DATA; 
    bit <= 9
end

always @(posedge CLK) begin
    if (RESET) begin
        SCK <= 0;
        MOSI <= 0;
        CS <= 0;
        RDY <= 0;
    end
    else begin
        if (bit > 0) begin
            RDY <= 0;
            CS <= 1;
	        MOSI <= inner_data[bit];
            bit <= bit - 1;
        end
        else begin
            MOSI <= 0;
            CS <= 0;
            RDY <= 1;
        end
    end
end

    
endmodule


