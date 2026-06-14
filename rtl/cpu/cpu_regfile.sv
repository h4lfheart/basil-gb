import cpu_types::*;

module cpu_regfile (
    input logic clk,
    input logic rst,
    input tcycle_t tcycle,

    input logic wr_r8,
    input r8_t wr_reg_r8,
    input logic [7:0] wr_data_r8,

    input logic wr_r16,
    input r16_t wr_reg_r16,
    input logic [15:0] wr_data_r16,

    input logic wr_flags,
    input flags_t wr_data_flags,

    output logic [7:0] A,
    output logic [7:0] B,
    output logic [7:0] C,
    output logic [7:0] D,
    output logic [7:0] E,
    output logic [7:0] H,
    output logic [7:0] L,
    output logic [15:0] SP,
    output flags_t F
);

    always_ff @(posedge clk) begin
        if (rst) begin
            A <= 'h00;
            B <= 'h00;
            C <= 'h00;
            D <= 'h00;
            E <= 'h00;
            H <= 'h00;
            L <= 'h00;
            SP <= 'h0000;
            F <= '0;
        end else if (tcycle == T3) begin
            if (wr_r8) begin
                case (wr_reg_r8)
                    R8_A: A <= wr_data_r8;
                    R8_B: B <= wr_data_r8;
                    R8_C: C <= wr_data_r8;
                    R8_D: D <= wr_data_r8;
                    R8_E: E <= wr_data_r8;
                    R8_H: H <= wr_data_r8;
                    R8_L: L <= wr_data_r8;
                endcase
            end

            if (wr_r16) begin
                case (wr_reg_r16)
                    R16_BC: {B, C} <= wr_data_r16;
                    R16_DE: {D, E} <= wr_data_r16;
                    R16_HL: {H, L} <= wr_data_r16;
                    R16_SP: SP <= wr_data_r16;
                    R16_AF: begin
                        A <= wr_data_r16[15:8];
                        F <= flags_t'(wr_data_r16[7:0] & 8'hF0);
                    end
                endcase
            end

            if (wr_flags)
                F <= wr_data_flags;
        end
    end

endmodule