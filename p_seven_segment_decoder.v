
`timescale 1ns / 1ps

module Seven_Segment_Decoder(
    input wire [3:0] data_in, // 0-9 for numbers, A-F for Hex/Error
    output reg [6:0] seg      // g f e d c b a (Standard mapping)
);

    // Active High Logic (1 means ON). If your board is Active Low, invert these.
    // Mapping: a=0, b=1, c=2, d=3, e=4, f=5, g=6 inside the vector usually, 
    // but let's stick to standard hex representation for [6:0] = gfedcba
    
    always @(*) begin
        case (data_in)
            //                  gfedcba
            4'h0: seg = 7'b0111111; // 0
            4'h1: seg = 7'b0000110; // 1
            4'h2: seg = 7'b1011011; // 2
            4'h3: seg = 7'b1001111; // 3
            4'h4: seg = 7'b1100110; // 4
            4'h5: seg = 7'b1101101; // 5
            4'h6: seg = 7'b1111101; // 6
            4'h7: seg = 7'b0000111; // 7
            4'h8: seg = 7'b1111111; // 8
            4'h9: seg = 7'b1101111; // 9
            
            // Special Characters
            4'hA: seg = 7'b1000000; // Dash (-) for negative sign
            4'hE: seg = 7'b1111001; // 'E' for Error
            4'hF: seg = 7'b0000000; // Blank (Space)
            
            default: seg = 7'b0000000; // Blank
        endcase
    end
endmodule