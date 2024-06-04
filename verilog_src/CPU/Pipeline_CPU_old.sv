`include "REG_STAGE/reg_stage.sv"
`include "ALU_STAGE/alu_stage.sv"
`include "DATA_STAGE/data_stage.sv"
`include "DATA_STAGE/mem_extender.sv"


module PipelineCPU
(
    input wire clk,
    input wire reset,

    inout wire [31:0] MemData,
    output wire ReadMemEN,
    output wire WriteMemEN,
    output wire [31:0] MemoryAdr, 

    output wire [4:0] R1_adr,
    output wire [4:0] R2_adr,
    output wire [4:0] DR_adr,

    input wire [31:0] R1,
    input wire [31:0] R2,
    output wire [31:0] DR,

    output wire RegWEN
);

// Hazard unit

logic stall/* verilator public */;

assign RS_reset = reset | stall | ALU_PCSrc;
assign ALU_reset = reset;
assign DS_reset = reset; //|  MemAssert | stall;

//   Data resolver

assign R_1_solve = (((RS_R_1_num == ALU_DR_num) & ALU_RegWrite) & (RS_R_1_num != 0))? 2'b10:
                   (((RS_R_1_num == DS_DR_num) & DS_RegWrite) & (RS_R_1_num != 0))?   2'b01: 2'b00;

assign R_2_solve = (((RS_R_2_num == ALU_DR_num) & ALU_RegWrite) & (RS_R_2_num != 0))? 2'b10:
                   (((RS_R_2_num == DS_DR_num) & DS_RegWrite) & (RS_R_2_num != 0))?   2'b01: 2'b00;


assign stall = (RS_ResultSrc[0]) & ((R1_adr == RS_DR_num) | (R2_adr == RS_DR_num));

assign PC_en = ~stall;


//Fetch Stage

reg [31:0] Instr;
reg [31:0] Inst_PC/* verilator public */;
reg [31:0] Inst_PC_plus_4;

always @(posedge clk) begin
    if(reset | ALU_PCSrc)begin
        Instr <= 0;
        Inst_PC <= 0;
        Inst_PC_plus_4 <= 0;
    end else if(~stall) begin
        Instr <= ex_MemData;
        Inst_PC <= PC;
        Inst_PC_plus_4 <= PC_plus_4;
    end
end

// Mem Asert
assign RS_EN = 1;//~MemAssert;
assign ALU_EN = 1;//~MemAssert;
assign DS_EN = 1;//~MemAssert;

wire [31:0] ex_ALU_WriteData;
wire [31:0] ex_MemData;

assign MemData = (WriteMemEN)? ex_ALU_WriteData: 32'bz; 

assign MemoryAdr = (MemAssert)? ({1'b1, {31{1'b0}}} |  ALUResData): PC;

MemExtender MemExtender(
    .MemWrite(ALU_WriteData),
    .MemWriteEx(ex_ALU_WriteData),

    .MemRead(MemData),
    .MemReadEx(ex_MemData),
    .funct3((MemAssert)? ALU_ALUControl: 3'b010)
);


// Reg_wr_stage

reg [31:0] PC /* verilator public */;
wire PC_en;

always @(posedge clk) begin
    if(reset)
        PC <= 0;
    else if(~MemAssert & PC_en) begin // I don't sure
        if(ALU_PCSrc)
            PC <= ALU_PCTarget;
        else 
            PC <= PC_plus_4;
    end
end

assign DR_adr = DS_DR_num;
assign RegWEN = DS_RegWrite;

mux3#(32) ResultMux (
    .d0(DS_ALUResData),
    .d1(DS_ReadData),
    .d2(DS_PC_plus_4),

    .s(DS_ResultSrc),

    .y(DR)
);

// Reg Stage
wire [31:0] PC_plus_4;
assign PC_plus_4 = PC + 4;

wire RS_reset;
wire RS_EN;

RegStage RegStage (
    .clk(clk),
    .reset(RS_reset),

    .EN(RS_EN),

    .Instr(Instr),
    .w_PC(Inst_PC),
    .w_PC_plus_4(Inst_PC_plus_4),

    .w_R_1_num(R1_adr),
    .w_R_2_num(R2_adr),
    .w_R_1(R1),
    .w_R_2(R2),

    .R_1(RS_R1),
    .R_2(RS_R2),
    .R_1_num(RS_R_1_num),
    .R_2_num(RS_R_2_num),
    .DR_num(RS_DR_num),

    //.w_DR_num(RS_DR_num),

    .ImmExt(RS_ImmExt),

    .PC(RS_PC),
    .PC_plus_4(RS_PC_plus_4),

    .ResultSrc(RS_ResultSrc),
    .MemWrite(RS_MemWrite),
    .ALUSrc(RS_ALUSrc),
    .RegWrite(RS_RegWrite),
    .Jump(RS_Jump),
    .Branch(RS_Branch),
    .ALUControl(RS_ALUControl),
    .MemRead(RS_MemRead)
);

