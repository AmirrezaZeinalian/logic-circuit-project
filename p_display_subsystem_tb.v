
`timescale 1ns / 1ps

module Display_Subsystem_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg [1:0] mode;
    reg signed [15:0] alu_result;
    reg alu_sign;
    reg alu_error;
    reg [5:0] sec;
    reg [5:0] min;
    reg [4:0] hour;

    // Outputs
    wire [6:0] seg_out;
    wire [7:0] an_out;

    // Instantiate UUT
    Display_Subsystem uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .mode(mode), 
        .alu_result(alu_result), 
        .alu_sign(alu_sign), 
        .alu_error(alu_error), 
        .sec(sec), 
        .min(min), 
        .hour(hour), 
        .seg_out(seg_out), 
        .an_out(an_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize
        rst_n = 0;
        mode = 0;
        alu_result = 0;
        alu_sign = 0;
        alu_error = 0;
        sec = 0; min = 0; hour = 0;
        
        #20 rst_n = 1;
        
        // --- Test 1: Calculator Mode (Display 123) ---
        $display("Test 1: Calc Mode, Number 123");
        mode = 2'b00; // Calc
        alu_result = 16'd123;
        alu_sign = 0;
        
        // Wait enough time to scan through a few digits
        #2000;
        
        // --- Test 2: Negative Number (-45) ---
        $display("Test 2: Calc Mode, Number -45");
        alu_result = 16'd45;
        alu_sign = 1;
        
        #2000;
        
        // --- Test 3: Clock Mode (12:30:45) ---
        $display("Test 3: Clock Mode, 12:30:45");
        mode = 2'b01; // Clock
        hour = 12;
        min = 30;
        sec = 45;
        
        #2000;
        
        // --- Test 4: Error Mode ---
        $display("Test 4: Error Mode");
        alu_error = 1;
        
        #1000;
        
        $stop;
    end

endmodule