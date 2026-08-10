import apu_types::*;

module apu_ch1(
    input logic clk,
    input logic rst,
    input logic enabled,
    input logic clear,
    input logic length_tick,
    input logic sweep_tick,
    input logic env_tick,
    input logic length_extra_window,
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
    logic length_expire;
    logic [3:0] volume;
    logic freq_tick;
    logic duty_digital;
    logic sweep_overflow;
    logic sweep_period_update;
    logic [10:0] sweep_period;
    logic sweep_negate_used;
    logic [10:0] period;
    logic [10:0] trigger_period;
    logic [13:0] reload;

    logic nrx2_write;
    logic nrx4_write;
    logic length_enable_rising;
    logic trigger_length_enable;

    assign dac_enabled = dac_enabled_nrx2(NR12);
    assign trigger = bus.cs && bus.wr && bus.addr == REG_NR14 && bus.data_wr[7];
    assign nrx2_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR12 && |bus.data_wr[7:3];
    assign nrx4_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR14;
    assign length_enable_rising = nrx4_write && bus.data_wr[6] && !NR14.length_enable;
    assign trigger_length_enable = trigger && enabled && bus.data_wr[6];
    assign period = {NR14.period_high, NR13};
    assign trigger_period = {bus.data_wr[2:0], NR13};
    assign reload = trigger ? pulse_period_reload(trigger_period) : pulse_period_reload(period);
    assign sample = digital_sample(active, duty_digital, volume);

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

    apu_length #(.WIDTH(6)) length_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .length_tick(length_tick),
        .length_enable(NR14.length_enable),
        .load(bus.cs && bus.wr && bus.addr == REG_NR11),
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
        .nrx2(NR12),
        .write(nrx2_write),
        .write_data(nrx2_t'(bus.data_wr)),
        .volume(volume)
    );

    apu_freq_timer #(.WIDTH(14)) freq_timer(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .enable(active),
        .trigger(trigger),
        .reload(reload),
        .tick(freq_tick)
    );

    apu_duty duty_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .tick(freq_tick),
        .trigger(trigger),
        .duty(NR11.duty),
        .digital(duty_digital)
    );

    apu_sweep sweep(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .sweep_tick(sweep_tick),
        .trigger(trigger),
        .nr10(NR10),
        .trigger_period(trigger_period),
        .overflow(sweep_overflow),
        .period_update(sweep_period_update),
        .period(sweep_period),
        .negate_used(sweep_negate_used)
    );

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
                        REG_NR10: begin
                            NR10 <= bus.data_wr;
                            if (NR10.negate && !bus.data_wr[3] && sweep_negate_used)
                                active <= 0;
                        end
                        REG_NR11: NR11 <= bus.data_wr;
                        REG_NR12: NR12 <= bus.data_wr;
                        REG_NR13: NR13 <= bus.data_wr;
                        REG_NR14: NR14 <= {1'b0, bus.data_wr[6:0]};
                        default: ;
                    endcase
                end
            end

            if (sweep_period_update) begin
                NR13 <= sweep_period[7:0];
                NR14.period_high <= sweep_period[10:8];
            end

            if (trigger)
                active <= dac_enabled;
            if (length_expire || sweep_overflow)
                active <= 0;
            if (!dac_enabled
                || (bus.cs && bus.wr && bus.addr == REG_NR12 && ~|bus.data_wr[7:3]))
                active <= 0;
        end
    end

endmodule
