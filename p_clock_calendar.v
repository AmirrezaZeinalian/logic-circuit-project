
`timescale 1ns / 1ps

module Clock_Calendar(
    input wire clk,
    input wire rst_n,
    input wire tick_1s,       // Pulse every 1 second
    
    // --- Setting Interface (Bonus) ---
    input wire set_mode,      // 1: Setup Mode, 0: Normal Run Mode
    input wire [2:0] field_sel, // Select field to edit: 0:Sec, 1:Min, 2:Hr, 3:Day, 4:Mon, 5:Yr
    input wire inc,           // Increment selected field (pulse)
    input wire dec,           // Decrement selected field (pulse)
    
    // --- Time & Date Outputs ---
    output reg [5:0] seconds, // 0-59
    output reg [5:0] minutes, // 0-59
    output reg [4:0] hours,   // 0-23
    output reg [4:0] day,     // 1-31
    output reg [3:0] month,   // 1-12
    output reg [6:0] year     // 0-99 (represents 1400-1499 or 2000-2099)
);

    // Days in each month (Simplified Solar/Jalali style for example: first 6 are 31, next 5 are 30, last is 29)
    // Index 0 is dummy. Months are 1-12.
    // Change this logic if you strictly want Gregorian or specific calendar.
    reg [4:0] days_in_month [1:12];
    
    initial begin
        // Example: First 6 months have 31 days, next 5 have 30, last has 29 (Standard Hijri Solar)
        days_in_month[1] = 31; days_in_month[2] = 31; days_in_month[3] = 31; 
        days_in_month[4] = 31; days_in_month[5] = 31; days_in_month[6] = 31;
        days_in_month[7] = 30; days_in_month[8] = 30; days_in_month[9] = 30; 
        days_in_month[10] = 30; days_in_month[11] = 30; days_in_month[12] = 29; // Assume non-leap for simplicity
    end

    // Internal edge detection for inc/dec buttons (to avoid racing)
    // Assuming inc/dec inputs are already debounced or single-cycle pulses from a controller
    // If they are push-buttons, we treat them as active high pulses here.

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to a default time/date (e.g., 00:00:00, 1404/01/01)
            seconds <= 0;
            minutes <= 0;
            hours   <= 0;
            day     <= 1;
            month   <= 1;
            year    <= 4; // Example: 1404
        end else begin
            if (set_mode) begin
                // --- SETTING MODE ---
                // Only change the selected field based on inc/dec inputs
                // Note: Logic assumes 'inc' and 'dec' are single-cycle pulses
                
                if (inc) begin
                    case (field_sel)
                        3'd0: seconds <= (seconds == 59) ? 0 : seconds + 1;
                        3'd1: minutes <= (minutes == 59) ? 0 : minutes + 1;
                        3'd2: hours   <= (hours == 23)   ? 0 : hours + 1;
                        3'd3: day     <= (day >= days_in_month[month]) ? 1 : day + 1;
                        3'd4: month   <= (month == 12)   ? 1 : month + 1;
                        3'd5: year    <= (year == 99)    ? 0 : year + 1;
                    endcase
                end
                else if (dec) begin
                    case (field_sel)
                        3'd0: seconds <= (seconds == 0) ? 59 : seconds - 1;
                        3'd1: minutes <= (minutes == 0) ? 59 : minutes - 1;
                        3'd2: hours   <= (hours == 0)   ? 23 : hours - 1;
                        3'd3: day     <= (day == 1)     ? days_in_month[month] : day - 1;
                        3'd4: month   <= (month == 1)   ? 12 : month - 1;
                        3'd5: year    <= (year == 0)    ? 99 : year - 1;
                    endcase
                end
            end 
            else begin
                // --- NORMAL RUN MODE ---
                if (tick_1s) begin
                    if (seconds == 59) begin
                        seconds <= 0;
                        if (minutes == 59) begin
                            minutes <= 0;
                            if (hours == 23) begin
                                hours <= 0;
                                // Date Increment Logic
                                if (day == days_in_month[month]) begin
                                    day <= 1;
                                    if (month == 12) begin
                                        month <= 1;
                                        year <= (year == 99) ? 0 : year + 1;
                                    end else begin
                                        month <= month + 1;
                                    end
                                end else begin
                                    day <= day + 1;
                                end
                            end else begin
                                hours <= hours + 1;
                            end
                        end else begin
                            minutes <= minutes + 1;
                        end
                    end else begin
                        seconds <= seconds + 1;
                    end
                end
            end
        end
    end

endmodule