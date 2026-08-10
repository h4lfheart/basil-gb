import apu_types::*;

module apu_ch4(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    input logic length_tick,
    input logic env_tick,
    input logic length_extra_window,
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
    logic length_expire;
    logic [3:0] volume;
    logic freq_tick;
    logic noise_digital;
    logic [21:0] reload;

    logic nrx2_write;
    logic nrx4_write;
    logic length_enable_rising;
    logic trigger_length_enable;

    assign dac_enabled = dac_enabled_nrx2(NR42);
    assign trigger = bus.cs && bus.wr && bus.addr == REG_NR44 && bus.data_wr[7];
    assign nrx2_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR42 && |bus.data_wr[7:3];
    assign nrx4_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR44;
    assign length_enable_rising = nrx4_write && bus.data_wr[6] && !NR44.length_enable;
    assign trigger_length_enable = trigger && enabled && bus.data_wr[6];
    assign reload = noise_period_reload(NR43.clock_divider, NR43.clock_shift);
    assign sample = digital_sample(active, noise_digital, volume);

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

    apu_length #(.WIDTH(6)) length_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .length_tick(length_tick),
        .length_enable(NR44.length_enable),
        .load(bus.cs && bus.wr && bus.addr == REG_NR41),
        .load_value(7'd64 - {1'b0, bus.data_wr[5:0]}),
        .trigger(trigger),
        .extra_window(length_extra_window),
        .enable_rising(length_enable_rising),
        .trigger_length_enable(trigger_length_enable),
        .expire(length_expire)
    );

    apu_envelope envelope(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .env_tick(env_tick),
        .active(active),
        .trigger(trigger),
        .nrx2(NR42),
        .write(nrx2_write),
        .write_data(nrx2_t'(bus.data_wr)),
        .volume(volume)
    );

    apu_freq_timer #(.WIDTH(22)) freq_timer(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .enable(active),
        .trigger(trigger),
        .reload(reload),
        .tick(freq_tick)
    );

    apu_lfsr lfsr_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .tick(freq_tick),
        .trigger(trigger),
        .width_mode(NR43.lfsr_width),
        .digital(noise_digital)
    );

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

            if (trigger)
                active <= dac_enabled;
            if (length_expire)
                active <= 0;
            if (!dac_enabled
                || (bus.cs && bus.wr && bus.addr == REG_NR42 && ~|bus.data_wr[7:3]))
                active <= 0;
        end
    end

endmodule
