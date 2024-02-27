
module reg_map (
  input  logic        clk,
  input  logic        rst_n,
  input  logic  [7:0] addr,
  input  logic  [7:0] wdata,
  input  logic        wr_en_wdata_sync,
  input  logic        update,
  output logic  [7:0] rdata,
  output logic [15:0] period,
  output logic [15:0] phase,
  output logic [15:0] duty_cycle,
  output logic  [2:0] trig_count,
  output logic        enable,
  output logic        invert,
  output logic        initial_val,
  output logic        start
);
  
  parameter MAX_ADDRESS = 7; // 7 total addresses, including zero
  
  logic [7:0] registers[MAX_ADDRESS-1:0];
  logic wr_en_wdata_hold;
  logic wr_en_wdata_fedge;
  
  logic [15:0] period_shadow;
  logic [15:0] phase_shadow;
  logic [15:0] duty_cycle_shadow;
  logic  [2:0] trig_count_shadow;
  logic        enable_shadow;
  logic        invert_shadow;
  logic        initial_val_shadow;
  logic        enable_reg;
  
  logic update_req;
  logic soft_start_req;
  
  always_ff @ (posedge clk, negedge rst_n)
    if (!rst_n) wr_en_wdata_hold <= 1'b0;
    else        wr_en_wdata_hold <= wr_en_wdata_sync;
    
  assign wr_en_wdata_fedge = wr_en_wdata_hold && (!wr_en_wdata_sync);
  
  // a compact method to capture writes
  integer i;
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)      for (i=0; i<=MAX_ADDRESS-1; i=i+1) registers[i]    <= 8'h00;
    else if (wr_en_wdata_fedge)                         registers[addr] <= wdata;
  
  // update_enable is held until update
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)                                    update_req <= 'd0;
    else if (wr_en_wdata_fedge && (addr == 8'd7))  update_req <= wdata[0];
    else if (!enable_reg || update)                update_req <= 'd0;
    
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)                                    soft_start_req <= 'd0;
    else if (wr_en_wdata_fedge && (addr == 8'd7))  soft_start_req <= wdata[1];
    else if (update)                               soft_start_req <= 'd0;
 
  // start starts the period_counter
  // soft_start_goes low with first update, enable goes high with first update
  assign start = soft_start_req || enable_reg;
 
  // some FPGAs explode when unexpected addresses are used
  assign rdata = (addr <= MAX_ADDRESS-1) ? registers[addr] : 8'd0;
 
 // this is just renaming the registers bits to custom names
  always_comb begin
    period_shadow      = {registers[1],registers[0]};
    phase_shadow       = {registers[3],registers[2]};
    duty_cycle_shadow  = {registers[5],registers[4]};
    trig_count_shadow  = registers[6][7:5];
    enable_shadow      = registers[6][0];
    invert_shadow      = registers[6][1];
    initial_val_shadow = registers[6][2];
  end
 
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      period      <= 'd0;
      phase       <= 'd0;
      duty_cycle  <= 'd0;
      trig_count  <= 'd0;
      enable_reg  <= 'd0;
      invert      <= 'd0;
      initial_val <= 'd0;
      end
    else if ((update && (update_req || soft_start_req)) || (!enable_reg && update_req)) begin
      period      <= period_shadow;
      phase       <= phase_shadow;
      duty_cycle  <= duty_cycle_shadow;
      trig_count  <= trig_count_shadow;
      enable_reg  <= enable_shadow;
      invert      <= invert_shadow;
      initial_val <= initial_val_shadow;
    end
 
   assign enable = soft_start_req ||  enable_reg;
 
endmodule