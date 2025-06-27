`timescale 1ns / 1ps

module UART_top 
#(
    parameter DATA_BITS = 8,                    // Width of UART data
    parameter int BAUD_RATE = 9600,             // UART baud rate
    parameter int SYS_CLK = 100_000_000,        // System clock frequency
    parameter int STOP_BITS = 1,                // Number of stop bits
    parameter HAS_PARITY = 0,                   // Enable parity bit
    parameter PARITY_EVEN = 0,                  // 1 for even parity, 0 for odd parity
    
    parameter ADDR_WIDTH = 2                    // FIFO address width (depth = 2^ADDR_WIDTH)
)
(
    input logic clk,                            // System clock
    input logic reset,                          // Asynchronous reset
    input logic UART_TXD_IN,                    // Incoming UART signal (from external source)
    output logic UART_RXD_OUT,                  // Outgoing UART signal (to external receiver)

    // Transmit Interface
    input logic [DATA_BITS-1:0] out_tx,         // Data to be transmitted (external source)
    input logic write_req,                      // Request to write to TX FIFO
    output logic full_tx,                       // TX FIFO full indicator

    // Receive Interface
    input logic read_req,                       // Request to read from RX FIFO
    output logic [DATA_BITS-1:0] rx_data,       // Received data output
    output logic empty_rx                       // RX FIFO empty indicator
);

    // Internal TX signals
    logic empty_tx, tx_valid, tx_ready;
    logic [DATA_BITS-1:0] tx_data;
    
    // TX FIFO (buffers outgoing data)
    sync_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_BITS)
    ) tx_fifo (
        .clk(clk),
        .reset(reset),
        .write_req(write_req),
        .read_req(tx_ready),                        // Read when UART TX is ready
        .data_in(out_tx),
        .data_out(tx_data),
        .full(full_tx),
        .empty(empty_tx)
    );
    
    // UART Transmitter
    uart_tx #(
        .DATA_BITS(DATA_BITS),
        .BAUD_RATE(BAUD_RATE),
        .SYS_CLK(SYS_CLK),
        .STOP_BITS(STOP_BITS),
        .HAS_PARITY(HAS_PARITY),
        .PARITY_EVEN(PARITY_EVEN)
    ) u1 (
        .clk(clk),
        .reset(reset),
        .data(tx_data),
        .valid(tx_valid),                           // Valid signal when FIFO has data
        .ready(tx_ready),                           // Ready signal from UART TX
        .sig(UART_RXD_OUT)
    );
    
    // Internal RX signals
    logic full_rx, rx_ready, rx_valid;
    logic [DATA_BITS-1:0] out_rx;
    
    // UART Receiver
    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .BAUD_RATE(BAUD_RATE),
        .SYS_CLK(SYS_CLK),
        .STOP_BITS(STOP_BITS),
        .HAS_PARITY(HAS_PARITY),
        .PARITY_EVEN(PARITY_EVEN)
    ) u2 (
        .clk(clk),
        .reset(reset),
        .sig(UART_TXD_IN),
        .ready(rx_ready),                           // RX ready indicates FIFO is not full
        .valid(rx_valid),                           // RX valid when new byte received
        .data_out(out_rx)
    );
    
    // RX FIFO (buffers incoming data)
    sync_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_BITS)
    ) rx_fifo (
        .clk(clk),
        .reset(reset),
        .write_req(rx_valid),                       // Write when UART RX has valid data
        .read_req(read_req),
        .data_in(out_rx),
        .data_out(rx_data),
        .full(full_rx),
        .empty(empty_rx)
    );
    
    // Control logic for handshaking
    assign rx_ready = ~full_rx;                     // Allow UART RX to write if FIFO is not full
    assign tx_valid = ~empty_tx;                    // Assert valid when TX FIFO has data

endmodule
