import mem_types::*;
import cpu_types::*;

module oam_dma(
    input logic clk,
    input logic rst,
    bus.child_port reg_bus,
    bus.parent_port mem_bus,
    output logic active
);
    logic [7:0] page;
    logic [7:0] index;
    logic [7:0] sample;
    logic [1:0] tcycle;
    logic starting;
    logic running;

    localparam logic [7:0] LAST_INDEX = OAM_END - OAM_START;

    assign running = active && !starting;

    always_comb begin
        reg_bus.data_rd = 'hFF;
        if (reg_bus.cs && reg_bus.rd)
            reg_bus.data_rd = page;
    end

    always_comb begin
        mem_bus.addr = 'd0;
        mem_bus.data_wr = 'd0;
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
            active <= 0;
            starting <= 0;
        end else if (reg_bus.cs && reg_bus.wr) begin
            page <= reg_bus.data_wr;
            index <= '0;
            sample <= '0;
            tcycle <= T0;
            active <= 1;
            starting <= 1;
        end else if (active) begin
            if (starting) begin
                starting <= 0;
            end else begin
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
                            active <= 0;
                            index <= 'd0;
                        end else begin
                            index <= index + 'd1;
                        end
                    end
                endcase
            end
        end
    end

endmodule
