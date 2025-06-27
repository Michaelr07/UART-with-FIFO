module fifo_tb;

  localparam ADDR_WIDTH = 2;
  localparam DATA_WIDTH = 8;

  localparam CLK_PERIOD = 10;

  logic clk = 0, reset = 1;
  logic write_req, read_req;
  logic [DATA_WIDTH-1:0] data_in;
  logic [DATA_WIDTH-1:0] data_out;
  logic full, empty;
  logic [7:0] val;
    
  // Instantiate DUT
  sync_fifo #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .clk(clk),
      .reset(reset),
      .write_req(write_req),
      .read_req(read_req),
      .data_in(data_in),
      .data_out(data_out),
      .full(full),
      .empty(empty)
  );

  // Clock generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Write task
  task write_data(input [DATA_WIDTH-1:0] wdata);
    begin
      @(negedge clk);
      if (!full) begin
        write_req = 1;
        data_in = wdata;
        @(negedge clk);
        write_req = 0;
      end else begin
        $display("Write attempt ignored - FIFO is FULL");
      end
    end
  endtask

  // Read task
  task read_data(output [DATA_WIDTH-1:0] rdata);
    begin
      @(negedge clk);
      if (!empty) begin
        read_req = 1;
        @(negedge clk);
        read_req = 0;
        rdata = data_out;
      end else begin
        $display("Read attempt ignored - FIFO is EMPTY");
      end
    end
  endtask

  initial begin
    // Initial reset
    write_req = 0;
    read_req = 0;
    data_in = 0;
    #20 reset = 0;

    // Write a few values
    write_data(8'hA5);
    write_data(8'h5A);
    write_data(8'hFF);
    write_data(8'h00);

    // Read values
    read_data(val); 
        $display("Read: %h", val);
    read_data(val); 
        $display("Read: %h", val);
    read_data(val); 
        $display("Read: %h", val);

    // Read and Write at the same time
    fork
        begin write_data(8'hCC); end
        begin read_data(val); $display("Concurrent Read: %h", val); end
    join
    
    //emptying out the buffer
    read_data(val); 
    $display("Read: %h", val);
    
    // Wait and finish
    #100;
    $finish;
  end

endmodule
