`timescale 1ns / 1ps

module ALU #(
    parameter N = 8 // Input width (Default 8 bits based on project suggestion)
)(
    input wire clk,
    input wire rst_n,          // Asynchronous Active Low Reset
    input wire start,          // Start signal to begin operation
    input wire [3:0] opcode,   // Operation selection code (Table 1)
    input wire signed [N-1:0] A, // Input A (Signed)
    input wire signed [N-1:0] B, // Input B (Signed)
    
    output reg ready,          // Ready pulse when calculation is done
    output reg signed [2*N-1:0] result, // Output (2*N bits to handle multiplication)
    
    // Flags
    output reg Z, // Zero flag
    output reg C, // Carry flag
    output reg V, // Overflow flag
    output reg S, // Sign flag
    output reg E  // Error flag
);

    // Internal temporary result for full precision calculation
    reg signed [2*N:0] temp_result; 
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
            ready <= 0;
            Z <= 0; C <= 0; V <= 0; S <= 0; E <= 0;
            temp_result <= 0;
        end else begin
            // Default values
            ready <= 0; 
            
            if (start) begin
                // Reset flags for new operation
                E <= 0; V <= 0; C <= 0;
                
                case (opcode)
                    // --- Arithmetic Operations ---
                    4'b0000: begin // ADD
                        temp_result = A + B;
                        result <= temp_result[2*N-1:0];
                        // Carry check for unsigned interpretation (usually relevant for adder)
                        // Overflow check for signed: (pos+pos=neg) or (neg+neg=pos)
                        V <= ((A[N-1] == B[N-1]) && (result[N-1] != A[N-1]));
                        C <= temp_result[N]; // Capture carry out
                    end
                    
                    4'b0001: begin // SUB (A - B)
                        temp_result = A - B;
                        result <= temp_result[2*N-1:0];
                        // Overflow for sub: (pos-neg=neg) or (neg-pos=pos)
                        V <= ((A[N-1] != B[N-1]) && (result[N-1] != A[N-1]));
                        C <= temp_result[N]; // Borrow usually indicated here
                    end
                    
                    4'b0010: begin // MUL (Bonus)
                        result <= A * B;
                        // Overflow is less relevant in 2N output, but we keep V=0
                    end
                    
                    4'b0011: begin // DIV (Bonus)
                        if (B == 0) begin
                            result <= 0;
                            E <= 1; // Error: Divide by Zero
                        end else begin
                            result <= A / B;
                        end
                    end
                    
                    4'b0100: begin // MOD (Bonus)
                        if (B == 0) begin
                            result <= 0;
                            E <= 1; // Error: Divide by Zero
                        end else begin
                            result <= A % B;
                        end
                    end
                    
                    // --- Bitwise Operations ---
                    4'b0101: result <= A & B; // AND
                    4'b0110: result <= A | B; // OR
                    4'b0111: result <= A ^ B; // XOR
                    4'b1000: result <= ~A;    // NOT A (Bitwise Complement)
                    
                    // --- Shift Operations ---
                    // Using $unsigned(B) to use the value of B as shift amount
                    4'b1001: result <= A << $unsigned(B[2:0]); // SHL (Limit shift amount for safety)
                    4'b1010: result <= A >> $unsigned(B[2:0]); // SHR
                    
                    // --- Comparison Operations ---
                    4'b1011: result <= (A == B) ? 1 : 0; // EQ
                    4'b1100: result <= (A > B)  ? 1 : 0; // GT
                    4'b1101: result <= (A < B)  ? 1 : 0; // LT
                    
                    default: begin
                        result <= 0;
                        E <= 1; // Invalid Opcode
                    end
                endcase
                
                // Set common flags
                // Note: These are set based on the NEXT value of result (non-blocking simulation logic)
                // To be precise in hardware, we should assign them in the next cycle or use blocking assignments for temp vars.
                // Here we set 'ready' to 1 in the NEXT cycle, so the receiver reads the registered result.
                ready <= 1;
            end 
        end
    end

    // Flag Logic Update (Combinational or Registered? text implies flags are part of output)
    // We update Z and S based on the *current registered result* to ensure stability when ready is high.
    always @(posedge clk) begin
        if (start) begin
            // Wait for calculation to settle (next cycle)
        end else if (ready) begin
            Z <= (result == 0);
            S <= result[2*N-1]; // Sign bit of the 2N-bit output
        end
    end

endmodule