module rom_loader #(
    parameter logic [23:0] FLASH_OFFSET = 'h20_0000,
    parameter logic [23:0] ROM_BYTES = 'h20_0000
) (
    input logic clk,
    input logic rst_n,
    sdram_bus.client sdram,
    spi_flash_bus.controller flash,
    output logic [7:0] header_cart_type,
    output logic ready
);
    typedef enum logic [1:0] {
        WAIT_SDRAM,
        START_SPI,
        STREAM,
        DONE
    } state_t;

    state_t state;
    logic [22:0] wr_addr;
    logic spi_start;
    logic spi_busy;
    logic spi_byte_valid;
    logic spi_done;
    logic [7:0] spi_byte;
    logic [7:0] cart_type;
    logic wr_pending;
    logic wr_issued;
    logic [7:0] wr_data;
    logic spi_finished;
    logic [15:0] refresh_div;

    spi_flash_read u_spi (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi_start),
        .pause(wr_pending),
        .addr(FLASH_OFFSET),
        .length(ROM_BYTES),
        .busy(spi_busy),
        .byte_valid(spi_byte_valid),
        .byte_data(spi_byte),
        .done(spi_done),
        .flash(flash)
    );

    assign header_cart_type = cart_type;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT_SDRAM;
            sdram.rd <= 1'b0;
            sdram.wr <= 1'b0;
            sdram.refresh <= 1'b0;
            sdram.addr <= '0;
            sdram.din <= '0;
            spi_start <= 1'b0;
            wr_addr <= '0;
            ready <= 1'b0;
            wr_pending <= 1'b0;
            wr_issued <= 1'b0;
            wr_data <= '0;
            spi_finished <= 1'b0;
            refresh_div <= '0;
            cart_type <= 8'h03;
        end else begin
            sdram.rd <= 1'b0;
            sdram.wr <= 1'b0;
            sdram.refresh <= 1'b0;
            spi_start <= 1'b0;

            if (spi_done)
                spi_finished <= 1'b1;

            refresh_div <= refresh_div + 1'b1;
            if (refresh_div >= 'd800) begin
                refresh_div <= '0;
                if (!sdram.busy && !wr_pending && state != WAIT_SDRAM)
                    sdram.refresh <= 1'b1;
            end

            unique case (state)
                WAIT_SDRAM: begin
                    if (!sdram.busy) begin
                        spi_start <= 1'b1;
                        wr_addr <= '0;
                        state <= START_SPI;
                    end
                end

                START_SPI: begin
                    if (spi_busy)
                        state <= STREAM;
                end

                STREAM: begin
                    if (spi_byte_valid) begin
                        wr_data <= spi_byte;
                        wr_pending <= 1'b1;
                        if (wr_addr == 'h0147)
                            cart_type <= spi_byte;
                    end

                    if (wr_pending && !wr_issued && !sdram.busy
                            && !sdram.wr && !sdram.refresh) begin
                        sdram.wr <= 1'b1;
                        sdram.addr <= wr_addr;
                        sdram.din <= wr_data;
                        wr_issued <= 1'b1;
                    end

                    if (wr_issued && !sdram.busy && !sdram.wr) begin
                        wr_pending <= 1'b0;
                        wr_issued <= 1'b0;
                        wr_addr <= wr_addr + 1'b1;
                    end

                    if (spi_finished && !wr_pending)
                        state <= DONE;
                end

                DONE: begin
                    ready <= 1'b1;
                end

                default: state <= WAIT_SDRAM;
            endcase
        end
    end
endmodule
