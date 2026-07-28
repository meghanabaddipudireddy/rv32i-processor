module top (
    input logic clk,
    input logic rst
);

    //program counter wires
    logic [31:0] pc;
    logic [31:0] pc_4;
    logic [31:0] branch_target;
    logic [31:0] next_pc;

    //instruction memory
    logic [31:0] instr;

    //register file wires
    logic [31:0] rd_data_1;
    logic [31:0] rd_data_2;

    //immediate
    logic [31:0] imm_out;

    //ALU wires
    logic zero;
    logic [31:0] alu_res;
    logic [31:0] alu_input_b;

    //data memory wires
    logic [31:0] mem_read_data;

    // writeback
    logic [31:0] writeback;

    // control signals
    logic        reg_write;
    logic        alu_src;
    logic        mem_write;
    logic        mem_read;
    logic        mem_to_reg;
    logic        pc_src;
    logic [3:0]  alu_op;

    //pc logic
    always_ff @(posedge clk) begin
        if 
            (rst) pc <= 32'b0;
        else
            pc <= next_pc;
    end

    assign pc_4 = pc + 32'd4;
    assign branch_target = (imm_out << 1) + pc_4;
    assign next_pc = pc_src ? branch_target : pc_4;

    //muxes
    assign alu_input_b = alu_src ? imm_out : rd_data_2;
    assign writeback = mem_to_reg ? mem_read_data : alu_res;

    //instantiations
    instr_mem u_instr_mem (.pc(pc), .instr(instr));
    reg_file u_reg_file (.clk(clk), .rst(rst), .reg_write(reg_write), .rs1(instr[19:15]),.rs2(instr[24:20]), .rd(instr[11:7]), .wr_data(writeback), .rd_data_1(rd_data_1), .rd_data_2(rd_data_2));
    imm_gen u_imm_gen(.in(instr),.opcode(instr[6:0]),.out(imm_out));
    alu u_alu(.rd_1(rd_data_1), .rd_2(alu_input_b), .alu_op(alu_op), .zero(zero), .result(alu_res));
    data_memory u_data_memory( .clk(clk), .address(alu_res), .wr_data(rd_data_2), .mem_write(mem_write), .mem_read(mem_read), .read_data(mem_read_data));
    control_unit u_control_unit(.opcode(instr[6:0]), .funct3(instr[14:12]), .funct7(instr[31:25]), .zero(zero), .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write), .mem_read(mem_read), .mem_to_reg(mem_to_reg), .pc_src(pc_src), .alu_op(alu_op));

endmodule
