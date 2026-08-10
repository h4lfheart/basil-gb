package apu_types;
    typedef logic signed [4:0] channel_sample_t;
    typedef logic signed [9:0] mix_sample_t;

    typedef struct packed {
        logic unused;
        logic [2:0] pace;
        logic negate;
        logic [2:0] shift;
    } nr10_t;

    typedef struct packed {
        logic [1:0] duty;
        logic [5:0] length;
    } nrx1_t;

    typedef struct packed {
        logic [3:0] volume;
        logic envelope_dir;
        logic [2:0] env_pace;
    } nrx2_t;

    typedef struct packed {
        logic trigger;
        logic length_enable;
        logic [2:0] unused;
        logic [2:0] period_high;
    } nrx4_t;

    typedef struct packed {
        logic dac_enable;
        logic [6:0] unused;
    } nr30_t;

    typedef struct packed {
        logic unused_high;
        logic [1:0] volume;
        logic [4:0] unused_low;
    } nr32_t;

    typedef struct packed {
        logic [3:0] clock_shift;
        logic lfsr_width;
        logic [2:0] clock_divider;
    } nr43_t;

    typedef struct packed {
        logic vin_left;
        logic [2:0] left_volume;
        logic vin_right;
        logic [2:0] right_volume;
    } nr50_t;

    typedef struct packed {
        logic ch4_left;
        logic ch3_left;
        logic ch2_left;
        logic ch1_left;
        logic ch4_right;
        logic ch3_right;
        logic ch2_right;
        logic ch1_right;
    } nr51_t;

    localparam logic [15:0] APU_IO_START = 'hFF10;
    localparam logic [15:0] APU_IO_END = 'hFF3F;

    localparam logic [15:0] REG_NR10 = 'hFF10;
    localparam logic [15:0] REG_NR11 = 'hFF11;
    localparam logic [15:0] REG_NR12 = 'hFF12;
    localparam logic [15:0] REG_NR13 = 'hFF13;
    localparam logic [15:0] REG_NR14 = 'hFF14;

    localparam logic [15:0] REG_NR21 = 'hFF16;
    localparam logic [15:0] REG_NR22 = 'hFF17;
    localparam logic [15:0] REG_NR23 = 'hFF18;
    localparam logic [15:0] REG_NR24 = 'hFF19;

    localparam logic [15:0] REG_NR30 = 'hFF1A;
    localparam logic [15:0] REG_NR31 = 'hFF1B;
    localparam logic [15:0] REG_NR32 = 'hFF1C;
    localparam logic [15:0] REG_NR33 = 'hFF1D;
    localparam logic [15:0] REG_NR34 = 'hFF1E;

    localparam logic [15:0] REG_NR41 = 'hFF20;
    localparam logic [15:0] REG_NR42 = 'hFF21;
    localparam logic [15:0] REG_NR43 = 'hFF22;
    localparam logic [15:0] REG_NR44 = 'hFF23;

    localparam logic [15:0] REG_NR50 = 'hFF24;
    localparam logic [15:0] REG_NR51 = 'hFF25;
    localparam logic [15:0] REG_NR52 = 'hFF26;

    localparam logic [15:0] WAVE_RAM_START = 'hFF30;
    localparam logic [15:0] WAVE_RAM_END = 'hFF3F;

    function automatic logic is_apu_reg(input logic [15:0] addr);
        return addr inside {[APU_IO_START:APU_IO_END]};
    endfunction

    function automatic logic is_ch1_reg(input logic [15:0] addr);
        return addr inside {[REG_NR10:REG_NR14]};
    endfunction

    function automatic logic is_ch2_reg(input logic [15:0] addr);
        return addr inside {[REG_NR21:REG_NR24]};
    endfunction

    function automatic logic is_ch3_reg(input logic [15:0] addr);
        return addr inside {[REG_NR30:REG_NR34], [WAVE_RAM_START:WAVE_RAM_END]};
    endfunction

    function automatic logic is_ch4_reg(input logic [15:0] addr);
        return addr inside {[REG_NR41:REG_NR44]};
    endfunction

    function automatic logic dac_enabled_nrx2(input nrx2_t nrx2);
        return |{nrx2.volume, nrx2.envelope_dir};
    endfunction

    function automatic logic [13:0] pulse_period_reload(input logic [10:0] period);
        return (14'd2048 - {3'b0, period}) << 2;
    endfunction

    function automatic logic [12:0] wave_period_reload(input logic [10:0] period);
        return (13'd2048 - {2'b0, period}) << 1;
    endfunction

    function automatic logic [21:0] noise_period_reload(
        input logic [2:0] divider,
        input logic [3:0] shift
    );
        logic [21:0] divisor;
        divisor = divider == 0 ? 22'd8 : {15'd0, divider, 4'b0000};
        return divisor << shift;
    endfunction

    function automatic channel_sample_t digital_sample(
        input logic active,
        input logic digital,
        input logic [3:0] volume
    );
        if (!active)
            return '0;
        return digital ? $signed({1'b0, volume}) : -$signed({1'b0, volume});
    endfunction
endpackage
