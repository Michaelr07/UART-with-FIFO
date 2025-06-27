module block_ram
#(
    parameter int ADDR_WIDTH = 4,
                  DATA_WIDTH = 8
)
(
    input logic clk,
    input logic write_en,
    input logic read_en,
    input logic  [ADDR_WIDTH-1:0] write_addr,
    input logic  [ADDR_WIDTH-1:0] read_addr,
    input logic  [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);
    
    (* ram_style = "block" *) logic [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

    always_ff @(posedge clk) begin
        if (write_en)
            mem[write_addr] <= data_in;
        if (read_en)
            data_out <= mem[read_addr];
    end

endmodule
