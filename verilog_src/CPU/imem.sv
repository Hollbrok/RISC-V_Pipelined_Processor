module imem(
    input logic [31:0] a,
    output logic [31:0] rd
);

    logic [31:0] RAM[65535:0]/* verilator public */;

    assign rd = RAM[a[17:2]]; // word aligned
endmodule
