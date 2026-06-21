typedef struct packed {
    logic [1:0] color;
    logic [1:0] palette;
    logic bg_priority;
} fifo_pixel_t;

typedef struct {
    logic [3:0] count;
    logic [2:0] head;
    fifo_pixel_t data [8];
} pixel_fifo_t;

function automatic fifo_pixel_t fifo_head(ref pixel_fifo_t fifo);
    return fifo.data[fifo.head];
endfunction

function automatic void fifo_reset(ref pixel_fifo_t fifo);
    fifo.count = 0;
    fifo.head = 0;
endfunction

function automatic fifo_pixel_t fifo_pop(ref pixel_fifo_t fifo);
    fifo_pixel_t out;
    out = fifo.data[fifo.head];
    if (fifo.count > 0) begin
        fifo.head = fifo.head + 1;
        fifo.count--;
    end
    return out;
endfunction

function automatic void fifo_push(ref pixel_fifo_t fifo, input fifo_pixel_t in);
    logic [2:0] tail;
    tail = fifo.head + fifo.count;
    fifo.data[tail] = in;
    if (fifo.count < 8)
        fifo.count++;
endfunction