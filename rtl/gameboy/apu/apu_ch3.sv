import apu_types::*;

module apu_ch3(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    input logic length_tick,
    input logic length_extra_window,
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
    logic length_expire;
    logic freq_tick;
    logic [4:0] wave_position;
    logic [10:0] period;
    logic [10:0] trigger_period;
    logic [12:0] reload;
    logic [3:0] wave_sample;
    logic [3:0] scaled_sample;
    logic signed [5:0] doubled_sample;
    logic signed [4:0] centered_sample;

    logic nrx4_write;
    logic length_enable_rising;
    logic trigger_length_enable;

    assign wave_sel = bus.addr inside {[WAVE_RAM_START:WAVE_RAM_END]};
    assign dac_enabled = NR30.dac_enable;
    assign trigger = bus.cs && bus.wr && bus.addr == REG_NR34 && bus.data_wr[7];
    assign nrx4_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR34;
    assign length_enable_rising = nrx4_write && bus.data_wr[6] && !NR34.length_enable;
    assign trigger_length_enable = trigger && enabled && bus.data_wr[6];
    assign period = {NR34.period_high, NR33};
    assign trigger_period = {bus.data_wr[2:0], NR33};
    assign reload = trigger ? wave_period_reload(trigger_period) : wave_period_reload(period);
    assign wave_sample = wave_position[0]
        ? wave_ram[wave_position[4:1]][3:0]
        : wave_ram[wave_position[4:1]][7:4];

    always_comb begin
        case (NR32.volume)
            'd0: scaled_sample = '0;
            'd1: scaled_sample = wave_sample;
            'd2: scaled_sample = wave_sample >> 1;
            'd3: scaled_sample = wave_sample >> 2;
        endcase
    end

    assign doubled_sample = $signed({1'b0, scaled_sample, 1'b0}) - 6'sd15;
    assign centered_sample = doubled_sample[4:0];
    assign sample = active ? centered_sample : '0;

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

    apu_length #(.WIDTH(8)) length_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .length_tick(length_tick),
        .length_enable(NR34.length_enable),
        .load(bus.cs && bus.wr && bus.addr == REG_NR31),
        .load_value(9'd256 - {1'b0, bus.data_wr}),
        .trigger(trigger),
        .extra_window(length_extra_window),
        .enable_rising(length_enable_rising),
        .trigger_length_enable(trigger_length_enable),
        .expire(length_expire)
    );

    apu_freq_timer #(.WIDTH(13)) freq_timer(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .enable(active),
        .trigger(trigger),
        .reload(reload),
        .tick(freq_tick)
    );

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
            wave_position <= '0;
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

            if (freq_tick)
                wave_position <= wave_position + 'd1;

            if (trigger) begin
                active <= dac_enabled;
                wave_position <= '0;
            end
            if (length_expire)
                active <= 0;
            if (!dac_enabled
                || (bus.cs && bus.wr && bus.addr == REG_NR30 && !bus.data_wr[7]))
                active <= 0;
        end
    end

endmodule
