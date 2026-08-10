module audio_cdc (
    input logic audio_clk,
    input logic audio_rst,
    input logic src_clk,
    input logic src_rst,
    input logic signed [9:0] src_left,
    input logic signed [9:0] src_right,
    output logic signed [15:0] sample_left,
    output logic signed [15:0] sample_right
);
    logic request;
    logic [2:0] request_sync;
    logic signed [17:0] accumulated_left;
    logic signed [17:0] accumulated_right;
    logic signed [17:0] held_left;
    logic signed [17:0] held_right;

    always_ff @(posedge audio_clk or posedge audio_rst) begin
        if (audio_rst) begin
            request <= 0;
            sample_left <= '0;
            sample_right <= '0;
        end else begin
            request <= ~request;
            sample_left <= (held_left >>> 1) + (held_left >>> 2) - (held_left >>> 6);
            sample_right <= (held_right >>> 1) + (held_right >>> 2) - (held_right >>> 6);
        end
    end

    always_ff @(posedge src_clk or posedge src_rst) begin
        if (src_rst) begin
            request_sync <= '0;
            accumulated_left <= '0;
            accumulated_right <= '0;
            held_left <= '0;
            held_right <= '0;
        end else begin
            request_sync <= {request_sync[1:0], request};
            if (request_sync[2] != request_sync[1]) begin
                held_left <= accumulated_left + src_left;
                held_right <= accumulated_right + src_right;
                accumulated_left <= '0;
                accumulated_right <= '0;
            end else begin
                accumulated_left <= accumulated_left + src_left;
                accumulated_right <= accumulated_right + src_right;
            end
        end
    end

endmodule
