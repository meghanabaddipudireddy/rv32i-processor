package risc32i_pkg;
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;

    // RISC-V opcodes
    localparam R_TYPE  = 7'b0110011;
    localparam I_TYPE  = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam BRANCH  = 7'b1100011;

    //struct for ID/EX pipeline register
    typedef struct packed {
    logic [31:0] pc;
    logic [31:0] rd_data_1;
    logic [31:0] rd_data_2;
    logic [31:0] imm;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic        reg_write;
    logic        alu_src;
    logic        mem_write;
    logic        mem_read;
    logic        mem_to_reg;
    logic        pc_src;
    logic [3:0]  alu_op;
    } id_ex_t;

    //struct for EX/MEM pipeline register
    typedef struct packed {
    logic [31:0] alu_result;
    logic [31:0] rd_data_2;   
    logic [4:0]  rd;
    logic        zero;
    logic        reg_write;
    logic        mem_write;
    logic        mem_read;
    logic        mem_to_reg;
    logic        pc_src;
    } ex_mem_t;

    //struct for MEM/WB pipeline register
    typedef struct packed {
    logic [31:0] mem_read_data;
    logic [31:0] alu_result;
    logic [4:0]  rd;
    logic        reg_write;
    logic        mem_to_reg;
    } mem_wb_t;

endpackage

