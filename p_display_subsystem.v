
`timescale 1ns / 1ps

module Display_Subsystem(
    input wire clk,
    input wire rst_n,
    
    // Mode Control
    input wire [1:0] mode, // 00: CALC, 01: CLOCK, 10: DATE (Optional), 11: ERROR
    
    // Data Inputs (CALC)
    input wire signed [15:0] alu_result, // 2*N = 16 bits
    input wire alu_sign,                 // Sign of the result
    input wire alu_error,                // Error Flag
    
    // Data Inputs (CLOCK)
    input wire [5:0] sec,
    input wire [5:0] min,
    input wire [4:0] hour,
    
    // Hardware Outputs
    output reg [6:0] seg_out, // Connect to FPGA segments
    output reg [7:0] an_out   // Connect to FPGA anodes (Active Low usually)
);

    // Internal Signals
    reg [3:0] digits [7:0]; // 8 digits to hold data for display (Index 0 is Rightmost)
    wire [6:0] decoded_seg;
    reg [3:0] current_digit_val;
    
    // Refresh Counter for Multiplexing
    // Assuming 50MHz or 100MHz clock, we need to switch digits every ~1-5ms.
    // 17-bit counter covers reasonable range.
    reg [16:0] refresh_counter;
    wire [2:0] digit_sel; // Selects which of the 8 digits is active (0 to 7)

    assign digit_sel = refresh_counter[16:14]; // Use MSBs for scanning

    // --- Instantiations ---
    Seven_Segment_Decoder decoder (
        .data_in(current_digit_val),
        .seg(decoded_seg)
    );

    // --- Logic ---
    
    // 1. Binary to BCD Conversion (Combinational) for ALU Result
    // 16-bit signed number can be up to +/- 32767 (5 digits)
    reg [15:0] abs_result;
    reg [3:0] bcd_0, bcd_1, bcd_2, bcd_3, bcd_4; // Ones, Tens, Hundreds, ...
    
    always @(*) begin
        // Calculate Absolute Value
        abs_result = (alu_result[15]) ? -alu_result : alu_result;
        
        // Simple Behavioral Binary-to-BCD (Synthesis tool handles the math)
        bcd_0 = abs_result % 10;
        bcd_1 = (abs_result / 10) % 10;
        bcd_2 = (abs_result / 100) % 10;
        bcd_3 = (abs_result / 1000) % 10;
        bcd_4 = (abs_result / 10000) % 10;
    end
    
    // 2. Prepare Digits based on Mode
    integer i;
    always @(*) begin
        // Default blanking
        for(i=0; i<8; i=i+1) digits[i] = 4'hF; // F is Blank in our decoder
        
        if (mode == 2'b11 || alu_error) begin 
            // --- ERROR MODE ---
            digits[0] = 4'hE; // 'E'
            digits[1] = 4'hA; // '-'
            digits[2] = 4'hA; // '-'
            digits[3] = 4'hA; // '-'
        end
        else if (mode == 2'b01) begin
            // --- CLOCK MODE (HH-MM-SS) ---
            // Sec
            digits[0] = sec % 10;
            digits[1] = sec / 10;
            // Min
            digits[3] = min % 10;
            digits[4] = min / 10;
            // Hour
            digits[6] = hour % 10;
            digits[7] = hour / 10;
            // Dashes are hard to do without decimal point, leaving blanks for separators at 2 and 5
        end
        else begin
            // --- CALCULATOR MODE ---
            // Display Number (Right aligned)
            digits[0] = bcd_0;
            digits[1] = bcd_1;
            digits[2] = bcd_2;
            digits[3] = bcd_3;
            digits[4] = bcd_4;
            
            // Leading Zero Suppression (Optional but recommended)
            // Simple logic: If higher digits are 0, make them blank (F)
            if (abs_result < 10000) digits[4] = 4'hF;
            if (abs_result < 1000)  digits[3] = 4'hF;
            if (abs_result < 100)   digits[2] = 4'hF;
            if (abs_result < 10)    digits[1] = 4'hF;
            
            // Negative Sign handling
            // We need to place '-' to the left of the most significant digit
            if (alu_sign) begin
                 if (abs_result >= 10000) digits[5] = 4'hA;
                 else if (abs_result >= 1000) digits[4] = 4'hA;
                 else if (abs_result >= 100)  digits[3] = 4'hA;
                 else if (abs_result >= 10)   digits[2] = 4'hA;
                 else digits[1] = 4'hA;
            end
        end
    end

    // 3. Multiplexing Loop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 0;
            an_out <= 8'b11111111; // All OFF (Active Low)
            seg_out <= 7'b0000000;
        end else begin
            refresh_counter <= refresh_counter + 1;
            
            // Output Logic
            current_digit_val <= digits[digit_sel]; // Fetch data for current digit
            seg_out <= decoded_seg; // Output segments
            
            // Activate One Anode (Active Low: 0 means ON)
            case (digit_sel)
                3'b000: an_out <= 8'b11111110; // Digit 0 (Rightmost)
                3'b001: an_out <= 8'b11111101;
                3'b010: an_out <= 8'b11111011;
                3'b011: an_out <= 8'b11110111;
                3'b100: an_out <= 8'b11101111;
                3'b101: an_out <= 8'b11011111;
                3'b110: an_out <= 8'b10111111;
                3'b111: an_out <= 8'b01111111; // Digit 7 (Leftmost)
            endcase
        end
    end

endmodule