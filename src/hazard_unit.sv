module hazard_unit (
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] id_ex_rd,
    input  logic id_ex_reg_write,
    input  logic [4:0] ex_mem_rd,     // destination in MEM stage
    input  logic ex_mem_reg_write,
    output logic pc_write,      // 0 = freeze PC
    output logic if_id_write,   // 0 = freeze IF/ID register
    output logic bubble         // 1 = insert NOP into ID/EX
);

    always_comb begin
        if ((id_ex_reg_write  && id_ex_rd  != 5'b0 && (id_ex_rd  == rs1 || id_ex_rd  == rs2)) ||
            (ex_mem_reg_write && ex_mem_rd != 5'b0 && (ex_mem_rd == rs1 || ex_mem_rd == rs2))) begin    
            pc_write = 0;
            if_id_write = 0;
            bubble = 1;
        end
        else begin
            pc_write = 1;
            if_id_write = 1;
            bubble = 0;
        end
    end

endmodule