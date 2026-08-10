import apu_types::*;

module apu_ch4(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    bus.child_port bus,
    output logic active,
    output channel_sample_t sample
);
    logic [5:0] NR41;
    nrx2_t NR42;
    nr43_t NR43;
    nrx4_t NR44;

    logic dac_enabled;
    logic trigger;

    assign dac_enabled = |{NR42.volume, NR42.envelope_dir};
    assign trigger = bus.cs && bus.wr && (bus.addr == REG_NR44) && bus.data_wr[7];
    assign sample = '0;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_NR42: bus.data_rd = NR42;
                REG_NR43: bus.data_rd = NR43;
                REG_NR44: bus.data_rd = {1'b1, NR44.length_enable, 6'h3F};
                default: ;
            endcase
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            NR41 <= '0;
            NR42 <= '0;
            NR43 <= '0;
            NR44 <= '0;
            active <= 0;
        end else begin
            if (bus.cs && bus.wr) begin
                if (!enabled) begin
                    if (bus.addr == REG_NR41)
                        NR41 <= bus.data_wr[5:0];
                end else begin
                    case (bus.addr)
                        REG_NR41: NR41 <= bus.data_wr[5:0];
                        REG_NR42: NR42 <= bus.data_wr;
                        REG_NR43: NR43 <= bus.data_wr;
                        REG_NR44: NR44 <= {1'b0, bus.data_wr[6:0]};
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
