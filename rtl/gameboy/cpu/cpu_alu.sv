function automatic logic half_carry_add8(logic [7:0] a, logic [7:0] b, logic cin);
    return ((5'(a[3:0]) + 5'(b[3:0]) + 5'(cin)) > 5'hF);
endfunction

function automatic logic half_carry_sub8(logic [7:0] a, logic [7:0] b, logic cin);
    return (5'(b[3:0]) + 5'(cin) > 5'(a[3:0]));
endfunction

module cpu_alu(
    input alu_action_t action,
    input logic [7:0] a,
    input logic [7:0] b,
    input logic [2:0] bit_idx,
    input flags_t flags_in,
    input alu_z_mod_t z_mod,
    output logic [7:0] result,
    output flags_t flags
);

    always_comb begin
        result = 0;
        flags = 0;

        case (action)
            ALU_ACTION_BIT: begin
                flags.z = ~a[bit_idx];
                flags.n = 0;
                flags.h = 1;
                flags.c = flags_in.c;
            end

            ALU_ACTION_RES: begin
                result = a;
                result[bit_idx] = 0;

                flags = flags_in;
            end

            ALU_ACTION_SET: begin
                result = a;
                result[bit_idx] = 1;

                flags = flags_in;
            end

            ALU_ACTION_INC: begin
                result = a + 'd1;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = half_carry_add8(a, 'd1, 0);
                flags.c = flags_in.c;
            end

            ALU_ACTION_DEC: begin
                result = a - 'd1;

                flags.z = (result == 0);
                flags.n = 1;
                flags.h = half_carry_sub8(a, 'd1, 0);
                flags.c = flags_in.c;
            end

            ALU_ACTION_ADD: begin
                {flags.c, result} = {1'b0, a} + {1'b0, b};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = half_carry_add8(a, b, 0);
            end

            ALU_ACTION_ADC: begin
                {flags.c, result} = {1'b0, a} + {1'b0, b} + {1'b0, flags_in.c};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = half_carry_add8(a, b, flags_in.c);
            end

            ALU_ACTION_SUB: begin
                {flags.c, result} = {1'b0, a} - {1'b0, b};

                flags.z = (result == 0);
                flags.n = 1;
                flags.h = half_carry_sub8(a, b, 0);
            end

            ALU_ACTION_SBC: begin
                {flags.c, result} = {1'b0, a} - {1'b0, b} - {1'b0, flags_in.c};

                flags.z = (result == 0);
                flags.n = 1;
                flags.h = half_carry_sub8(a, b, flags_in.c);
            end

            ALU_ACTION_AND: begin
                result = a & b;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 1;
                flags.c = 0;
            end

            ALU_ACTION_OR: begin
                result = a | b;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = 0;
            end

            ALU_ACTION_XOR: begin
                result = a ^ b;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = 0;
            end

            ALU_ACTION_CPL: begin
                result = ~a;

                flags.z = flags_in.z;
                flags.n = 1;
                flags.h = 1;
                flags.c = flags_in.c;
            end

            ALU_ACTION_CCF: begin
                flags.z = flags_in.z;
                flags.n = 0;
                flags.h = 0;
                flags.c = ~flags_in.c;
            end

            ALU_ACTION_SCF: begin
                flags.z = flags_in.z;
                flags.n = 0;
                flags.h = 0;
                flags.c = 1;
            end

            ALU_ACTION_DAA: begin
                logic [7:0] adj;
                logic c_out;
                adj = 0;
                c_out = 0;

                if (!flags_in.n) begin
                    if (flags_in.h || a[3:0] > 4'h9) adj = adj + 8'h06;
                    if (flags_in.c || a > 8'h99) begin adj = adj + 8'h60; c_out = 1; end
                end else begin
                    if (flags_in.h) adj = adj - 8'h06;
                    if (flags_in.c) begin adj = adj - 8'h60; c_out = 1; end
                end

                result = a + adj;
                flags.z = (result == 0);
                flags.n = flags_in.n;
                flags.h = 0;
                flags.c = c_out;
            end

            ALU_ACTION_RLC: begin
                result = {a[6:0], a[7]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[7];
            end

            ALU_ACTION_RRC: begin
                result = {a[0], a[7:1]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[0];
            end

            ALU_ACTION_RL: begin
                result = {a[6:0], flags_in.c};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[7];
            end

            ALU_ACTION_RR: begin
                result = {flags_in.c, a[7:1]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[0];
            end

            ALU_ACTION_SLA: begin
                result = {a[6:0], 1'b0};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[7];
            end

            ALU_ACTION_SRA: begin
                result = {a[7], a[7:1]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[0];
            end

            ALU_ACTION_SWAP: begin
                result = {a[3:0], a[7:4]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = 0;
            end

            ALU_ACTION_SRL: begin
                result = {1'b0, a[7:1]};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = a[0];
            end
                        
            ALU_ACTION_LD: begin
                result = a;
                flags = flags_in;
            end
        endcase

        case (z_mod)
            ALU_Z_MOD_CLEAR: flags.z = 0;
            ALU_Z_MOD_PRESERVE: flags.z = flags_in.z;
        endcase
    end

endmodule