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
        logic [1:0] unused_high;
        logic [1:0] volume;
        logic [3:0] unused_low;
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

    localparam logic [5:0] LENGTH_6BIT_MAX = 'd63;
    localparam logic [7:0] LENGTH_8BIT_MAX = 'd255;

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
endpackage