wire [31:0] RS_R1;
wire [31:0] RS_R2;
wire [4:0] RS_R_1_num;
wire [4:0] RS_R_2_num;
wire [4:0] RS_DR_num;

wire [31:0] RS_ImmExt/* verilator public */;

wire [31:0] RS_PC;
wire [31:0] RS_PC_plus_4;

wire [1:0] RS_ResultSrc;
wire RS_MemWrite;
wire RS_ALUSrc;
wire RS_RegWrite;
wire RS_Jump;
wire RS_Branch;
wire [3:0] RS_ALUControl;
wire RS_MemRead;

// ALU Stage
wire ALU_reset;
wire ALU_EN;

wire [31:0] ALUResData;
//wire [31:0] DataReadData;

reg [1:0] R_1_solve;
reg [1:0] R_2_solve;

ALUStage ALUStage(
    .reset(ALU_reset),
    .clk(clk),

    .EN(ALU_EN),

    .w_PC(RS_PC),
    .w_PC_plus_4(RS_PC_plus_4),

    .w_R_1(RS_R1),
    .w_R_2(RS_R2),
    .w_ImmExt(RS_ImmExt),

    .w_R_1_num(RS_R_1_num),
    .w_R_2_num(RS_R_2_num),
    .w_DR_num(RS_DR_num),

    .ALUResData(ALUResData),
    .DataReadData(DR),

    .R_1_solve(R_1_solve),
    .R_2_solve(R_2_solve),

    .DR(ALUResData),
    .DR_num(ALU_DR_num),

    .WriteData(ALU_WriteData),

    .PC(ALU_PC),
    .PC_plus_4(ALU_PC_plus_4),
    .PCTarget(ALU_PCTarget),
    .PCSrc(ALU_PCSrc),

    .w_ResultSrc(RS_ResultSrc),
    .w_MemWrite(RS_MemWrite),
    .w_ALUSrc(RS_ALUSrc),
    .w_RegWrite(RS_RegWrite),
    .w_Jump(RS_Jump),
    .w_Branch(RS_Branch),
    .w_ALUControl(RS_ALUControl),
    .w_MemRead(RS_MemRead),

    .ResultSrc(ALU_ResultSrc),
    .MemWrite(ALU_MemWrite),
    .RegWrite(ALU_RegWrite),
    .MemRead(ALU_MemRead),
    .ALUControl(ALU_ALUControl)
);

wire [4:0] ALU_DR_num;
wire [31:0] ALU_WriteData;

wire [31:0] ALU_PC;
wire [31:0] ALU_PC_plus_4;
wire [31:0] ALU_PCTarget;
wire ALU_PCSrc;

wire [1:0] ALU_ResultSrc;
wire ALU_MemWrite;
wire ALU_RegWrite;
wire ALU_MemRead;
wire [2:0] ALU_ALUControl;

// DataStage
wire DS_reset;
wire DS_EN;

DataStage DataStage(
    .reset(DS_reset),
    .clk(clk),

    .EN(DS_EN),

    .w_DR_num(ALU_DR_num),
    .w_PC_plus_4(ALU_PC_plus_4),

    .w_ALUResData(ALUResData),
    
    .MemAssert(MemAssert),

    .w_ReadData(ex_MemData),
    .ReadData(DS_ReadData),

    .ALUResData(DS_ALUResData),
    .PC_plus_4(DS_PC_plus_4),
    .DR_num(DS_DR_num),

    .w_ResultSrc(ALU_ResultSrc),
    .w_MemWrite(ALU_MemWrite),
    .w_RegWrite(ALU_RegWrite),
    .w_MemRead(ALU_MemRead),

    .ResultSrc(DS_ResultSrc),
    .RegWrite(DS_RegWrite)
);

wire MemAssert;

wire [31:0] DS_ReadData;
wire [31:0] DS_ALUResData;
wire [31:0] DS_PC_plus_4;
wire [4:0] DS_DR_num;

wire [1:0] DS_ResultSrc;
wire DS_RegWrite;

assign WriteMemEN = ALU_MemWrite;
assign ReadMemEN = ~ALU_MemWrite;



endmodule