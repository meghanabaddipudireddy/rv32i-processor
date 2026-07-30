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
    assign branch_target = id_ex_reg.pc + id_ex_reg.imm;
    assign next_pc = (ex_mem_reg.pc_src && ex_mem_reg.zero) ? branch_target : pc_4;

    //muxes
    assign alu_input_b = id_ex_reg.alu_src ? id_ex_reg.imm : id_ex_reg.rd_data_2;
    assign writeback = mem_wb_reg.mem_to_reg ? mem_wb_reg.mem_read_data : mem_wb_reg.alu_result;

    //pipeline registers

    //IF/ID pipeline register
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr; 
    always_ff @(posedge clk) begin
        if(rst) begin
            if_id_pc <= 0;
            if_id_instr <= 0;
        end
        else begin
            if_id_pc <= pc;
            if_id_instr <= instr;
        end
    end

    //ID/EX register
    id_ex_t id_ex_reg;
    always_ff @(posedge clk) begin
        if(rst) begin
            id_ex_reg <= '0;
        end
        else begin
            id_ex_reg.pc <= if_id_pc;
            id_ex_reg.rd_data_1 <= rd_data_1;
            id_ex_reg.rd_data_2 <= rd_data_2;
            id_ex_reg.imm <= imm_out;
            id_ex_reg.rs1 <= if_id_instr[19:15];
            id_ex_reg.rs2 <= if_id_instr[24:20];
            id_ex_reg.rd <= if_id_instr[11:7];
            id_ex_reg.reg_write <= reg_write;
            id_ex_reg.alu_src <= alu_src;
            id_ex_reg.mem_write <= mem_write;
            id_ex_reg.mem_read <= mem_read;
            id_ex_reg.mem_to_reg <= mem_to_reg;
            id_ex_reg.pc_src <= pc_src;
            id_ex_reg.alu_op <= alu_op;
        end
    end

    //EX/MEM Register
    ex_mem_t ex_mem_reg;
    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_reg <= '0;
        end
        else begin
            ex_mem_reg.alu_result <= alu_res;
            ex_mem_reg.rd_data_2 <= id_ex_reg.rd_data_2;
            ex_mem_reg.rd <= id_ex_reg.rd;
            ex_mem_reg.zero <= zero;
            ex_mem_reg.reg_write <= id_ex_reg.reg_write;
            ex_mem_reg.mem_write <= id_ex_reg.mem_write;
            ex_mem_reg.mem_read <= id_ex_reg.mem_read;
            ex_mem_reg.mem_to_reg <= id_ex_reg.mem_to_reg;
            ex_mem_reg.pc_src <= id_ex_reg.pc_src;
        end
    end

    //MEM/WB Register
    mem_wb_t mem_wb_reg;
    always_ff @(posedge clk) begin
        if(rst) begin
            mem_wb_reg <= '0;
        end
        else begin
            mem_wb_reg.mem_read_data <= mem_read_data;
            mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
            mem_wb_reg.rd <= ex_mem_reg.rd;
            mem_wb_reg.reg_write <= ex_mem_reg.reg_write;
            mem_wb_reg.mem_to_reg <= ex_mem_reg.mem_to_reg;
        end
    end

    //instantiations
    instr_mem u_instr_mem (.pc(pc), .instr(instr));
    reg_file u_reg_file (.clk(clk), .rst(rst), .reg_write(mem_wb_reg.reg_write), .rs1(if_id_instr[19:15]),.rs2(if_id_instr[24:20]), .rd(mem_wb_reg.rd), .wr_data(writeback), .rd_data_1(rd_data_1), .rd_data_2(rd_data_2));
    imm_gen u_imm_gen(.in(if_id_instr),.opcode(if_id_instr[6:0]),.out(imm_out));
    alu u_alu(.rd_1(id_ex_reg.rd_data_1), .rd_2(alu_input_b), .alu_op(id_ex_reg.alu_op), .zero(zero), .result(alu_res));
    data_memory u_data_memory( .clk(clk), .address(ex_mem_reg.alu_result), .wr_data(ex_mem_reg.rd_data_2), .mem_write(ex_mem_reg.mem_write), .mem_read(ex_mem_reg.mem_read), .read_data(mem_read_data));
    control_unit u_control_unit(.opcode(if_id_instr[6:0]), .funct3(if_id_instr[14:12]), .funct7(if_id_instr[31:25]), .zero(zero), .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write), .mem_read(mem_read), .mem_to_reg(mem_to_reg), .pc_src(pc_src), .alu_op(alu_op));

    //hello
endmodule
