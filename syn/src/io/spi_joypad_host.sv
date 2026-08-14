module spi_joypad_host #(
    parameter int CLK_HZ = 27_000_000,
    parameter int SCLK_HZ = 1_000_000,
    parameter int POLL_HZ = 1_000
) (
    input logic clk,
    input logic rst,
    output logic sclk,
    output logic cs_n,
    output logic mosi,
    input logic miso,
    output joypad_buttons_t buttons
);
    localparam int HALF_PERIOD = CLK_HZ / (SCLK_HZ * 2);
    localparam int POLL_CLKS = CLK_HZ / POLL_HZ;

    typedef enum logic [1:0] {
        ST_WAIT,
        ST_ASSERT,
        ST_SHIFT,
        ST_DONE
    } state_t;

    state_t state;
    logic [15:0] div;
    logic [15:0] poll_cnt;
    logic [7:0] shreg;
    logic [2:0] bit_cnt;
    logic sclk_hi;
    joypad_buttons_t buttons_r;
    logic miso_meta;
    logic miso_sync;

    assign buttons = buttons_r;
    assign mosi = 1'b0;

    always_ff @(posedge clk) begin
        miso_meta <= miso;
        miso_sync <= miso_meta;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_WAIT;
            div <= '0;
            poll_cnt <= '0;
            sclk <= 1'b0;
            cs_n <= 1'b1;
            shreg <= '0;
            bit_cnt <= '0;
            sclk_hi <= 1'b0;
            buttons_r <= '1;
        end else begin
            unique case (state)
                ST_WAIT: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    div <= '0;
                    sclk_hi <= 1'b0;
                    if (poll_cnt >= POLL_CLKS[15:0] - 16'd1) begin
                        poll_cnt <= '0;
                        cs_n <= 1'b0;
                        state <= ST_ASSERT;
                    end else begin
                        poll_cnt <= poll_cnt + 16'd1;
                    end
                end

                ST_ASSERT: begin
                    if (div >= HALF_PERIOD[15:0] - 16'd1) begin
                        div <= '0;
                        bit_cnt <= 3'd7;
                        shreg <= '0;
                        sclk_hi <= 1'b0;
                        state <= ST_SHIFT;
                    end else begin
                        div <= div + 16'd1;
                    end
                end

                ST_SHIFT: begin
                    if (div >= HALF_PERIOD[15:0] - 16'd1) begin
                        div <= '0;
                        if (!sclk_hi) begin
                            sclk <= 1'b1;
                            shreg <= {shreg[6:0], miso_sync};
                            sclk_hi <= 1'b1;
                        end else begin
                            sclk <= 1'b0;
                            sclk_hi <= 1'b0;
                            if (bit_cnt == 3'd0)
                                state <= ST_DONE;
                            else
                                bit_cnt <= bit_cnt - 3'd1;
                        end
                    end else begin
                        div <= div + 16'd1;
                    end
                end

                ST_DONE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    buttons_r <= joypad_buttons_t'(~shreg);
                    poll_cnt <= '0;
                    state <= ST_WAIT;
                end

                default: state <= ST_WAIT;
            endcase
        end
    end
endmodule
