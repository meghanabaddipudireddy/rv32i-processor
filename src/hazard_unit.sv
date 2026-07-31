module hazard_unit (
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] id_ex_rd,
    input logic id_ex_mem_read,
    output logic pc_write,      // 0 = freeze PC
    output logic if_id_write,   // 0 = freeze IF/ID register
    output logic bubble         // 1 = insert NOP into ID/EX
);

    always_comb begin
        pc_write = 1;
        if_id_write = 1;
        bubble = 0;

        if (id_ex_mem_read && (id_ex_rd == rs1 || id_ex_rd == rs2) && id_ex_rd != 5'b0) begin
            pc_write = 0;
            if_id_write = 0;
            bubble = 1;
        end
    end

endmodule
