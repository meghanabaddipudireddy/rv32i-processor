import risc32i_pkg::*;

module imm_gen (
    input logic [31:0] in,
    input  logic [6:0]  opcode,
    output logic [31:0] out
);

always_comb begin
    out = 32'b0;
    case(opcode)
        I_TYPE,
        LOAD:
            out = {{20{in[31]}}, in[31:20]};
        STORE:
            out = {{20{in[31]}}, in[31:25], in[11:7]};
        BRANCH:
            out = {{20{in[31]}}, in[7], in[30:25], in[11:8], 1'b0};
        
        default: out = 32'b0;
    endcase
end

endmodule 