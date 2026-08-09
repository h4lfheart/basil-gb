typedef struct packed {
    logic [1:0] color;
    logic [2:0] palette;
    logic bg_priority;
} fifo_pixel_t;

typedef struct {
    logic [3:0] count;
    logic [2:0] head;
    fifo_pixel_t data [8];
} pixel_fifo_t;

function automatic fifo_pixel_t fifo_head(input pixel_fifo_t fifo);
    return fifo.data[fifo.head];
endfunction

function automatic void fifo_reset(ref pixel_fifo_t fifo);
    fifo.count = 0;
    fifo.head = 0;
endfunction

function automatic void fifo_pop(ref pixel_fifo_t fifo);
    if (fifo.count > 0) begin
        fifo.head = fifo.head + 1;
        fifo.count--;
    end
endfunction

function automatic void fifo_push(ref pixel_fifo_t fifo, input fifo_pixel_t in);
    logic [2:0] tail;
    tail = fifo.head + fifo.count;
    fifo.data[tail] = in;
    if (fifo.count < 8)
        fifo.count++;
endfunction

function automatic void fifo_pad_transparent(ref pixel_fifo_t fifo);
    fifo_pixel_t blank;
    blank = fifo_pixel_t'{color: 2'b00, palette: 3'b000, bg_priority: 1'b0};
    for (int i = 0; i < 8; i++)
        if (fifo.count < 8)
            fifo_push(fifo, blank);
endfunction

function automatic void fifo_overlay_sprite(
    ref pixel_fifo_t fifo,
    input logic [7:0] tile_data_low,
    input logic [7:0] tile_data_high,
    input logic x_flip,
    input logic [2:0] palette,
    input logic bg_priority,
    input logic [2:0] skip_pixels
);
    logic [2:0] slot;
    logic [2:0] bit_index;
    logic [1:0] color;
    fifo_pixel_t existing;
    fifo_pixel_t pixel;

    fifo_pad_transparent(fifo);

    for (int i = 0; i < 8; i++) begin
        if (i < int'(skip_pixels))
            continue;

        slot = 3'(i - int'(skip_pixels));
        if (slot >= fifo.count)
            break;

        bit_index = x_flip ? 3'(i) : 3'(7 - i);
        color = {tile_data_high[bit_index], tile_data_low[bit_index]};
        if (color == 2'b00)
            continue;

        existing = fifo.data[fifo.head + slot];
        if (existing.color != 2'b00)
            continue;

        pixel = fifo_pixel_t'{
            color: color,
            palette: palette,
            bg_priority: bg_priority
        };
        fifo.data[fifo.head + slot] = pixel;
    end
endfunction
