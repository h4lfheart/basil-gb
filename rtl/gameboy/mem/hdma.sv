import mem_types::*;

module hdma(
    input logic clk,
    input logic rst,
    input logic hblank_pulse,
    input logic lcd_on,
    input logic cpu_stalled,
    bus.child_port reg_bus,
    bus.parent_port mem_bus,
    output logic active,
    output logic cpu_stall,
    output logic [15:0] src_addr
);
    localparam logic [4:0] BYTES_PER_BLOCK = 'd16;

    logic [15:0] source;
    logic [15:0] dest;
    logic [6:0] length;
    logic busy;
    logic hblank_mode;
    logic transferring;
    logic pending;
    logic read_phase;
    logic [3:0] byte_index;
    logic [7:0] sample;

    assign active = busy;
    assign cpu_stall = transferring || pending;
    assign src_addr = source;

    function automatic logic [15:0] mask_source(logic [15:0] addr);
        return {addr[15:4], 4'b0000};
    endfunction

    function automatic logic [15:0] mask_dest(logic [15:0] addr);
        return VRAM_START | 16'({addr[12:4], 4'b0000});
    endfunction

    function automatic logic [15:0] next_dest(logic [15:0] addr);
        return VRAM_START | 16'(13'(addr[12:0] + 'd1));
    endfunction

    always_comb begin
        reg_bus.data_rd = 'hFF;
        if (reg_bus.cs && reg_bus.rd && reg_bus.addr == REG_HDMA5)
            reg_bus.data_rd = busy ? {1'b0, length} : 'hFF;
    end

    always_comb begin
        mem_bus.addr = '0;
        mem_bus.data_wr = '0;
        mem_bus.rd = 0;
        mem_bus.wr = 0;
        mem_bus.cs = 0;

        if (transferring) begin
            if (read_phase) begin
                mem_bus.addr = source;
                mem_bus.rd = 1;
                mem_bus.cs = 1;
            end else begin
                mem_bus.addr = dest;
                mem_bus.data_wr = sample;
                mem_bus.wr = 1;
                mem_bus.cs = 1;
            end
        end
    end

    logic hdma5_write;
    logic hblank_trigger;
    logic begin_block;

    assign hdma5_write = reg_bus.cs && reg_bus.wr && (reg_bus.addr == REG_HDMA5);
    assign hblank_trigger = busy && hblank_mode && !transferring && !pending
        && (hblank_pulse || !lcd_on);
    assign begin_block = pending && cpu_stalled;

    always_ff @(posedge clk) begin
        if (rst) begin
            source <= '0;
            dest <= VRAM_START;
            length <= 'h7F;
            busy <= 0;
            hblank_mode <= 0;
            transferring <= 0;
            pending <= 0;
            read_phase <= 1;
            byte_index <= '0;
            sample <= '0;
        end else begin
            if (reg_bus.cs && reg_bus.wr) begin
                unique case (reg_bus.addr)
                    REG_HDMA1: source[15:8] <= reg_bus.data_wr;
                    REG_HDMA2: source[7:0] <= {reg_bus.data_wr[7:4], 4'b0000};
                    REG_HDMA3: dest <= mask_dest({reg_bus.data_wr, dest[7:0]});
                    REG_HDMA4: dest <= mask_dest({dest[15:8], reg_bus.data_wr});
                endcase
            end

            if (hdma5_write && busy && hblank_mode && !reg_bus.data_wr[7]) begin
                busy <= 0;
                hblank_mode <= 0;
                transferring <= 0;
                pending <= 0;
                read_phase <= 1;
                byte_index <= '0;
            end else if (hdma5_write && !busy) begin
                length <= reg_bus.data_wr[6:0];
                source <= mask_source(source);
                dest <= mask_dest(dest);
                busy <= 1;
                hblank_mode <= reg_bus.data_wr[7];
                byte_index <= '0;
                read_phase <= 1;
                pending <= !reg_bus.data_wr[7];
            end else if (hblank_trigger) begin
                pending <= 1;
            end else if (begin_block) begin
                pending <= 0;
                transferring <= 1;
                read_phase <= 1;
                byte_index <= '0;
            end else if (transferring) begin
                if (read_phase) begin
                    sample <= mem_bus.data_rd;
                    read_phase <= 0;
                end else begin
                    source <= source + 'd1;
                    dest <= next_dest(dest);
                    read_phase <= 1;

                    if (byte_index == BYTES_PER_BLOCK - 'd1) begin
                        byte_index <= '0;

                        if (length == '0) begin
                            busy <= 0;
                            hblank_mode <= 0;
                            transferring <= 0;
                        end else begin
                            length <= length - 'd1;
                            transferring <= !hblank_mode;
                        end
                    end else begin
                        byte_index <= byte_index + 'd1;
                    end
                end
            end
        end
    end

endmodule
