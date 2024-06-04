`include "main_pipeline.sv"
`include "imem.sv"
`include "dmem.sv"

module PipelineCPU
(
    input logic clk, reset
);

    logic [31:0] PCF/* verilator public */, InstrF/* verilator public */, ReadDataM /* verilator public */, write_dataM, alu_outM;
    logic [2:0] mem_sizeM;
    logic mem_writeM;

    //
    main_pipeline main_pipeline(clk, reset, PCF, InstrF, mem_writeM, mem_sizeM, alu_outM, write_dataM, ReadDataM);

    imem instr_memory(PCF, InstrF);
    dmem data_memory(clk, mem_writeM, alu_outM, write_dataM, ReadDataM);

endmodule
