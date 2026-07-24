module instr_mem (
    input logic [31:0] pc,
    output logic [31:0] instr
);

    logic [31:0] mem [0:255];

    // for testing
    initial $readmemh("program.hex", mem);

    assign instr = mem[pc[31:2]];
endmodule