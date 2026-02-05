`timescale 1ns / 1ps

module ALU #(
    parameter N = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [3:0]            opcode,
    input  wire signed [N-1:0]   A,
    input  wire signed [N-1:0]   B,

    output reg                   ready,
    output reg signed [2*N-1:0]  result,

    output reg                   Z,
    output reg                   C,
    output reg                   V,
    output reg                   S,
    output reg                   E
);

    // shift amount width = log2(N)
    localparam integer SHW = (N <= 1) ? 1 : $clog2(N);

    // latched inputs
    reg [3:0]          op_r;
    reg signed [N-1:0] A_r, B_r;

    reg pending;

    // combinational next values
    reg signed [2*N-1:0] res_next;
    reg Z_next, C_next, V_next, S_next, E_next;

    // helpers
    reg [N:0] add_u, sub_u;
    reg signed [N-1:0] add_n, sub_n;

    reg signed [N-1:0] div_q;
    reg signed [N-1:0] mod_r;

    wire [SHW-1:0] shamt;
    assign shamt = B_r[SHW-1:0];

    always @(*) begin
        // defaults
        res_next = '0;
        Z_next   = 1'b0;
        C_next   = 1'b0;
        V_next   = 1'b0;
        S_next   = 1'b0;
        E_next   = 1'b0;

        add_u = {1'b0, $unsigned(A_r)} + {1'b0, $unsigned(B_r)};
        sub_u = {1'b0, $unsigned(A_r)} - {1'b0, $unsigned(B_r)};
        add_n = A_r + B_r;
        sub_n = A_r - B_r;

        div_q = '0;
        mod_r = '0;

        case (op_r)
            4'b0000: begin // ADD
                res_next = {{N{add_n[N-1]}}, add_n};
                C_next   = add_u[N];
                V_next   = (A_r[N-1] == B_r[N-1]) && (add_n[N-1] != A_r[N-1]);
            end

            4'b0001: begin // SUB
                res_next = {{N{sub_n[N-1]}}, sub_n};
                C_next   = ~sub_u[N]; // ~borrow convention
                V_next   = (A_r[N-1] != B_r[N-1]) && (sub_n[N-1] != A_r[N-1]);
            end

            4'b0010: begin // MUL
                res_next = A_r * B_r;
            end

            4'b0011: begin // DIV
                if (B_r == 0) begin
                    res_next = '0;
                    E_next   = 1'b1;
                end else begin
                    div_q    = A_r / B_r;
                    res_next = {{N{div_q[N-1]}}, div_q};
                end
            end

            4'b0100: begin // MOD
                if (B_r == 0) begin
                    res_next = '0;
                    E_next   = 1'b1;
                end else begin
                    mod_r    = A_r % B_r;
                    res_next = {{N{mod_r[N-1]}}, mod_r};
                end
            end

            4'b0101: res_next = {{N{1'b0}}, (A_r & B_r)};                 // AND
            4'b0110: res_next = {{N{1'b0}}, (A_r | B_r)};                 // OR
            4'b0111: res_next = {{N{1'b0}}, (A_r ^ B_r)};                 // XOR
            4'b1000: res_next = {{N{1'b0}}, (~A_r)};                      // NOT

            4'b1001: res_next = {{N{1'b0}}, ($unsigned(A_r) << shamt)};   // SHL (logical)
            4'b1010: res_next = {{N{1'b0}}, ($unsigned(A_r) >> shamt)};   // SHR (logical)

            4'b1011: res_next = {{(2*N-1){1'b0}}, (A_r == B_r)};          // EQ
            4'b1100: res_next = {{(2*N-1){1'b0}}, (A_r >  B_r)};          // GT
            4'b1101: res_next = {{(2*N-1){1'b0}}, (A_r <  B_r)};          // LT

            default: begin
                res_next = '0;
                E_next   = 1'b1;
            end
        endcase

        Z_next = (res_next == 0);
        S_next = res_next[2*N-1];
    end

    // sequential: capture on start, produce outputs next cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_r    <= 4'd0;
            A_r     <= '0;
            B_r     <= '0;
            pending <= 1'b0;

            result  <= '0;
            ready   <= 1'b0;

            Z <= 1'b0; C <= 1'b0; V <= 1'b0; S <= 1'b0; E <= 1'b0;
        end else begin
            ready <= 1'b0;

            if (start) begin
                op_r    <= opcode;
                A_r     <= A;
                B_r     <= B;
                pending <= 1'b1;
            end

            if (pending) begin
                result  <= res_next;
                Z       <= Z_next;
                C       <= C_next;
                V       <= V_next;
                S       <= S_next;
                E       <= E_next;

                ready   <= 1'b1;
                pending <= 1'b0;
            end
        end
    end

endmodule
