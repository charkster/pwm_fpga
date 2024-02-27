
module pwm (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] period_count, // common counter value for all pwm instances
  input  logic [15:0] period,       // number of clock counts for one complete cycle 
  input  logic [15:0] phase,        // delay until pwm_out goes active
  input  logic [15:0] duty_cycle,   // active duration of pwm_out
  input  logic  [2:0] trig_count,   // divides the period and period_count by multiples of 2
  input  logic        enable,
  input  logic        invert,       // invert defines the active level, if high level is low, else high
  input  logic        initial_val,  // pwm_out value when not enabled (does not obey invert)
  output logic        pwm_out 
);

  logic        phase_and_duty_gt_period;
  logic        duty_plus_phase_minus_period;
  logic [15:0] new_period;
  logic [15:0] new_period_count;
  logic [16:0] phase_plus_duty_cycle;
  
  // 2'd0 is no change, 2'd1 is div_by_2, 2'd2 is div_by_4 and 2'd3 is div_by_8
  assign new_period       = period / (trig_count + 1);
  assign new_period_count = period_count % new_period;
  
  assign phase_plus_duty_cycle = phase + duty_cycle;
  
  // this is for the case of large phase values, or large duty_cycle values, wrap-around is in effect
  assign phase_and_duty_gt_period = phase_plus_duty_cycle > {1'b0,new_period};
  
  // this is the active duration from the beginning of the period, when wrap-around is in effect
  assign duty_plus_phase_minus_period = phase_plus_duty_cycle - new_period;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)                                                                              pwm_out <= 1'b0;
    else if (!enable)                                                                        pwm_out <= initial_val;
    else if (phase_and_duty_gt_period && (new_period_count <  duty_plus_phase_minus_period)) pwm_out <= ~invert;
    else if (phase_and_duty_gt_period && (new_period_count == duty_plus_phase_minus_period)) pwm_out <=  invert;
    else if (new_period_count == phase)                                                      pwm_out <= ~invert;
    else if (!phase_and_duty_gt_period && (new_period_count == phase_plus_duty_cycle))       pwm_out <=  invert;

endmodule