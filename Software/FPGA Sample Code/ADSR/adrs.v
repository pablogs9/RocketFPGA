module envelope_generator #(
  parameter BITSIZE = 16,
  parameter SAMPLE_CLK_FREQ = 44100,
  parameter ACCUMULATOR_BITS = 26
) (
  input wire clk,
  input wire gate,
  input wire [3:0] a,
  input wire [3:0] d,
  input wire [3:0] s,
  input wire [3:0] r,
  output reg signed [BITSIZE-1:0] amplitude,
);

  localparam  ACCUMULATOR_SIZE = 2**ACCUMULATOR_BITS;
  reg signed [ACCUMULATOR_BITS:0] accumulator = 0;
  reg signed [ACCUMULATOR_BITS:0] future_accumulator = 1;

  `define CALCULATE_PHASE_INCREMENT(n) $rtoi(ACCUMULATOR_SIZE / (n * SAMPLE_CLK_FREQ))

  function [16:0] attack_table;
    input [3:0] param;
    begin
      case(param)
        4'b0000: attack_table = `CALCULATE_PHASE_INCREMENT(0.002);  // 33554
        4'b0001: attack_table = `CALCULATE_PHASE_INCREMENT(0.008);
        4'b0010: attack_table = `CALCULATE_PHASE_INCREMENT(0.016);
        4'b0011: attack_table = `CALCULATE_PHASE_INCREMENT(0.024);
        4'b0100: attack_table = `CALCULATE_PHASE_INCREMENT(0.038);
        4'b0101: attack_table = `CALCULATE_PHASE_INCREMENT(0.056);
        4'b0110: attack_table = `CALCULATE_PHASE_INCREMENT(0.068);
        4'b0111: attack_table = `CALCULATE_PHASE_INCREMENT(0.080);
        4'b1000: attack_table = `CALCULATE_PHASE_INCREMENT(0.100);
        4'b1001: attack_table = `CALCULATE_PHASE_INCREMENT(0.250);
        4'b1010: attack_table = `CALCULATE_PHASE_INCREMENT(0.500);
        4'b1011: attack_table = `CALCULATE_PHASE_INCREMENT(0.800);
        4'b1100: attack_table = `CALCULATE_PHASE_INCREMENT(1.000);
        4'b1101: attack_table = `CALCULATE_PHASE_INCREMENT(3.000);
        4'b1110: attack_table = `CALCULATE_PHASE_INCREMENT(5.000);
        4'b1111: attack_table = `CALCULATE_PHASE_INCREMENT(8.000);
        default: attack_table = 65535;
      endcase
    end
  endfunction


  // Incrementators modify on parameter change
  reg [16:0] attack_inc;
  always @(a) begin
    attack_inc <= attack_table(a);
  end

  reg [16:0] decay_inc;
  always @(d) begin
      decay_inc <= attack_table(d);
  end

  reg [16:0] release_inc;
  always @(r) begin
      release_inc <= attack_table(r);
  end

  reg signed [ACCUMULATOR_BITS:0] sustain_volume;
  always @(s) begin
      sustain_volume <= {1'b0, s, {(ACCUMULATOR_BITS-5){1'b1}} };
  end


  
  function [2:0] next_state;
    input [2:0] s;
    input g;
    begin
      case ({ s, g })
        { ATTACK,  1'b0 }: next_state = RELEASE;  /* attack, gate off => skip decay, sustain; go to release */
        { ATTACK,  1'b1 }: next_state = DECAY;    /* attack, gate still on => decay */
        { DECAY,   1'b0 }: next_state = RELEASE;  /* decay, gate off => skip sustain; go to release */
        { DECAY,   1'b1 }: next_state = SUSTAIN;  /* decay, gate still on => sustain */
        { SUSTAIN, 1'b0 }: next_state = RELEASE;  /* sustain, gate off => go to release */
        { SUSTAIN, 1'b1 }: next_state = SUSTAIN;  /* sustain, gate on => stay in sustain */
        { RELEASE, 1'b0 }: next_state = OFF;      /* release, gate off => end state */
        { RELEASE, 1'b1 }: next_state = ATTACK;   /* release, gate on => attack */
        { OFF,     1'b0 }: next_state = OFF;      /* end_state, gate off => stay in end state */
        { OFF,     1'b1 }: next_state = ATTACK;   /* end_state, gate on => attack */
        default: next_state = OFF;                /* default is end (off) state */
      endcase
    end
  endfunction


  // State machine
  localparam OFF     = 3'd0;
  localparam ATTACK  = 3'd1;
  localparam DECAY   = 3'd2;
  localparam SUSTAIN = 3'd3;
  localparam RELEASE = 3'd4;

  reg[2:0] state = OFF;

  reg last_gate;

  always @(posedge clk) begin
      
      amplitude <= {2'b00, accumulator[ACCUMULATOR_BITS-1 -: BITSIZE-2]};
      last_gate <= gate;
      case (state)
        ATTACK:
          begin
            if (future_accumulator > 0) begin
              accumulator <= accumulator + attack_inc;
              future_accumulator <= accumulator + (attack_inc << 1);
            end else begin
              future_accumulator <= (2**ACCUMULATOR_BITS-1)-1;
              state <= next_state(state, gate);
            end
          end
        DECAY:
          begin
            if (!last_gate && gate) begin
                state = ATTACK;
            end
            if (future_accumulator >= sustain_volume && s < 4'b1111) begin
                accumulator <= accumulator - decay_inc;
                future_accumulator <= accumulator - (decay_inc << 1);
            end else begin
                state <= next_state(state, gate);
                future_accumulator <= 1;
            end
          end
        SUSTAIN:
          begin
            state <= next_state(state, gate);
          end
        RELEASE:
          begin
            if (future_accumulator > 0) begin
                accumulator <= accumulator - release_inc;
                future_accumulator <= accumulator - (release_inc << 1);
            end else begin
                future_accumulator <= 1;
                state <= next_state(state, gate);
            end
          end
        default:
          begin
            accumulator <= 0;
            future_accumulator <= 1;
            state <= next_state(state, gate);
          end
      endcase

  end

endmodule
