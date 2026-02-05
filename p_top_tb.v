`timescale 1ns / 1ps

module DCD_Project_Top_tb;

    // Parameters
    parameter N = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg tick_1s;
    reg sys_mode_sw;
    reg start_btn;
    reg [3:0] opcode;
    reg signed [N-1:0] A_in;
    reg signed [N-1:0] B_in;
    reg set_mode_sw;
    reg [2:0] field_sel;
    reg inc_btn;
    reg dec_btn;

    // Outputs
    wire [6:0] seg;
    wire [7:0] an;
    wire done_led;
    wire error_led;

    // Instantiate the Top Module
    DCD_Project_Top #(
        .N(N)
    ) uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .tick_1s(tick_1s), 
        .sys_mode_sw(sys_mode_sw), 
        .start_btn(start_btn), 
        .opcode(opcode), 
        .A_in(A_in), 
        .B_in(B_in), 
        .set_mode_sw(set_mode_sw), 
        .field_sel(field_sel), 
        .inc_btn(inc_btn), 
        .dec_btn(dec_btn), 
        .seg(seg), 
        .an(an), 
        .done_led(done_led), 
        .error_led(error_led)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test Procedure
    initial begin
        // Initialize Inputs
        rst_n = 0;
        tick_1s = 0;
        sys_mode_sw = 0; // Start in Calculator Mode
        start_btn = 0;
        opcode = 0;
        A_in = 0;
        B_in = 0;
        set_mode_sw = 0;
        field_sel = 0;
        inc_btn = 0;
        dec_btn = 0;

        // Reset
        #20;
        rst_n = 1;
        #10;

        // --- SCENARIO 1: CALCULATOR ADD (10 + 5) ---
        $display("--- Scenario 1: Calculator ADD (10 + 5) ---");
        sys_mode_sw = 0; // Calc Mode
        opcode = 4'b0000; // ADD
        A_in = 8'd10;
        B_in = 8'd5;
        
        // Press Start
        @(posedge clk);
        start_btn = 1;
        @(posedge clk);
        start_btn = 0;
        
        // Wait for Done LED
        wait(done_led);
        #100; // Increased delay to ensure signals are stable
        $display("Calc Done. LED is ON. Check Waveform for Segments.");

        // --- SCENARIO 2: ERROR HANDLING (DIV BY ZERO) ---
        $display("--- Scenario 2: Calculator DIV by ZERO ---");
        // Reset Inputs for next test (Optional but good practice)
        start_btn = 0;
        
        opcode = 4'b0011; // DIV
        A_in = 8'd50;
        B_in = 8'd0;
        
        @(posedge clk);
        start_btn = 1;
        @(posedge clk);
        start_btn = 0;
        
        wait(done_led);
        #100; // FIX: Increased checking delay from 10 to 100ns
        
        if (error_led) $display("SUCCESS: Error LED is correctly ON.");
        else $display("FAIL: Error LED NOT ON (Value: %b)", error_led);
        
        #50;

        // --- SCENARIO 3: CLOCK MODE ---
        $display("--- Scenario 3: Switch to Clock Mode ---");
        sys_mode_sw = 1; // Switch to Clock
        
        // Simulate time passing (generate ticks)
        repeat(5) begin
            #90;
            @(posedge clk); tick_1s = 1;
            @(posedge clk); tick_1s = 0;
        end
        $display("Clock Ticking. Check Waveform.");

        // --- SCENARIO 4: SET CLOCK ---
        $display("--- Scenario 4: Setting the Clock ---");
        set_mode_sw = 1;
        field_sel = 3'd1; // Minutes
        
        // Press INC twice
        repeat(2) begin
            @(posedge clk); inc_btn = 1;
            @(posedge clk); inc_btn = 0;
            #20;
        end
        set_mode_sw = 0;
        
        #100;
        $stop;
    end

endmodule