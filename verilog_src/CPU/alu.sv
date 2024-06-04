module alu (
    input [2:0] ALUControl,
    input [31:0] SrcA, 
    input [31:0] SrcB,

    output Zero,
    output reg [31:0] ALUResult
);

    always_comb begin
        case (ALUControl)
        //Arithmetic
        3'b000: ALUResult = SrcA + SrcB;                                // Addition
        3'b001: ALUResult = SrcA - SrcB;                                // Substraction
        
        //Logic
        3'b010: ALUResult = SrcA & SrcB;                                // AND
        3'b011: ALUResult = SrcA | SrcB;                                // OR
        3'b100: ALUResult = SrcA ^ SrcB;                                // XOR
        //Compare
        3'b101: ALUResult = $signed(SrcA) < $signed(SrcB)? 1 : 0;       // SLT
        //3'b0011: ALUResult = $unsigned(SrcA) < $unsigned(SrcB)? 1 : 0;   //SLTU

        //Shift
        // 4'b0001: ALUResult = SrcA << SrcB;                               //SLL
        // 4'b0101: ALUResult = SrcA >> SrcB;                               //SRL
        // 4'b1101: ALUResult = $signed(SrcA) >> SrcB;                      //SRA
        //nothing
        // 4'b1111: ALUResult = SrcB;                                       //imm
        default: ALUResult = 32'bx;
        endcase
    end
    
    assign Zero = (ALUResult == 32'b0);

endmodule