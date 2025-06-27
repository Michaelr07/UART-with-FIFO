# UART-with_FIFO
This project implements a UART (Universal Asynchronous Receiver Transmitter) system with FIFO (First-In-First-Out) buffers for both transmission (TX) and reception (RX), written in synthesizable SystemVerilog. It is designed to support modularity, configurability, and testability.

## Features
- **Configurable UART Transmitter & Receiver**
  - Parameterized data bits, parity, stop bits, and baud rate
  - Supports optional even/odd parity
- **Synchronous FIFO Buffers**
  - TX FIFO buffers outgoing data
  - RX FIFO stores received bytes
- **Modular Design**
  - Separated `uart_tx`, `uart_rx`, and `sync_fifo` modules
  - FIFO RAM abstracted for synthesis as block RAM
- **Handshaking Interface**
  - Follows `valid`/`ready` protocol for control
- **Testbenches**
  - TBs for UART TX, RX, and FIFO to validate functionality

## Testbenches
