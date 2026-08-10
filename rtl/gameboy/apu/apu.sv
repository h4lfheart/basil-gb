import apu_types::*;

`define APU_CONNECT_CH(child, sel) \
    always_comb begin \
        child.addr = reg_bus.addr; \
        child.data_wr = reg_bus.data_wr; \
        child.rd = reg_bus.rd; \
        child.wr = reg_bus.wr; \
        child.cs = reg_bus.cs && (sel); \
    end

module apu(
    input logic clk,
    input logic rst,
    bus.child_port reg_bus,
    input logic [15:0] div,
    output mix_sample_t sample_left,
    output mix_sample_t sample_right
);
    logic enabled;

    nr50_t NR50;
    nr51_t NR51;

    logic ch1_active;
    logic ch2_active;
    logic ch3_active;
    logic ch4_active;

    channel_sample_t ch1_sample;
    channel_sample_t ch2_sample;
    channel_sample_t ch3_sample;
    channel_sample_t ch4_sample;

    logic signed [6:0] mix_left;
    logic signed [6:0] mix_right;

    logic ch1_sel;
    logic ch2_sel;
    logic ch3_sel;
    logic ch4_sel;

    logic power_off;

    logic div_apu_falling;
    logic [2:0] frame_step;

    bus ch1_bus();
    bus ch2_bus();
    bus ch3_bus();
    bus ch4_bus();

    assign ch1_sel = is_ch1_reg(reg_bus.addr);
    assign ch2_sel = is_ch2_reg(reg_bus.addr);
    assign ch3_sel = is_ch3_reg(reg_bus.addr);
    assign ch4_sel = is_ch4_reg(reg_bus.addr);

    assign power_off = reg_bus.cs && reg_bus.wr && (reg_bus.addr == REG_NR52)
        && !reg_bus.data_wr[7] && enabled;

    edge_detect div_apu_edge(
        .clk(clk),
        .rst(rst),
        .signal(div[12]),
        .rising(),
        .falling(div_apu_falling)
    );

    always_ff @(posedge clk) begin
        if (rst)
            frame_step <= 0;
        else if (div_apu_falling)
            frame_step <= frame_step + 1'b1;
    end

    
    logic length_tick;
    logic sweep_tick;
    logic env_tick;
    assign length_tick = div_apu_falling && !frame_step[0];
    assign sweep_tick = div_apu_falling && (frame_step[1:0] == 2'b10);
    assign env_tick = div_apu_falling && (frame_step == 3'd7);

    `APU_CONNECT_CH(ch1_bus, ch1_sel)
    `APU_CONNECT_CH(ch2_bus, ch2_sel)
    `APU_CONNECT_CH(ch3_bus, ch3_sel)
    `APU_CONNECT_CH(ch4_bus, ch4_sel)

    apu_ch1 ch1(
        .clk(clk),
        .rst(rst),
        .enabled(enabled),
        .clear(power_off),
        .bus(ch1_bus),
        .active(ch1_active),
        .sample(ch1_sample)
    );

    apu_ch2 ch2(
        .clk(clk),
        .rst(rst),
        .enabled(enabled),
        .clear(power_off),
        .bus(ch2_bus),
        .active(ch2_active),
        .sample(ch2_sample)
    );

    apu_ch3 ch3(
        .clk(clk),
        .rst(rst),
        .enabled(enabled),
        .clear(power_off),
        .bus(ch3_bus),
        .active(ch3_active),
        .sample(ch3_sample)
    );

    apu_ch4 ch4(
        .clk(clk),
        .rst(rst),
        .enabled(enabled),
        .clear(power_off),
        .bus(ch4_bus),
        .active(ch4_active),
        .sample(ch4_sample)
    );

    always_comb begin
        mix_left = '0;
        mix_right = '0;

        if (NR51.ch1_left) mix_left += ch1_sample;
        if (NR51.ch2_left) mix_left += ch2_sample;
        if (NR51.ch3_left) mix_left += ch3_sample;
        if (NR51.ch4_left) mix_left += ch4_sample;

        if (NR51.ch1_right) mix_right += ch1_sample;
        if (NR51.ch2_right) mix_right += ch2_sample;
        if (NR51.ch3_right) mix_right += ch3_sample;
        if (NR51.ch4_right) mix_right += ch4_sample;

        sample_left = enabled ? mix_left * $signed({1'b0, NR50.left_volume}) : '0;
        sample_right = enabled ? mix_right * $signed({1'b0, NR50.right_volume}) : '0;
    end

    always_comb begin
        reg_bus.data_rd = 'hFF;
        if (reg_bus.cs && reg_bus.rd) begin
            if (ch1_sel) reg_bus.data_rd = ch1_bus.data_rd;
            else if (ch2_sel) reg_bus.data_rd = ch2_bus.data_rd;
            else if (ch3_sel) reg_bus.data_rd = ch3_bus.data_rd;
            else if (ch4_sel) reg_bus.data_rd = ch4_bus.data_rd;
            else
                case (reg_bus.addr)
                    REG_NR50: reg_bus.data_rd = NR50;
                    REG_NR51: reg_bus.data_rd = NR51;
                    REG_NR52: reg_bus.data_rd =
                        {enabled, 3'b111, ch4_active, ch3_active, ch2_active, ch1_active};
                    default: ;
                endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst || power_off) begin
            enabled <= 0;
            NR50 <= '0;
            NR51 <= '0;
        end else if (reg_bus.cs && reg_bus.wr) begin
            case (reg_bus.addr)
                REG_NR50: if (enabled) NR50 <= reg_bus.data_wr;
                REG_NR51: if (enabled) NR51 <= reg_bus.data_wr;
                REG_NR52: enabled <= reg_bus.data_wr[7];
                default: ;
            endcase
        end
    end

endmodule
