module data_memory (
    input logic clk,
    input logic [31:0] address,
    input logic [31:0] wr_data,
    input logic mem_write,
    input logic mem_read,
    output logic [31:0]read_data
);

    //memory
    logic [31:0] mem [0:255];

    //risc-v uses byte addresses but currently using word based address so have to shift right 2 to get the word index
    always_ff @(posedge clk) begin
        if(mem_write) begin
            mem[address[31:2]] <= wr_data;
        end
    end

    assign read_data = mem_read ? mem[address[31:2]] : 32'b0;

endmodule
