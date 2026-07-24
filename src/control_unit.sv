import risc32i_pkg::*;

module control_unit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic zero,
    output logic reg_write,
    output logic alu_src,
    output logic mem_write,
    output logic mem_read,
    output logic mem_to_reg,
    output logic pc_src,
    output logic [3:0] alu_op
);

    always_comb begin
        
        reg_write  = 0;
        alu_src    = 0;
        mem_write  = 0;
        mem_read   = 0;
        mem_to_reg = 0;
        pc_src     = 0;
        alu_op     = ALU_ADD;

        case(opcode)
            R_TYPE: begin
                reg_write = 1;
                alu_src = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                pc_src = 0;
                case (funct3)
                    3'h0: alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
                    3'h4: alu_op = ALU_XOR;
                    3'h6: alu_op = ALU_OR;
                    3'h7: alu_op = ALU_AND;
                    3'h1: alu_op = ALU_SLL;
                    3'h5: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'h2: alu_op = ALU_SLT;
                    default: alu_op = ALU_ADD;
                endcase
            end
            I_TYPE: begin
                reg_write = 1;
                alu_src = 1;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                pc_src = 0;
                case (funct3)
                    3'h0: alu_op = ALU_ADD;   // ADDI
                    3'h4: alu_op = ALU_XOR;   // XORI
                    3'h6: alu_op = ALU_OR;    // ORI
                    3'h7: alu_op = ALU_AND;   // ANDI
                    3'h1: alu_op = ALU_SLL;   // SLLI
                    3'h5: alu_op = funct7[5] ? ALU_SRA : ALU_SRL; // SRAI : SRLI
                    3'h2: alu_op = ALU_SLT;   // SLTI
                    default: alu_op = ALU_ADD;
                endcase
            end

            LOAD: begin
                reg_write = 1;
                alu_src = 1;
                mem_write = 0;
                mem_read = 1;
                mem_to_reg = 1;
                pc_src = 0;
                alu_op = ALU_ADD;
            end

            STORE: begin
                reg_write = 0;
                alu_src = 1;
                mem_write = 1;
                mem_read = 0;
                mem_to_reg = 0;
                pc_src = 0;
                alu_op = ALU_ADD;
            end

            BRANCH: begin
                reg_write = 0;
                alu_src = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                pc_src = zero;
                alu_op = ALU_SUB;
            end
            default : begin
                reg_write  = 0;
                alu_src    = 0;
                mem_write  = 0;
                mem_read   = 0;
                mem_to_reg = 0;
                pc_src     = 0;
                alu_op     = ALU_ADD;
            end
        endcase

    end

endmodule
