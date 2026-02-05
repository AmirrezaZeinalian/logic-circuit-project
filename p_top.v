`timescale 1ns / 1ps

module DCD_Project_Top #(
    parameter N = 8
)(
    input wire clk,
    input wire rst_n,
    input wire tick_1s,       // External 1Hz pulse
    
    // --- System Control ---
    input wire sys_mode_sw,   // 0: Calculator Mode, 1: Clock Mode
    
    // --- Calculator Inputs ---
    input wire start_btn,     // Button to start calculation
    input wire [3:0] opcode,  // Switch for operation
    input wire signed [N-1:0] A_in, // Switches for A
    input wire signed [N-1:0] B_in, // Switches for B
    
    // --- Clock Settings Inputs ---
    input wire set_mode_sw,   // 1: Enable Set Mode
    input wire [2:0] field_sel, // Select field to edit
    input wire inc_btn,       // Button to increment
    input wire dec_btn,       // Button to decrement
    
    // --- Outputs ---
    output wire [6:0] seg,    // 7-segment cathodes
    output wire [7:0] an,     // 7-segment anodes
    output wire done_led,     // LED to indicate calculation done
    output wire error_led     // LED to indicate error
);

    // --- Internal Signals ---
    
    // ALU Signals
    wire alu_start;
    wire alu_ready;
    wire signed [2*N-1:0] alu_result;
    wire alu_Z, alu_C, alu_V, alu_S, alu_E;
    
    // Clock Signals
    wire [5:0] sec, min;
    wire [4:0] hour, day;
    wire [3:0] month;
    wire [6:0] year;
    
    // FSM State Encoding
    localparam STATE_CALC_IDLE  = 2'b00;
    localparam STATE_CALC_EXEC  = 2'b01;
    localparam STATE_CALC_DONE  = 2'b10;
    localparam STATE_CLOCK      = 2'b11;
    
    reg [1:0] current_state, next_state;
    
    // Display Subsystem Control Signals
    reg [1:0] disp_mode;
    
    // --- 1. State Machine (FSM) ---
    
    // Sequential Logic: State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= STATE_CALC_IDLE;
        else 
            current_state <= next_state;
    end
    
    // Combinational Logic: Next State Logic
    always @(*) begin
        next_state = current_state; // Default to stay
        
        // If System Switch is on Clock, override everything (Simple Priority)
        if (sys_mode_sw == 1) begin
            next_state = STATE_CLOCK;
        end 
        else begin
            // Calculator Logic
            case (current_state)
                STATE_CLOCK: begin
                     if (sys_mode_sw == 0) next_state = STATE_CALC_IDLE;
                end
                
                STATE_CALC_IDLE: begin
                    if (start_btn) next_state = STATE_CALC_EXEC;
                end
                
                STATE_CALC_EXEC: begin
                    if (alu_ready) next_state = STATE_CALC_DONE;
                end
                
                STATE_CALC_DONE: begin
                    // Stay showing result until start pressed again or mode switch
                    if (start_btn) next_state = STATE_CALC_EXEC; 
                end
                
                default: next_state = STATE_CALC_IDLE;
            endcase
        end
    end

    // FSM Outputs & Control Logic
    // We generate a pulse for ALU start only in the transition to EXEC
    // Ideally, we need edge detection for buttons, but here we use state based control.
    
    // Generate ALU Start (active high pulse)
    assign alu_start = (current_state == STATE_CALC_EXEC) && (!alu_ready); 

    // LED Outputs
    assign done_led = (current_state == STATE_CALC_DONE);
    assign error_led = alu_E;

    // Display Mode Logic
    always @(*) begin
        case (current_state)
            STATE_CLOCK:     disp_mode = 2'b01; // CLOCK
            STATE_CALC_DONE: disp_mode = (alu_E) ? 2'b11 : 2'b00; // ERROR or CALC
            default:         disp_mode = 2'b00; // Default to CALC (shows 0 or previous)
        endcase
    end

    // --- 2. Module Instantiations ---
    
    ALU #( .N(N) ) alu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(alu_start),
        .opcode(opcode),
        .A(A_in),
        .B(B_in),
        .ready(alu_ready),
        .result(alu_result),
        .Z(alu_Z), .C(alu_C), .V(alu_V), .S(alu_S), .E(alu_E)
    );
    
    Clock_Calendar clock_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1s(tick_1s),
        .set_mode(set_mode_sw),
        .field_sel(field_sel),
        .inc(inc_btn),
        .dec(dec_btn),
        .seconds(sec),
        .minutes(min),
        .hours(hour),
        .day(day),
        .month(month),
        .year(year)
    );
    
    Display_Subsystem display_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mode(disp_mode),
        .alu_result(alu_result[15:0]), // Map 2N result to 16-bit display input
        .alu_sign(alu_result[2*N-1]),  // Sign bit
        .alu_error(alu_E),
        .sec(sec),
        .min(min),
        .hour(hour),
        .seg_out(seg),
        .an_out(an)
    );

endmodule