`timescale 1ns / 1ps

module uart_rx_tb;

    localparam DATA_BITS        = 8;
    localparam int BAUD_RATE    = 9600;
    localparam int SYS_CLK      = 100_000_000;
    localparam int STOP_BITS    = 1; 
    localparam HAS_PARITY       = 0;
    localparam PARITY_EVEN      = 0;
    
    localparam CLK_PERIOD = 10;
    localparam BAUD_PERIOD = 1_000_000_000/BAUD_RATE;

    logic clk = 0;
    logic reset = 1;
    logic sig;
    logic ready = 0;
    logic valid;
    logic [DATA_BITS-1:0] data_out;
    
    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .BAUD_RATE(BAUD_RATE),
        .SYS_CLK(SYS_CLK),
        .STOP_BITS(STOP_BITS),
        .HAS_PARITY(HAS_PARITY),
        .PARITY_EVEN(PARITY_EVEN)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .sig(sig),              //change
        .ready(ready),               //  ready
        .valid(valid),               // valid
        .data_out(data_out)               // data_out
    );

    always 
        #(CLK_PERIOD/2)
        clk = ~clk;
        
    
    task send_uart_byte (input [7:0] i_byte);
        integer i;
        reg parity;
        
        begin
        
        // start bit is initally low
        sig = 0;
        #(BAUD_PERIOD);
        
        //data bits
        for (i = 0; i <DATA_BITS; i = i + 1) begin
            sig = i_byte[i];
            #(BAUD_PERIOD);
        end
        
        //for parity
        if (HAS_PARITY) begin
            sig = ^i_byte;
            if (!PARITY_EVEN) 
                parity = ~parity;
            sig = parity;
            #(BAUD_PERIOD);
        end
        
        //stop bit(s)
        sig = 1;
        #(BAUD_PERIOD * STOP_BITS);
        end
        
    endtask
    
    initial begin
       
        sig = 1;
        reset = 1;
        #(10*CLK_PERIOD);
        reset = 0;
        #(10*CLK_PERIOD);
        
        $display("Sending Byte 0xA5");
        send_uart_byte(8'hA5);
        
        //wait for the reception
        wait (valid == 1);
        #CLK_PERIOD;
        if(data_out == 8'hA5)
            $display("PASS: Recevied correct Byte");
        else
            $display("FAIL: Wrong Byte, Received %h", data_out);
            
       //acknowledge receipt
       ready = 1;
       #CLK_PERIOD;
       ready = 0;
       
       #(10*CLK_PERIOD);
       
       $display("Sending Byte 0xFF");
       send_uart_byte(8'hFF);
        
        //wait for the reception
        wait (valid == 1);
        #CLK_PERIOD;
        if(data_out == 8'hFF)
            $display("PASS: Recevied correct Byte");
        else
            $display("FAIL: Wrong Byte, Received %h", data_out);
            
       //acknowledge receipt
       ready = 1;
       #CLK_PERIOD;
       ready = 0;
       
       #(10*CLK_PERIOD);
       
       $display("Sending Byte 0x00");
       send_uart_byte(8'h00);
        
        //wait for the reception
        wait (valid == 1);
        #CLK_PERIOD;
        if(data_out == 8'h00)
            $display("PASS: Recevied correct Byte");
        else
            $display("FAIL: Wrong Byte, Received %h", data_out);
            
       //acknowledge receipt
       ready = 1;
       #CLK_PERIOD;
       ready = 0;
       
       #(10*CLK_PERIOD);
       $stop;
    
    end
    
endmodule