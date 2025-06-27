module uart_tx
#(
    parameter DATA_BITS        = 8,
    parameter int BAUD_RATE    = 115200,
    parameter int SYS_CLK      = 100_000_000,
    parameter int STOP_BITS    = 1,
    parameter HAS_PARITY       = 0,   // 1 = enable parity, 0 = disable
    parameter PARITY_EVEN      = 0    // 1 = even parity, 0 = odd parity
)
(
    input  logic clk,
    input  logic reset,
    input logic [DATA_BITS-1 : 0] data, 
    input logic valid,
    output logic ready, sig
);

    localparam int N = SYS_CLK / BAUD_RATE;
    localparam int FRAME_BITS = 1 + DATA_BITS + HAS_PARITY + STOP_BITS; // start + data + parity (opt) + stop
    localparam [STOP_BITS-1:0] STOP_PATTERN = {STOP_BITS{1'b1}};        // STOP_BITS of 1s

    typedef enum logic [1:0] { IDLE, LOAD, SHIFT, DONE } state_t;
    state_t cs, ns;

    logic [FRAME_BITS-1:0] data_reg;
    logic [$clog2(FRAME_BITS):0] bit_counter;
    logic parity_bit;
    logic tick;

    // Tick generator
    timer #(N) baud_generator (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .done(tick)
    );

    // Combinational parity logic
    always_comb begin
        if (HAS_PARITY) begin
            parity_bit = ^data;
            if (!PARITY_EVEN)
                parity_bit = ~parity_bit;
        end else begin
            parity_bit = 1'b0;
        end
    end

    // FSM next-state logic
    always_comb begin
        ns = cs;
        case (cs)
            IDLE:  if (valid && ready) ns = LOAD;
            LOAD:  if (tick) ns = SHIFT;
            SHIFT: if (tick && bit_counter == FRAME_BITS-1) ns = DONE;
            DONE:  if (tick) ns = IDLE;
        endcase
    end

    // FSM and shift register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cs <= IDLE;
            bit_counter <= 0;
            ready <= 1;
            sig <= 1; // idle line
        end else begin
            cs <= ns;

            case (cs)
                IDLE: begin
                    ready <= 1;
                end

                LOAD: if (tick) begin
                    bit_counter <= 0;
                    ready <= 0;
                    if (HAS_PARITY)
                        data_reg <= {STOP_PATTERN, parity_bit, data, 1'b0};
                    else
                        data_reg <= {STOP_PATTERN, data, 1'b0};
                end

                SHIFT: if (tick) begin
                    sig <= data_reg[0];
                    data_reg <= data_reg >> 1;
                    bit_counter <= bit_counter + 1;
                end

                DONE: if (tick) begin
                    sig <= 1;
                    ready <= 1;
                end
            endcase
        end
    end

endmodule
