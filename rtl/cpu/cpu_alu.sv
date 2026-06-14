module cpu_alu(
    input alu_action_t action,
    input logic [7:0] a,
    input logic [7:0] b,
    input flags_t flags_in,
    output logic [7:0] result,
    output flags_t flags
);

    always_comb begin
        result = 0;
        flags = 0;

        case (action)
            ALU_ACTION_XOR: begin
                result = a ^ b;

                flags.z = (result == 0);
                flags.n = 0;
                flags.h = 0;
                flags.c = 0;
            end
        endcase
    end

endmodule