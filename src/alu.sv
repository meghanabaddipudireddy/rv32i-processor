import risc32i_pkg::*;

module alu(
    input logic [31:0] rd_1,
    input logic [31:0] rd_2,
    input logic [3:0] alu_op,
    output logic zero,
    output logic [31:0] result
);

    always_comb begin
        result = 32'b0;
        zero = 1'b0;

        case (alu_op)
            ALU_ADD: result = rd_1 + rd_2;
            ALU_SUB: result = rd_1 - rd_2;
            ALU_AND: result = rd_1 & rd_2;
            ALU_OR: result = rd_1 | rd_2;
            ALU_XOR: result = rd_1 ^ rd_2;
            ALU_SLL: result = rd_1 << rd_2[4:0];
            ALU_SRL: result = rd_1 >> rd_2[4:0];
            ALU_SRA: result = $signed(rd_1) >>> rd_2;
            ALU_SLT: result = ($signed(rd_1) < $signed(rd_2)) ? 32'd1 : 32'd0;
        endcase

        zero = (result == 32'b0);
    end
    
endmodule
