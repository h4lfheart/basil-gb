module edge_detect(
    input logic clk,
    input logic rst,
    input logic signal,
    output logic rising,
    output logic falling
);
    logic prev;

    always_ff @(posedge clk) begin
        if (rst)
            prev <= 0;
        else
            prev <= signal;
    end

    assign rising = signal && !prev;
    assign falling = !signal && prev;
endmodule