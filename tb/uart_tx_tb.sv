`timescale 1ns / 1ps

module uart_tx_tb;

  // Parameters
  localparam DATA_BITS = 8;
  localparam BAUD_RATE = 9600;
  localparam SYS_CLK   = 100_000_000;
  localparam STOP_BITS = 1;
  localparam HAS_PARITY = 1;
  localparam PARITY_EVEN = 1;

  localparam CLK_PERIOD = 10; // 100 MHz clock
  localparam BAUD_PERIOD = 1_000_000_000 / BAUD_RATE;

  // DUT signals
  logic clk = 0, reset = 1;
  logic [DATA_BITS-1:0] data;
  logic valid, ready;
  logic sig;

  // Instantiate DUT
  uart_tx #(
    .DATA_BITS(DATA_BITS),
    .BAUD_RATE(BAUD_RATE),
    .SYS_CLK(SYS_CLK),
    .STOP_BITS(STOP_BITS),
    .HAS_PARITY(HAS_PARITY),
    .PARITY_EVEN(PARITY_EVEN)
  ) dut (
    .clk(clk),
    .reset(reset),
    .data(data),
    .valid(valid),
    .ready(ready),
    .sig(sig)
  );

  // Clock generation
  always #(CLK_PERIOD/2) 
    clk = ~clk;

  task send_byte(input [7:0] tx_byte);
    begin
      data = tx_byte;
      valid = 1;
      @(posedge clk);
      while (!ready) @(posedge clk);
      valid = 0;
    end
  endtask
  
    task check_tx_frame(input [7:0] tx_byte);
    integer i;
    reg parity;
    begin
      // Wait for start bit (should be 0)
      wait (sig == 0);
      #(BAUD_PERIOD);

      // Sample and check data bits
      for (i = 0; i < DATA_BITS; i++) begin
        if (sig !== tx_byte[i])
          $display("FAIL: Bit %0d expected %b got %b", i, tx_byte[i], sig);
        #(BAUD_PERIOD);
      end

      // Parity check if enabled
      if (HAS_PARITY) begin
        parity = ^tx_byte;
        if (!PARITY_EVEN) parity = ~parity;
        if (sig !== parity)
          $display("FAIL: Parity mismatch. Expected %b got %b", parity, sig);
        #(BAUD_PERIOD);
      end

      // Stop bit(s)
      for (i = 0; i < STOP_BITS; i++) begin
        if (sig !== 1)
          $display("FAIL: Stop bit %0d not 1. Got %b", i, sig);
        #(BAUD_PERIOD);
      end

      $display("PASS: Frame for 0x%h transmitted correctly.", tx_byte);
    end
  endtask

   initial begin
    sig = 1;
    data = 8'h00;
    valid = 0;

    #100;
    reset = 0;

    $display("Sending 0xA5");
    send_byte(8'hA5);
    check_tx_frame(8'hA5);

    $display("Sending 0x5A");
    send_byte(8'h5A);
    check_tx_frame(8'h5A);
    
    $display("Sending 0xFF");
    send_byte(8'hFF);
    check_tx_frame(8'hFF);

    $display("Sending 0x00");
    send_byte(8'h00);
    check_tx_frame(8'h00);
    
    $stop;
  end

endmodule
