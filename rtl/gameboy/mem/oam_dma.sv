import mem_types::*;
import cpu_types::*;

module oam_dma(
    input logic clk,
    input logic rst,
    bus.child_port reg_bus,
    bus.parent_port mem_bus,
    output logic active,
    output logic [15:0] src_addr
);
    logic [7:0] page;
    logic [7:0] index;
    logic [7:0] sample;
    logic [1:0] tcycle;
    logic busy;
    logic [2:0] delay;
    logic oam_locked;
    logic running;

    localparam logic [2:0] START_DELAY = 3'd5;
    localparam logic [7:0] LAST_INDEX = OAM_END - OAM_START;

    assign running = busy && (delay == '0);
    assign active = running || oam_locked;
    assign src_addr = {page, index};

    always_comb begin
        reg_bus.data_rd = 'hFF;
        if (reg_bus.cs && reg_bus.rd)
            reg_bus.data_rd = page;
    end

    always_comb begin
        mem_bus.addr = '0;
        mem_bus.data_wr = '0;
        mem_bus.rd = 0;
        mem_bus.wr = 0;
        mem_bus.cs = 0;

        if (running) begin
            unique case (tcycle)
                T0, T1: begin
                    mem_bus.addr = {page, index};
                    mem_bus.rd = 1;
                    mem_bus.cs = 1;
                end
                T2: begin
                    mem_bus.addr = OAM_START + 16'(index);
                    mem_bus.data_wr = sample;
                    mem_bus.wr = 1;
                    mem_bus.cs = 1;
                end
                T3: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            page <= '0;
            index <= '0;
            sample <= '0;
            tcycle <= T0;
            busy <= 0;
            delay <= '0;
            oam_locked <= 0;
        end else if (reg_bus.cs && reg_bus.wr) begin
            page <= reg_bus.data_wr;
            index <= '0;
            sample <= '0;
            tcycle <= T0;
            oam_locked <= busy;
            busy <= 1;
            delay <= START_DELAY;
        end else if (busy) begin
            if (delay != '0) begin
                delay <= delay - 1;
            end else begin
                oam_locked <= 0;
                tcycle <= tcycle + 1;
                unique case (tcycle)
                    T0: begin

                    end
                    T1: begin
                        sample <= mem_bus.data_rd;
                    end
                    T2: begin

                    end
                    T3: begin
                        if (index == LAST_INDEX) begin
                            busy <= 0;
                            index <= '0;
                        end else begin
                            index <= index + 1;
                        end
                    end
                endcase
            end
        end
    end

endmodule
