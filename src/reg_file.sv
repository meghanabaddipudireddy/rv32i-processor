module reg_file(
    input logic clk,
    input logic rst,
    input logic reg_write,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data_1,
    output logic [31:0] rd_data_2
);
    //array of registers
    logic [31:0] registers [0:31];

    //read data outputs(x0 is 0)
    assign rd_data_1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign rd_data_2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    //write if reg_write is 1
    always_ff @(posedge clk) begin
        if (reg_write) begin
            registers[rd] <= wr_data;
        end
    end

endmodule