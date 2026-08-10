import apu_types::*;

module apu_ch2(
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
    nrx1_t NR21;
    nrx2_t NR22;
    logic [7:0] NR23;
    nrx4_t NR24;

    logic dac_enabled;
    logic trigger;
    logic length_expire;
    logic [3:0] volume;
    logic freq_tick;
    logic duty_digital;
    logic [10:0] period;
    logic [10:0] trigger_period;
    logic [13:0] reload;

    logic nrx2_write;
    logic nrx4_write;
    logic length_enable_rising;
    logic trigger_length_enable;

    assign dac_enabled = dac_enabled_nrx2(NR22);
    assign trigger = bus.cs && bus.wr && bus.addr == REG_NR24 && bus.data_wr[7];
    assign nrx2_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR22 && |bus.data_wr[7:3];
    assign nrx4_write = enabled && bus.cs && bus.wr && bus.addr == REG_NR24;
    assign length_enable_rising = nrx4_write && bus.data_wr[6] && !NR24.length_enable;
    assign trigger_length_enable = trigger && enabled && bus.data_wr[6];
    assign period = {NR24.period_high, NR23};
    assign trigger_period = {bus.data_wr[2:0], NR23};
    assign reload = trigger ? pulse_period_reload(trigger_period) : pulse_period_reload(period);
    assign sample = digital_sample(active, duty_digital, volume);

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

    apu_length #(.WIDTH(6)) length_unit(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .length_tick(length_tick),
        .length_enable(NR24.length_enable),
        .load(bus.cs && bus.wr && bus.addr == REG_NR21),
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
        .nrx2(NR22),
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
        .duty(NR21.duty),
        .digital(duty_digital)
    );

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

            if (trigger)
                active <= dac_enabled;
            if (length_expire)
                active <= 0;
            if (!dac_enabled
                || (bus.cs && bus.wr && bus.addr == REG_NR22 && ~|bus.data_wr[7:3]))
                active <= 0;
        end
    end

endmodule
