import apu_types::*;

module apu_ch3(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    bus.child_port bus,
    output logic active,
    output channel_sample_t sample
);
    nr30_t NR30;
    logic [7:0] NR31;
    nr32_t NR32;
    logic [7:0] NR33;
    nrx4_t NR34;

    logic [7:0] wave_ram [0:15];

    logic wave_sel;
    logic dac_enabled;
    logic trigger;

    assign wave_sel = bus.addr inside {[WAVE_RAM_START:WAVE_RAM_END]};
    assign dac_enabled = NR30.dac_enable;
    assign trigger = bus.cs && bus.wr && (bus.addr == REG_NR34) && bus.data_wr[7];
    assign sample = '0;

    always_comb begin
        bus.data_rd = 'hFF;
        if (bus.cs && bus.rd) begin
            if (wave_sel)
                bus.data_rd = wave_ram[bus.addr[3:0]];
            else
                case (bus.addr)
                    REG_NR30: bus.data_rd = {NR30.dac_enable, 7'h7F};
                    REG_NR32: bus.data_rd = {1'b1, NR32.volume, 5'h1F};
                    REG_NR34: bus.data_rd = {1'b1, NR34.length_enable, 6'h3F};
                    default: ;
                endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 16; i++)
                wave_ram[i] <= '0;
        end else if (bus.cs && bus.wr && wave_sel) begin
            wave_ram[bus.addr[3:0]] <= bus.data_wr;
        end
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            NR30 <= '0;
            NR31 <= '0;
            NR32 <= '0;
            NR33 <= '0;
            NR34 <= '0;
            active <= 0;
        end else begin
            if (bus.cs && bus.wr && !wave_sel) begin
                if (!enabled) begin
                    if (bus.addr == REG_NR31)
                        NR31 <= bus.data_wr;
                end else begin
                    case (bus.addr)
                        REG_NR30: NR30 <= bus.data_wr;
                        REG_NR31: NR31 <= bus.data_wr;
                        REG_NR32: NR32 <= bus.data_wr;
                        REG_NR33: NR33 <= bus.data_wr;
                        REG_NR34: NR34 <= {1'b0, bus.data_wr[6:0]};
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
