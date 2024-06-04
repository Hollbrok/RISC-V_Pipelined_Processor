`include "main_decoder.sv"
`include "alu_decoder.sv"

`include "../ADDITIONAL/FlopReset.sv"
`include "../ADDITIONAL/FlopResetEn.sv"
`include "../ADDITIONAL/FlopResetClear.sv"

module controller(
    input logic clk, reset,

    // Decode stage control signals
    input logic [6:0] opD,
    input logic [2:0] funct3D,
    input logic funct7b5D,
    output logic [2:0] ImmSrcD,

    // Execute stage control signals
    input logic FlushE,
    input logic ZeroE,
    output logic PCSrcE, // for datapath and Hazard Unit
    output logic [2:0] ALUControlE,
    output logic ALUSrcAE,
    output logic ALUSrcBE,
    output logic ResultSrcEb0, // for Hazard Unit
    
    // Memory stage control signals
    output logic MemWriteM,
    output logic RegWriteM, // for Hazard Unit

    // Writeback stage control signals
    output logic RegWriteW, // for datapath and Hazard Unit
    output logic [1:0] ResultSrcW
);
    // pipelined control signals
    logic RegWriteD, RegWriteE;
    logic [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
    logic MemWriteD, MemWriteE;
    logic JumpD, JumpE;
    logic BranchD, BranchE;
    logic [1:0] ALUOpD;
    logic [2:0] ALUControlD;
    logic ALUSrcAD;
    logic ALUSrcBD; // for lui

    // Decode stage logic
    maindec md(opD, ResultSrcD, MemWriteD, BranchD,
    ALUSrcAD, ALUSrcBD, RegWriteD, JumpD, ImmSrcD, ALUOpD);
    aludec ad(opD[5], funct3D, funct7b5D, ALUOpD, ALUControlD);

    // Execute stage pipeline control register and logic
    floprc #(11) controlregE(
        clk, reset, FlushE,
        {RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD,
        ALUControlD, ALUSrcAD, ALUSrcBD},
        {RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE,
        ALUControlE, ALUSrcAE, ALUSrcBE}
    );

    assign PCSrcE = (BranchE & ZeroE) | JumpE;
    assign ResultSrcEb0 = ResultSrcE[0];

    // Memory stage pipeline control register
    flopr #(4) controlregM(
        clk, reset,
        {RegWriteE, ResultSrcE, MemWriteE},
        {RegWriteM, ResultSrcM, MemWriteM}
    );

    // Writeback stage pipeline control register
    flopr #(3) controlregW(
        clk, reset,
        {RegWriteM, ResultSrcM},
        {RegWriteW, ResultSrcW}
    );

endmodule
