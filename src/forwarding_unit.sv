module forwarding_unit (
    input logic [4:0] id_ex_rs1,
    input logic [4:0] id_ex_rs2,
    input logic [4:0] ex_mem_rd,
    input logic ex_mem_reg_write,
    input logic [4:0] mem_wb_rd,
    input logic mem_wb_reg_write,
    output logic [1:0] forwarding_a,
    output logic [1:0] forwarding_b
);

    always_comb begin
        forwarding_a = 2'b00;
        forwarding_b = 2'b00;

        if(ex_mem_reg_write && id_ex_rs1 == ex_mem_rd && ex_mem_rd != 5'b0) begin
            forwarding_a = 2'b01;
        end
        else if (mem_wb_reg_write && id_ex_rs1 == mem_wb_rd && ex_mem_rd != 5'b0) begin
            forwarding_a = 2'b10;
        end

        if(ex_mem_reg_write && id_ex_rs2 == ex_mem_rd && ex_mem_rd != 5'b0) begin
            forwarding_b = 2'b01;
        end
        else if (mem_wb_reg_write && id_ex_rs2 == mem_wb_rd && ex_mem_rd != 5'b0) begin
            forwarding_b = 2'b10;
        end
    end

endmodule