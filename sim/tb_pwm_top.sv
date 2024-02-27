module tb_i2c_top ();

   parameter EXT_CLK_PERIOD_NS = 100;
   
   reg         clk;
   reg         reset;

   initial begin
      clk = 1'b0;
      forever
        #(EXT_CLK_PERIOD_NS/2) clk = ~clk;
   end

   //----------
   // I2C
   //----------
   wire sda;
   wire scl;

   pullup(sda);
   pullup(scl);

   // I2C Master instance
   i2c_master
      #( .value   ( "FAST" ),  // 400MHz
         .scl_min ( "HIGH" ) ) // this is the most aggressive
   u_mstr_i2c
     ( .sda       ( sda ), // inout
       .scl       ( scl )  // output
     );
   
   parameter ADDR_PERIOD      = 0,
             ADDR_PWM_1_PHASE = 2,
             ADDR_PWM_1_DUTY  = 4,
             ADDR_PWM_1_CTRL  = 6,
             ADDR_TRIGGER     = 7;
   
   //2 byte write
   task i2c_word_write;
     input  [7:0] addr;
     input [15:0] wdata;
     logic  [7:0] wbuffer;
     begin
       wbuffer = wdata; // lower 8bits
       u_mstr_i2c.i2c_write(7'h24, addr, wbuffer);
       wbuffer = wdata >> 8;
       u_mstr_i2c.i2c_write(7'h24, addr + 1, wbuffer);
     end
   endtask
   
   // read-modify-write
   task i2c_bf_write;
     input [7:0] addr;      // address
     input [7:0] bit_value; // bitfield value
     input [7:0] offset;    // offset to bitfield
     input [7:0] width;     // width of bitfield
     logic [7:0] bit_mask;
     logic [7:0] mod_val;
     logic [7:0] read_data;
     begin
       u_mstr_i2c.i2c_read (7'h24, addr, read_data);
       bit_mask = (2 ** width - 1) << offset;
       mod_val = (read_data & (~bit_mask)) + (bit_value << offset);
       u_mstr_i2c.i2c_write(7'h24, addr, mod_val);
     end
   endtask

   logic [7:0] i2c_read_data;

   initial begin
      #EXT_CLK_PERIOD_NS;
      reset = 1'b1;
      #EXT_CLK_PERIOD_NS;
      reset = 1'b0;
      repeat(10) #EXT_CLK_PERIOD_NS;
      u_mstr_i2c.i2c_read (7'h24, 8'h00, i2c_read_data);
      i2c_word_write(ADDR_PERIOD,16'd240);
      i2c_word_write(ADDR_PWM_1_PHASE, 16'd10);
      i2c_word_write(ADDR_PWM_1_DUTY,  16'd20);
      u_mstr_i2c.i2c_write(7'h24, ADDR_TRIGGER, 8'h01);
      i2c_word_write(ADDR_PERIOD,16'd200);
      i2c_word_write(ADDR_PWM_1_PHASE, 16'd8);
      i2c_word_write(ADDR_PWM_1_DUTY,  16'd10);
      i2c_bf_write(ADDR_PWM_1_CTRL,3'd4,8'd5,8'd3); // trig_count
      i2c_bf_write(ADDR_PWM_1_CTRL,1'b1, 8'd0,8'd1); // enable, shadow
      u_mstr_i2c.i2c_write(7'h24, ADDR_TRIGGER, 8'h02); // soft start request
      u_mstr_i2c.i2c_read (7'h24, 8'h00, i2c_read_data);
      u_mstr_i2c.i2c_read (7'h24, 8'h01, i2c_read_data);
      i2c_bf_write(ADDR_PWM_1_CTRL,1'b0,8'd0,8'd1); // enable-off
      u_mstr_i2c.i2c_read (7'h24, 8'h03, i2c_read_data);
	  repeat(10) #EXT_CLK_PERIOD_NS;
      $finish;
   end

   pwm_top u_pwm_top
     ( .clk,                      // input  
       .button_0   ( reset     ), // input  
       .scl	       ( scl       ), // input  
       .sda	       ( sda       ), // inout
       .pwm_out    (           )  // output
       );


endmodule
