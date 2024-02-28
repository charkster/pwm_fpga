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
   
   parameter SLAVE_ID = 7'h24;
   
   // FROM REGMAP
   parameter ADDR_PERIOD      = 0,
             ADDR_PWM_1_PHASE = 2,
             ADDR_PWM_1_DUTY  = 4,
             ADDR_PWM_1_CTRL  = 6,
             ADDR_TRIGGER     = 7;
   // FROM REGMAP
   parameter OFFSET_TRIG_CNT = 5,
              WIDTH_TRIG_CNT = 3;
   // FROM REGMAP
   parameter OFFSET_ENABLE   = 0,
              WIDTH_ENABLE   = 1;

   logic  [7:0] i2c_read_data;
   logic [15:0] i2c_read_word;

   initial begin
      #EXT_CLK_PERIOD_NS;
      reset = 1'b1;
      #EXT_CLK_PERIOD_NS;
      reset = 1'b0;
      repeat(100) #EXT_CLK_PERIOD_NS;
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PERIOD,      16'd240);
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PWM_1_PHASE, 16'd10);
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PWM_1_DUTY,  16'd20);
      u_mstr_i2c.i2c_read_word (SLAVE_ID,ADDR_PERIOD, i2c_read_word); // this has the value of 240
      u_mstr_i2c.i2c_write     (SLAVE_ID,ADDR_TRIGGER,      8'h01);
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PERIOD,      16'd200);
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PWM_1_PHASE, 16'd8);
      u_mstr_i2c.i2c_write_word(SLAVE_ID,ADDR_PWM_1_DUTY,  16'd10);
      u_mstr_i2c.i2c_bf_write  (SLAVE_ID,ADDR_PWM_1_CTRL, 3'd4, OFFSET_TRIG_CNT, WIDTH_TRIG_CNT); // trig_count, shadow
      u_mstr_i2c.i2c_bf_write  (SLAVE_ID,ADDR_PWM_1_CTRL, 1'b1, OFFSET_ENABLE,   WIDTH_ENABLE);   // enable bit, shadow
      u_mstr_i2c.i2c_write     (SLAVE_ID,ADDR_TRIGGER,      8'h02);   // soft start request
      u_mstr_i2c.i2c_read_word (SLAVE_ID,ADDR_PERIOD, i2c_read_word); // this has the value of 200
      u_mstr_i2c.i2c_bf_write  (SLAVE_ID,ADDR_PWM_1_CTRL, 1'b0, OFFSET_ENABLE, WIDTH_ENABLE); // enable-off, shadow
      u_mstr_i2c.i2c_read      (SLAVE_ID,ADDR_TRIGGER,    i2c_read_data);
	  repeat(100) #EXT_CLK_PERIOD_NS;
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
