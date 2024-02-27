
module period_counter (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] period,
  input  logic        start,
  output logic [15:0] period_count,
  output logic        update
  );
  
  always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)                      period_count <= 16'd0;
      else if (period == 16'd0)        period_count <= 16'd0;
      else if (!start)                 period_count <= 16'd0;
      else if (period_count == period) period_count <= 16'd0;
      else if (period_count < period)  period_count <= period_count + 16'd1;
  
  assign update = (period_count == period) && (period != 16'd0); // ok to glitch
  
endmodule