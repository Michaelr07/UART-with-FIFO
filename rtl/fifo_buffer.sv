`timescale 1ns / 1ps

module sync_fifo
#(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
)
(
    input logic clk,
    input logic reset,
    input logic write_req, read_req,        // for the external module to request when to write/read
    input logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic full, empty
);
    localparam MAX = 2**ADDR_WIDTH;         // calculates the amount of entries
    
    logic [ADDR_WIDTH-1:0] write_ptr, read_ptr;     //the address pointers for where to write/read data
    logic [ADDR_WIDTH:0] fifo_counter;              // for keeping track of pointers
    logic write_en, read_en;                        // signals that enable read/write
    
    // Block Ram instantiation
    block_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram (
        .clk(clk),
        .write_en(write_en),
        .read_en(read_en),
        .write_addr(write_ptr),
        .read_addr(read_ptr),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    assign write_en = !full && write_req;
    assign read_en = !empty && read_req;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset)begin
           fifo_counter <= 0;
           write_ptr <= 0;
           read_ptr <= 0; 
        end
        else begin
            case({write_en, read_en})
            2'b01:  begin 
                read_ptr <= read_ptr + 1;
                fifo_counter <= fifo_counter - 1;
            end
            2'b10:  begin
                write_ptr <= write_ptr + 1;
                fifo_counter <= fifo_counter + 1;
            end
            2'b11:  begin
                read_ptr <= read_ptr + 1;
                write_ptr <= write_ptr + 1;
            end
            default:    begin
            
            end
            endcase
        end
    end
    
    assign full = (fifo_counter == MAX);
    assign empty = (fifo_counter == 0);

endmodule
