module uart_rx 
#(  
    parameter DATA_BITS        = 8,
    parameter int BAUD_RATE    = 115200,
    parameter int SYS_CLK      = 100_000_000,
    parameter int STOP_BITS    = 1,     // up to 3
    parameter HAS_PARITY       = 0,   // 1 = enable parity, 0 = disable
    parameter PARITY_EVEN      = 0    // 1 = even parity, 0 = odd parity)
)
( 
    input logic clk,
    input logic reset,
    input logic sig,    //sig
    input logic ready,  //ack
    output logic valid, //req
    output logic [DATA_BITS-1:0] data_out
);
    
    localparam int FRAME_BITS = DATA_BITS + HAS_PARITY;
    localparam int N = SYS_CLK/BAUD_RATE;
    localparam int N1 = N + (N/2); 
    
    logic tick, tick1;              // one for regular baud rate and the other for the one time baud
    logic enable, enable1;          // enable control signals
    logic parity;                   // for keeping track of parity
    logic [FRAME_BITS-1:0] data_reg;
    logic computed_parity;          // for checking parity
    
    
    logic [$clog2(FRAME_BITS):0] bit_counter;
    logic [$clog2 (STOP_BITS):0] stop_counter;
    
    typedef enum logic [1:0] {IDLE, START, SHIFT, DONE} StateType;
    StateType ns, cs;
    
    timer #(N) baud_generator (clk, reset, enable, tick);       // regualr baud rate
    timer #(N1) onenhalf (clk, reset, enable1, tick1);           // 1 and a half baud rate
    
    always_comb begin
        ns = cs;
        case(cs)
            IDLE: begin
                if(sig == 0)                    // when start bit is sent which is 0
                    ns = START;
            end
    
            START: begin
                if(tick1)                           
                    ns = SHIFT;
            end
    
            SHIFT: begin
                if(tick)
                    if (bit_counter == FRAME_BITS - 1)
                        ns = DONE;
            end
    
            DONE: begin
                if (tick)
                    if (stop_counter == STOP_BITS - 1 )
                        ns = IDLE;
            end
        endcase
    end
    
    always_ff @ (posedge clk or posedge reset) begin
        if(reset) begin
            cs <= IDLE;
            data_out <= 0;
            bit_counter <= 0;
            stop_counter <= 0;
            enable <= 0;
            enable1 <= 0;
            valid <= 0;
        end
        else begin
            cs <= ns;
            if (valid && ready) // makes sure to set request to 0 only when it has been acknowledged
                valid <= 0;
            else if (cs == IDLE && sig == 0) begin	
                enable1 <= 1;                   //enable for the 1.5 baud rate tick
                stop_counter <= 0;              // resetting stop bit counter
            end
            else if(cs == START && tick1) begin
                enable <= 1;                    // go back to normal baud rate ticks
                enable1 <= 0;
                bit_counter <= 1;   //reset bit_counter
                data_reg[FRAME_BITS-1] <= sig;				// making it the first sample bit to get shifted
            end
            else if(cs == SHIFT && tick) begin
                data_reg <= {sig, data_reg[FRAME_BITS-1:1]};		// right shift
                bit_counter <= bit_counter + 1;
            end
            else if(cs == DONE && tick) begin
                enable <= 0;
                stop_counter <= stop_counter + 1;
                if(HAS_PARITY && (computed_parity != parity))
                    valid <= 0;
                else
                    valid <= 1;
            end
            
        end
    end
    
    assign data_out = data_reg [DATA_BITS-1 : 0];
    assign parity = data_reg [FRAME_BITS-1];
    assign computed_parity = (PARITY_EVEN)? (^data_out) : ~(^data_out);

endmodule