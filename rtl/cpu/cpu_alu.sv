function automatic logic half_carry_add8(logic [7:0] a, logic [7:0] b, logic cin);
    return ((a[3:0] + b[3:0] + cin) > 4'hF);
endfunction

module cpu_alu(
    input alu_action_t action,
    input logic [7:0] a,
    input logic [7:0] b,
    input logic [2:0] bit_idx,
    input flags_t flags_in,
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

            ALU_ACTION_ADD: begin
                {flags.c, result} = {1'b0, a} + {1'b0, b};

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = half_carry_add8(a, b, 0);
            end

            ALU_ACTION_XOR: begin
                result = a ^ b;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = 0;
            end
            
            ALU_ACTION_LD: begin
                result = a;
                flags = flags_in;
            end
        endcase
    end

endmodule