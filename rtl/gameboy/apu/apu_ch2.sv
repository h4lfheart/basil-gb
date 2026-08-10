import apu_types::*;

module apu_ch2(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    bus.child_port bus,
    output logic active,
    output channel_sample_t sample
);
    nrx1_t NR21;
    nrx2_t NR22;
    logic [7:0] NR23;
    nrx4_t NR24;

    logic dac_enabled;
    logic trigger;

    assign dac_enabled = |{NR22.volume, NR22.envelope_dir};
    assign trigger = bus.cs && bus.wr && (bus.addr == REG_NR24) && bus.data_wr[7];
    assign sample = '0;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd)
            case (bus.addr)
                REG_NR21: bus.data_rd = {NR21.duty, 6'h3F};
                REG_NR22: bus.data_rd = NR22;
                REG_NR24: bus.data_rd = {1'b1, NR24.length_enable, 6'h3F};
                default: ;
            endcase
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            NR21 <= '0;
            NR22 <= '0;
            NR23 <= '0;
            NR24 <= '0;
            active <= 0;
        end else begin
            if (bus.cs && bus.wr) begin
                if (!enabled) begin
                    if (bus.addr == REG_NR21)
                        NR21.length <= bus.data_wr[5:0];
                end else begin
                    case (bus.addr)
                        REG_NR21: NR21 <= bus.data_wr;
                        REG_NR22: NR22 <= bus.data_wr;
                        REG_NR23: NR23 <= bus.data_wr;
                        REG_NR24: NR24 <= {1'b0, bus.data_wr[6:0]};
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
