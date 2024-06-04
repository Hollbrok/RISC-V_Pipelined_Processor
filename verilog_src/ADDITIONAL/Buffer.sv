module latch
    #(parameter DATA_SIZE = `DWORD_BITS)
(
    input logic clk,
    input logic clr,
    input logic en,
    input logic  [DATA_SIZE - 1:0] input,
    output logic [DATA_SIZE - 1:0] output
);

    logic [DATA_SIZE - 1:0] buffer;
    assign output = buffer;

    always_ff @(posedge clk)
    begin
        if (en && !clr)
            buffer <= input;
        else if (clr)
            buffer <= 0;
    end

endmodule