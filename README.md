# RV32I Processor — SystemVerilog Implementation

A single-cycle RISC-V 32-bit processor implemented in SystemVerilog, targeting FPGA synthesis in Vivado. Currently implementing the single-cycle datapath with plans to extend to a 5-stage pipeline with hazard detection and forwarding.

---

## Status

- [x] Single-cycle datapath — complete
- [x] ISA subset implemented
- [x] Pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
- [x] Hazard detection + stalling
- [x] Data forwarding
- [ ] Branch handling + pipeline flush
- [ ] FPGA synthesis + timing analysis

---

## ISA Subset

| Type | Instructions |
|---|---|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA |
| I-type | ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Load | LW |
| Store | SW |
| Branch | BEQ |

---

## Architecture

### Single-Cycle Datapath

Every instruction completes in exactly one clock cycle. The datapath flows left to right through five conceptual stages — Fetch, Decode, Execute, Memory, Writeback — with no pipeline registers between them.

```
         ┌──────────────────────────────────────────────────────────────┐
         │                                                              │
PC ──→ IMEM ──→ REGFILE ──→ [ALUSrc MUX] ──→ ALU ──→ DMEM ──→ [MemtoReg MUX] ──→ REGFILE
         │         ↑                           ↓              ↑              │
         │       WB data                     zero           DMEM           WB data
         │         └──────────────────────────────────────────┘
         │
       IMEM ──→ IMM_GEN ──────────────────────────────↗
         │
       IMEM ──→ CONTROL ──→ (RegWrite, ALUSrc, MemWrite, MemRead, MemtoReg, PCSrc, ALUop)
         │
         └──→ [PCSrc MUX] ──→ PC
                   ↑
              branch_target = PC + imm
              pc_plus4      = PC + 4
```

---

## Module Hierarchy

```
rv32i_top
├── instr_mem       — ROM, loads program from program.hex
├── reg_file        — 32 x 32-bit registers, 2 read ports, 1 write port, x0 hardwired to 0
├── imm_gen         — extracts and sign-extends immediate for I/S/B-type instructions
├── alu             — ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT
├── data_memory     — RAM for LW/SW, word-aligned
└── control_unit    — opcode → control signals (combinational)

rv32i_top also contains:
├── PC register (always_ff)
├── PC+4 adder
├── Branch target adder (PC + imm)
├── ALUSrc mux    — rs2 value vs immediate
├── MemtoReg mux  — ALU result vs memory read data
└── PCSrc mux     — PC+4 vs branch target
```

---

## File Structure

```
rv32i-processor/
├── src/
│   ├── rv32i_pkg.sv       — shared constants (opcodes, ALU op codes)
│   ├── rv32i_top.sv       — top level, wires everything together
│   ├── instr_mem.sv       — instruction memory (ROM)
│   ├── reg_file.sv        — register file
│   ├── imm_gen.sv         — immediate generator
│   ├── alu.sv             — arithmetic logic unit
│   ├── data_memory.sv     — data memory (RAM)
│   └── control_unit.sv    — control unit
│   └── hazard_unit.sv     — hazard unit

├── tb/
│   └── rv32i_top_tb.sv    — testbench
├── program.hex            — test program loaded at simulation start
└── README.md
```

---

## Control Signals

The control unit takes the opcode, funct3, and funct7 fields and generates all datapath control signals:

| Signal | Width | Description |
|---|---|---|
| reg_write | 1 | Write result to register file |
| alu_src | 1 | 0 = use rs2, 1 = use immediate |
| mem_write | 1 | Write to data memory (SW) |
| mem_read | 1 | Read from data memory (LW) |
| mem_to_reg | 1 | 0 = writeback ALU result, 1 = writeback memory data |
| pc_src | 1 | 0 = PC+4, 1 = branch target |
| alu_op | 4 | ALU operation select |

### Control signal truth table

| Instruction | reg_write | alu_src | mem_write | mem_read | mem_to_reg | pc_src | alu_op |
|---|---|---|---|---|---|---|---|
| R-type | 1 | 0 | 0 | 0 | 0 | 0 | from funct3/7 |
| I-type | 1 | 1 | 0 | 0 | 0 | 0 | from funct3 |
| LW | 1 | 1 | 0 | 1 | 1 | 0 | ADD |
| SW | 0 | 1 | 1 | 0 | — | 0 | ADD |
| BEQ | 0 | 0 | 0 | 0 | — | zero | SUB |

---

## Key Design Decisions

**Synchronous reset** — register file and PC use synchronous active-high reset, consistent with FPGA best practices.

**Word-aligned memory** — instruction and data memory use `address[31:2]` to index, dropping the bottom 2 bits. Supports word-aligned LW/SW only (no byte/halfword access in this implementation).

**x0 hardwired to zero** — register file read logic checks `rs1 == 0` and `rs2 == 0` and returns 32'b0 regardless of what is stored in `registers[0]`.

**Combinational reads** — register file and data memory reads are combinational (`assign` statements) so data is available in the same cycle it is requested. Writes are synchronous (always_ff).

**Package-based constants** — all opcodes and ALU operation codes are defined once in `rv32i_pkg.sv` and imported by every module that needs them, avoiding magic numbers throughout the design.

---

## How to Simulate

**1. Create program.hex** — one hex instruction per line:
```
00500093
00300113
002081B3
```

**2. Compile and run (Icarus Verilog):**
```bash
iverilog -g2012 -o sim src/rv32i_pkg.sv src/instr_mem.sv src/reg_file.sv \
  src/imm_gen.sv src/alu.sv src/data_memory.sv src/control_unit.sv \
  src/rv32i_top.sv tb/rv32i_top_tb.sv
vvp sim
gtkwave rv32i_top_tb.vcd
```

**3. Synthesize (Vivado):**
- Target: Basys3 (xc7a35tcpg236-1)
- Add all src/ files to project
- Run synthesis and implementation
- Check timing report for fmax and utilization

---

## Planned Extensions

### Branch Handling
Flush IF/ID and ID/EX pipeline registers when a branch is taken, preventing incorrectly-fetched instructions from completing.

---

## References

- Patterson & Hennessy — Computer Organization and Design RISC-V Edition
- RISC-V ISA Specification (riscv.org)
- RVfpga — Imagination Technologies free RISC-V FPGA course
