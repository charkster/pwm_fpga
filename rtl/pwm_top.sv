
module pwm_top (
  input  logic clk,      // board clock, this should be faster than SCL
  input  logic button_0, // button closest to PMOD connector
  input  logic scl,
  inout  wire  sda,
  output logic pwm_out 
);

  logic rst_n;
  logic sda_out;
  logic sda_in;
  
  logic [7:0] addr;
  logic [7:0] wdata;
  logic [7:0] rdata;
  logic       wr_en_wdata;
  logic       wr_en_wdata_sync;
  logic [1:0] sda_shift;
  
  logic [15:0] period;
  logic [15:0] phase;
  logic [15:0] duty_cycle;
  logic  [2:0] trig_count;
  logic        enable;
  logic        invert;
  logic        initial_val; 
  
  logic [15:0] period_count;
  logic        update;
  logic        start;
  logic        clk_400mhz;
  logic        locked;
  
  assign sda_in = sda; // this is for read-ablity
  
  clk_wiz_0 u_clk_wiz_400mhz
  ( .clk_out1 (clk_400mhz), // output
    .reset    (button_0),   // input
    .locked,                // output
    .clk_in1  (clk)         // input
  );
  
  // button_0 is high when pressed
  synchronizer u_synchronous_rst_n
  ( .clk      (clk_400mhz), // input
    .rst_n    (locked),     // input
    .data_in  (1'b1),       // input
    .data_out (rst_n)       // output
  );
    
  bidir u_sda
  ( .pad    ( sda ),     // inout
    .to_pad ( sda_out ), // input
    .oe     ( ~sda_out)  // input, open drain
  );

  i2c_slave 
  # ( .SLAVE_ID(7'h24) )
  u_i2c_slave
  ( .rst_n,                // input 
    .scl,                  // input 
    .sda_in,               // input 
    .sda_out,              // output  
    .i2c_active      ( ),  // output 
    .rd_en           ( ),  // output
    .wr_en           ( ),  // output
    .rdata,                // input [7:0]
    .addr,                 // output [7:0]
    .wdata,                // output [7:0]
    .wr_en_wdata           // output
  );
  
  synchronizer u_wr_en_sync
  ( .clk      (clk_400mhz),      // input
    .rst_n    (rst_n),           // input
    .data_in  (wr_en_wdata),     // input
    .data_out (wr_en_wdata_sync) // output
  );

  reg_map u_reg_map
  ( .clk (clk_400mhz), // input
    .rst_n,            // input
    .addr,             // input [7:0], data is stable when used
    .wdata,            // input [7:0], data is stable when used
    .wr_en_wdata_sync, // input
    .update,           // input
    .rdata,            // output [7:0]
    .period,           // output [15:0]
    .phase,            // output [15:0]
    .duty_cycle,       // output [15:0]
    .trig_count,       // output [2:0]
    .enable,           // output
    .invert,           // output
    .initial_val,      // output
    .start             // output
  );
  
  period_counter u_period_counter
  ( .clk (clk_400mhz), // input
    .rst_n,            // input
    .period,           // input [15:0]
    .start,            // input
    .period_count,     // output [15:0]
    .update            // output
  );

  pwm u_pwm
  ( .clk  (clk_400mhz), // input
    .rst_n,             // input
    .period_count,      // input [15:0]
    .period,            // input [15:0]
    .phase,             // input [15:0]
    .duty_cycle,        // input [15:0]
    .trig_count,        // input [2:0]
    .enable,            // input
    .invert,            // input
    .initial_val,       // input
    .pwm_out            // output
  ); 

endmodule