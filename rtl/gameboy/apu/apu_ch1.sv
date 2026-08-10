import apu_types::*;

module apu_ch1(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    bus.child_port bus,
    output logic active,
    output channel_sample_t sample
);
    nr10_t NR10;
    nrx1_t NR11;
    nrx2_t NR12;
    logic [7:0] NR13;
    nrx4_t NR14;

    logic dac_enabled;
    logic trigger;

    assign dac_enabled = |{NR12.volume, NR12.envelope_dir};
    assign trigger = bus.cs && bus.wr && (bus.addr == REG_NR14) && bus.data_wr[7];
    assign sample = '0;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_NR10: bus.data_rd = {1'b1, NR10.pace, NR10.negate, NR10.shift};
                REG_NR11: bus.data_rd = {NR11.duty, 6'h3F};
                REG_NR12: bus.data_rd = NR12;
                REG_NR14: bus.data_rd = {1'b1, NR14.length_enable, 6'h3F};
                default: ;
            endcase
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            NR10 <= '0;
            NR11 <= '0;
            NR12 <= '0;
            NR13 <= '0;
            NR14 <= '0;
            active <= 0;
        end else begin
            if (bus.cs && bus.wr) begin
                if (!enabled) begin
                    if (bus.addr == REG_NR11)
                        NR11.length <= bus.data_wr[5:0];
                end else begin
                    case (bus.addr)
                        REG_NR10: NR10 <= bus.data_wr;
                        REG_NR11: NR11 <= bus.data_wr;
                        REG_NR12: NR12 <= bus.data_wr;
                        REG_NR13: NR13 <= bus.data_wr;
                        REG_NR14: NR14 <= {1'b0, bus.data_wr[6:0]};
                        default: ;
                    endcase
                end
            end

            if (trigger && dac_enabled)
                active <= 1;
            if (!dac_enabled)
                active <= 0;
        end
    end

endmodule
