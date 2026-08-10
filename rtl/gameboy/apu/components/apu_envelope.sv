import apu_types::*;

module apu_envelope(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic env_tick,
    input logic active,
    input logic trigger,
    input nrx2_t nrx2,
    input logic write,
    input nrx2_t write_data,
    output logic [3:0] volume
);
    logic [2:0] timer;
    logic running;
    logic [3:0] zombie_volume;

    always_comb begin
        zombie_volume = volume;
        if (nrx2.env_pace == 0 && running)
            zombie_volume = zombie_volume + 'd1;
        else if (!nrx2.envelope_dir)
            zombie_volume = zombie_volume + 'd2;

        if (nrx2.envelope_dir != write_data.envelope_dir)
            zombie_volume = 'd0 - zombie_volume;
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            volume <= '0;
            timer <= '0;
            running <= 0;
        end else begin
            if (env_tick && active && running && nrx2.env_pace != 0) begin
                if (timer > 'd1) begin
                    timer <= timer - 'd1;
                end else begin
                    timer <= nrx2.env_pace;
                    if (nrx2.envelope_dir && volume != 'hF)
                        volume <= volume + 'd1;
                    else if (!nrx2.envelope_dir && volume != 0)
                        volume <= volume - 'd1;
                    else
                        running <= 0;
                end
            end

            if (write && active)
                volume <= zombie_volume;

            if (trigger) begin
                volume <= nrx2.volume;
                timer <= nrx2.env_pace;
                running <= 1;
            end
        end
    end

endmodule
