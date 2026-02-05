
`timescale 1ns / 1ps

module ALU_tb;

    // Parameters
    parameter N = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [3:0] opcode;
    reg signed [N-1:0] A;
    reg signed [N-1:0] B;

    // Outputs
    wire ready;
    wire signed [2*N-1:0] result;
    wire Z, C, V, S, E;

    // Instantiate the Unit Under Test (UUT)
    ALU #(
        .N(N)
    ) uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .opcode(opcode), 
        .A(A), 
        .B(B), 
        .ready(ready), 
        .result(result), 
        .Z(Z), .C(C), .V(V), .S(S), .E(E)
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
        start = 0;
        opcode = 0;
        A = 0;
        B = 0;

        // Reset Pulse
        #20;
        rst_n = 1;
        #10;

        // --- Test 1: ADD (10 + 5) ---
        $display("Test 1: ADD (10 + 5)");
        drive_input(4'b0000, 8'd10, 8'd5);
        
        // --- Test 2: SUB (10 - 20) -> Negative Result ---
        $display("Test 2: SUB (10 - 20)");
        drive_input(4'b0001, 8'd10, 8'd20);

        // --- Test 3: MUL (10 * -5) ---
        $display("Test 3: MUL (10 * -5)");
        drive_input(4'b0010, 8'd10, -8'd5);

        // --- Test 4: DIV (100 / 4) ---
        $display("Test 4: DIV (100 / 4)");
        drive_input(4'b0011, 8'd100, 8'd4);

        // --- Test 5: DIV by Zero (Error Check) ---
        $display("Test 5: DIV by Zero");
        drive_input(4'b0011, 8'd50, 8'd0);

        // --- Test 6: EQ (25 == 25) ---
        $display("Test 6: EQ (25 == 25)");
        drive_input(4'b1011, 8'd25, 8'd25);

        $stop;
    end

    // Task to drive inputs and wait for ready
    task drive_input;
        input [3:0] op;
        input signed [N-1:0] inA;
        input signed [N-1:0] inB;
        begin
            @(posedge clk);
            start = 1;
            opcode = op;
            A = inA;
            B = inB;
            @(posedge clk);
            start = 0;
            
            // Wait for ready signal
            wait(ready);
            @(posedge clk);
            
            // Display Result
            $display("Op: %b, A: %d, B: %d -> Result: %d, Flags(ZCVSE): %b%b%b%b%b", 
                     opcode, A, B, result, Z, C, V, S, E);
            $display("--------------------------------");
        end
    endtask

endmodule