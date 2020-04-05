`include "baudgen.vh"

module uart_rx (
    input wire rstn, 
    input wire rx,
    output reg rcv,
    output reg [7:0] data
);


wire clk_baud;
reg rx_r;

reg bauden;  //-- Activar señal de reloj de datos
reg clear;   //-- Poner a cero contador de bits
reg load;    //-- Cargar dato recibido

wire clk;
SB_HFOSC #(
  .CLKHF_DIV ("0b10"), //Generating 12 MHz
) OSC12MHZ (
    .CLKHFEN(1'b1),
    .CLKHFPU(1'b1),
    .CLKHF(clk)
);

always @(posedge clk)
  rx_r <= rx;


baudgen_rx #(
  .BAUD(1250), // 9600 bauds
) baudgen0 ( 
  .clk(clk),
  .clk_ena(bauden), 
  .clk_out(clk_baud)
);

//-- Contador de bits
reg [3:0] bitc;

always @(posedge clk)
  if (clear)
    bitc <= 4'd0;
  else if (clear == 0 && clk_baud == 1)
    bitc <= bitc + 1;


//-- Registro de desplazamiento para almacenar los bits recibidos
reg [9:0] raw_data;

always @(posedge clk)
  if (clk_baud == 1) begin
    raw_data = {rx_r, raw_data[9:1]};
  end

//-- Registro de datos. Almacenar el dato recibido
always @(posedge clk)
  if (rstn == 0)
    data <= 0;
  else if (load)
    data <= raw_data[8:1];

//-------------------------------------
//-- CONTROLADOR
//-------------------------------------
localparam IDLE = 2'd0;  //-- Estado de reposo
localparam RECV = 2'd1;  //-- Recibiendo datos
localparam LOAD = 2'd2;  //-- Almacenamiento del dato recibido
localparam DAV = 2'd3;   //-- Señalizar dato disponible 

reg [1:0] state = IDLE;

//-- Transiciones entre estados
always @(posedge clk)

  if (rstn == 0)
    state <= IDLE;
  else
    case (state)

      //-- Resposo
      IDLE : 
        //-- Al llegar el bit de start se pasa al estado siguiente
        if (rx_r == 0)  
          state <= RECV;
        else
          state <= IDLE;

      //--- Recibiendo datos      
      RECV:
        //-- Vamos por el ultimo bit: pasar al siguiente estado
        if (bitc == 4'd10)
          state <= LOAD;
        else
          state <= RECV;

      //-- Almacenamiento del dato
      LOAD:
        state <= DAV;

      //-- Señalizar dato disponible
      DAV:
        state <= IDLE;

    default:
      state <= IDLE;
    endcase


//-- Salidas de microordenes
always @* begin
  bauden <= (state == RECV) ? 1 : 0;
  clear <= (state == IDLE) ? 1 : 0;
  load <= (state == LOAD) ? 1 : 0;
  rcv <= (state == DAV) ? 1 : 0;
end


endmodule

