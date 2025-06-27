`timescale 1ns / 1ps

interface uart_if # (parameter DATA_BITS = 8);
    logic [DATA_BITS-1 :0] data;
    logic       valid;
    logic       ready;
    logic       sig;
    logic       parity;
    
    modport tx(
        input data, valid, parity,
        output ready, sig
        );
    modport rx(
        output data, valid,
        input ready, sig
        );
        
endinterface 
