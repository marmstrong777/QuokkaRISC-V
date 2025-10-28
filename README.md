# QuokkaRISC-V

A simple RISC-V softcore SoC targeting the Xilinx Zynq-7000 FPGA family.

## Platform Details
- Single core RISC-V (march=rv32i_zicsr)
- 8 KiB instruction memory, 64 KiB data memory; can be trivially extended up to target blockram limit
- Character mode DVI-D (HDMI compatible) display driver with support for 80 * 30 characters at 640 * 480 resolution at 60 fps
- UART controller
- Interrupt controller with support for up to 32 sources

![alt text](./quokkarv.drawio.svg)

## CPU Microarchitecture
- 5 stage pipeline
- 3 clock cycle branch penalty
- Presently lacking forwarding and branch prediction, thus IPC suffers

## Deployment Process
### Prerequisites
- Vivado 2025.1
- RISC-V GNU toolchain

### Steps
1. Change the working directory to the project root.
2. Execute "vivado -source scripts/create_project.tcl" to instantiate a vivado project.
3. Execute src/c_to_hex.sh with test c program as first argument to generate instruction and data memory hex files if not already present. Presently the memory can only be instantiated at bitstream programming time.
4. Vivado GUI can be used for synthesis/implementation/bitstream programming.

## IP Used / Portability
- clk_gen used for clock synthesis.
- fifo_generator used for UART asyncronous FIFO clock domain crossing.
- OSERDESE2 shift register used for DVI-D transmitter.
- TMDS_33 I/O standard used for DVI-D transmitter.

## Future Development
- RISC-V debug module (will additionally allow for upload of programs after bitstream programming)
- Port libc (newlib)
- GPIO peripheral
- Sound output peripheral
- Bitmap display peripheral
- External memory interface (replace current memory and add cache)

## Acknowledgements
- TMDS encoder implementation provided by https://github.com/projf/display_controller/tree/master
- Character mode display font data sourced from http://viznut.fi/unscii/
