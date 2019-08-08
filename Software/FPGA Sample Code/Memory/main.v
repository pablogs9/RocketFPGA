module main (        
         input clk,                      //-- Señal de reloj global
         input wire [AW-1: 0] addr,      //-- Direcciones
         input wire rw,                  //-- Modo lectura (1) o escritura (0)
         input wire [DW-1: 0] data_in,   //-- Dato de entrada
         output reg [DW-1: 0] data_out); //-- Dato a escribir

//-- Parametro: Nombre del fichero con el contenido de la RAM
// parameter ROMFILE = "bufferini.list";

//-- Calcular el numero de posiciones totales de memoria
    localparam AW = 10;
    localparam DW = 8;
    localparam NPOS = 2 ** AW;

  //-- Memoria
  reg [DW-1: 0] ram [0: NPOS-1];

  //-- Lectura de la memoria
  always @(posedge clk) begin
    if (rw == 1)
    data_out <= ram[addr];
  end

  //-- Escritura en la memoria
  always @(posedge clk) begin
    if (rw == 0)
     ram[addr] <= data_in;
  end

//-- Cargar en la memoria el fichero ROMFILE
//-- Los valores deben estan dados en hexadecimal
// initial begin
//   $readmemh(ROMFILE, ram);
// end

endmodule