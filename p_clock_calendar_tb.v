
`timescale 1ns / 1ps

module Clock_Calendar_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg tick_1s;
    reg set_mode;
    reg [2:0] field_sel;
    reg inc;
    reg dec;

    // Outputs
    wire [5:0] seconds;
    wire [5:0] minutes;
    wire [4:0] hours;
    wire [4:0] day;
    wire [3:0] month;
    wire [6:0] year;

    // Instantiate the Unit Under Test (UUT)
    Clock_Calendar uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .tick_1s(tick_1s), 
        .set_mode(set_mode), 
        .field_sel(field_sel), 
        .inc(inc), 
        .dec(dec), 
        .seconds(seconds), 
        .minutes(minutes), 
        .hours(hours), 
        .day(day), 
        .month(month), 
        .year(year)
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
        set_mode = 0;
        field_sel = 0;
        inc = 0;
        dec = 0;

        // Reset
        #20;
        rst_n = 1;
        $display("Reset Complete. Time: %02d:%02d:%02d", hours, minutes, seconds);

        // --- Test 1: Normal Counting (Fast Forward) ---
        $display("--- Test 1: Normal Counting ---");
        // We will simulate 3 seconds passing
        repeat (3) begin
            #90; // Wait a bit
            @(posedge clk);
            tick_1s = 1; // Pulse tick
            @(posedge clk);
            tick_1s = 0;
        end
        
        #10;
        $display("Time after 3 ticks: %02d:%02d:%02d", hours, minutes, seconds);

        // --- Test 2: Set Mode (Change Hour) ---
        $display("--- Test 2: Set Mode (Set Hour to 23) ---");
        set_mode = 1;
        field_sel = 3'd2; // Select Hours (0=sec, 1=min, 2=hr)
        
        // Pulse 'dec' once to go from 00 to 23
        @(posedge clk);
        dec = 1;
        @(posedge clk);
        dec = 0;
        #10;
        $display("Time after DEC in Set Mode: %02d:%02d:%02d", hours, minutes, seconds);
        
        set_mode = 0; // Back to run mode

        // --- Test 3: Date Rollover (Manual force to end of day) ---
        // Let's force time to 23:59:59 using Set Mode first for speed
        $display("--- Test 3: Date Rollover Check ---");
        set_mode = 1;
        
        // Set Min to 59
        field_sel = 3'd1;
        repeat(59) begin
             @(posedge clk); inc = 1; @(posedge clk); inc = 0;
        end
        
        // Set Sec to 59
        field_sel = 3'd0;
        repeat(59) begin // Simple loop to increment
             @(posedge clk); inc = 1; @(posedge clk); inc = 0;
        end
        
        set_mode = 0;
        $display("Forced Time: %02d:%02d:%02d Date: %d/%d/%d", hours, minutes, seconds, year, month, day);
        
        // Now apply one tick to roll over
        @(posedge clk);
        tick_1s = 1;
        @(posedge clk);
        tick_1s = 0;
        
        #10;
        $display("After Rollover: %02d:%02d:%02d Date: %d/%d/%d", hours, minutes, seconds, year, month, day);

        $stop;
    end

endmodule