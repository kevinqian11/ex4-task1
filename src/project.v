/*
 * Copyright (c) 2026 Kevin Qian
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Combinational WIDTH-bit unsigned difference of A - B with borrow in and out
module Subtracter
  #(parameter WIDTH = 8)
  (input logic [WIDTH - 1:0] A, B,
  input logic bin,
  output logic [WIDTH - 1:0] diff,
  output logic bout);

  always_comb begin
    diff = A - bin - B;
    bout = (A < B || ((A == B) && bin)) ? 1 : 0;
  end

endmodule: Subtracter

// WIDTH-bit register with enable and synchronous clear, enable has priority
module Register
  #(parameter WIDTH = 8)
  (input logic [WIDTH - 1:0] D,
  input logic en, clear, clock,
  output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock)
    if(en)
      Q <= D;
    else if(clear)
      Q <= '0;

endmodule: Register

// Combinational magnitude comparison for A < B, A == B, and A > B
module MagComp
  #(parameter WIDTH = 8)
  (input logic [WIDTH - 1:0] A, B,
  output logic AltB, AeqB, AgtB);

  assign AltB = (A < B);
  assign AeqB = (A == B);
  assign AgtB = (A > B);

endmodule: MagComp

// Finds the range between the max and min of a series of numbers
module RangeFinder
  #(parameter WIDTH=16)
  (input  logic [WIDTH-1:0] data_in,
  input  logic             clock, reset,
  input  logic             go, finish,
  output logic [WIDTH-1:0] range,
  output logic             error);

// Put your code here
  logic minEn, maxEn, minClear, maxClear;
  logic [WIDTH-1:0] min, max;

  // New Minimum/Maximum Check
  MagComp #(WIDTH) minComp(.A(data_in), .B(min), .AltB(minEn), .AeqB(),
    .AgtB());
  MagComp #(WIDTH) maxComp(.A(data_in), .B(max), .AltB(), .AeqB(),
    .AgtB(maxEn));
  
  // Minimum and Maximum Values
  Register #(WIDTH) minReg(.D(data_in), .en(minEn | minClear), .clear(),
    .clock(clock), .Q(min));
  Register #(WIDTH) maxReg(.D(data_in), .en(maxEn), .clear(maxClear),
    .clock(clock), .Q(max));

  // Calculate Range
  Subtracter #(WIDTH) rangeSub(.A(max), .B(min), .bin(1'b0), .diff(range),
    .bout());

  // FSM States
  enum logic [1:0] {WAIT = 2'b00, RUN = 2'b01, ERRORW = 2'b10, ERRORR = 2'b11}
    cur_state, n_state;

  always_comb begin
    // Default Uninitialized Case
    n_state = WAIT;
    minClear = 1;
    maxClear = 1;
    error = 0;
    
    case(cur_state)
      // Reset State
      WAIT: begin
        if(finish)
          n_state = ERRORW;
        else if(go)
          n_state = RUN;
        else
          n_state = WAIT;
        minClear = go ? 0 : 1;
        maxClear = go ? 0 : 1;
        error = finish ? 1 : 0;
      end
      // Running State
      RUN: begin
        if(go)
          n_state = ERRORR;
        else if(finish)
          n_state = WAIT;
        else
          n_state = RUN;
        minClear = 0;
        maxClear = 0;
        error = go ? 1 : 0;
      end
      // Waiting Error State
      ERRORW: begin
        n_state = (go & ~finish) ? WAIT : ERRORW;
        minClear = 0;
        maxClear = 0;
        error = (go & ~finish) ? 0 : 1;
      end
      // Running Error State
      ERRORR: begin
        n_state = (go & ~finish) ? RUN : ERRORR;
        minClear = 0;
        maxClear = 0;
        error = (go & ~finish) ? 0 : 1;
      end
    endcase
  end

  always_ff @(posedge clock, posedge reset)
    if(reset)
      cur_state <= WAIT;
    else
      cur_state <= n_state;

endmodule: RangeFinder

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[7:1] = 0;
  assign uio_oe = 8'b1;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, uio_in[0], uio_in[3], uio_in[4], uio_in[5],
    uio_in[6], uio_in[7], 1'b0};

  RangeFinder #(8) rf(.data_in(ui_in), .clock(clk), .reset(~rst_n), .go(uio_in[1]),
    .finish(uio_in[2]), .range(uo_out), .error(uio_out[0]));

endmodule
