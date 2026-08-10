module spi_flash_read (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic pause,
    input logic [23:0] addr,
    input logic [23:0] length,
    output logic busy,
    output logic byte_valid,
    output logic [7:0] byte_data,
    output logic done,
    spi_flash_bus.controller flash
);
    typedef enum logic [2:0] {
        IDLE,
        CMD,
        ADDR,
        DATA,
        DONE
    } state_t;

    state_t state;
    logic [1:0] div;
    logic tick;
    logic [7:0] shreg;
    logic [2:0] bit_cnt;
    logic [23:0] addr_sh;
    logic [1:0] addr_byte;
    logic [23:0] remain;

    assign tick = (div == 'd3);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            div <= '0;
            flash.cs_n <= 1'b1;
            flash.clk <= 1'b0;
            flash.mosi <= 1'b0;
            busy <= 1'b0;
            byte_valid <= 1'b0;
            done <= 1'b0;
            bit_cnt <= '0;
            remain <= '0;
        end else begin
            byte_valid <= 1'b0;
            done <= 1'b0;

            if (!(state == DATA && pause))
                div <= div + 1'b1;

            unique case (state)
                IDLE: begin
                    flash.cs_n <= 1'b1;
                    flash.clk <= 1'b0;
                    busy <= 1'b0;

                    if (start) begin
                        busy <= 1'b1;
                        flash.cs_n <= 1'b0;
                        shreg <= 8'h03;
                        bit_cnt <= 'd7;
                        addr_sh <= addr;
                        addr_byte <= '0;
                        remain <= length;
                        div <= '0;
                        state <= CMD;
                    end
                end

                CMD: if (tick) begin
                    flash.clk <= ~flash.clk;
                    if (!flash.clk) begin
                        flash.mosi <= shreg[7];
                        shreg <= {shreg[6:0], 1'b0};
                    end else if (bit_cnt == '0) begin
                        shreg <= addr_sh[23:16];
                        bit_cnt <= 'd7;
                        state <= ADDR;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ADDR: if (tick) begin
                    flash.clk <= ~flash.clk;
                    if (!flash.clk) begin
                        flash.mosi <= shreg[7];
                        shreg <= {shreg[6:0], 1'b0};
                    end else if (bit_cnt == '0) begin
                        if (addr_byte == 'd2) begin
                            bit_cnt <= 'd7;
                            shreg <= '0;
                            state <= DATA;
                        end else begin
                            addr_byte <= addr_byte + 1'b1;
                            bit_cnt <= 'd7;
                            unique case (addr_byte)
                                'd0: shreg <= addr_sh[15:8];
                                default: shreg <= addr_sh[7:0];
                            endcase
                        end
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                DATA: if (tick) begin
                    flash.clk <= ~flash.clk;
                    if (!flash.clk) begin
                        flash.mosi <= 1'b0;
                    end else begin
                        shreg <= {shreg[6:0], flash.miso};
                        if (bit_cnt == '0) begin
                            byte_data <= {shreg[6:0], flash.miso};
                            byte_valid <= 1'b1;
                            bit_cnt <= 'd7;
                            if (remain <= 'd1)
                                state <= DONE;
                            else
                                remain <= remain - 1'b1;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                DONE: begin
                    flash.cs_n <= 1'b1;
                    flash.clk <= 1'b0;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
