# RV32I Pipelined Processor — SystemVerilog Implementation
NOTE: CHECK BRANCH-FLUSH BRACNH FOR FULLY UPDATED PROCESSOR (CURRENTLY SPLIT UP FOR TESTING)

A 5-stage pipelined RISC-V 32-bit processor implemented in SystemVerilog, targeting FPGA synthesis in Vivado. Implements data forwarding, load-use hazard detection with stalling, and branch flush for correct pipeline execution.

---

## Status

- [x] Single-cycle datapath
- [x] 5-stage pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
- [x] Load-use hazard detection + stalling
- [x] Data forwarding (EX→EX, MEM→EX)
- [x] Branch flush
- [ ] FPGA synthesis + timing analysis (Vivado)

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

### 5-Stage Pipeline

The processor is split into five stages. Each stage is separated by a pipeline register — a set of flip-flops that hold the signals produced by one stage until the next stage is ready to consume them. This allows multiple instructions to be in-flight simultaneously, one per stage, improving throughput.

```
   IF          ID           EX          MEM          WB
┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐
│ IMEM │→IF/ID→REGFILE│→ID/EX→│ ALU  │→EX/MEM→│ DMEM │→MEM/WB→REGFILE
└──────┘    └──────┘    └──────┘    └──────┘    └──────┘
   ↑            ↑           ↑           ↑           ↑
  PC+4       Decode      Execute      Memory     Writeback
```

**IF — Instruction Fetch:** PC drives instruction memory, fetches the 32-bit instruction word. PC advances to PC+4 every cycle unless stalled or branching.

**ID — Instruction Decode:** Reads source registers from the register file. Immediate generator extracts and sign-extends the immediate. Control unit decodes the opcode and generates all control signals. Everything gets captured into the ID/EX pipeline register.

**EX — Execute:** ALU computes the result using forwarded or register-file values. Forwarding muxes select the correct data source. Branch target is computed here.

**MEM — Memory:** Data memory is read (LW) or written (SW) using the ALU result as the address. For non-memory instructions this stage passes the ALU result through unchanged.

**WB — Writeback:** Selects between memory read data and ALU result (MemtoReg mux) and writes back to the destination register.

---

## Pipeline Registers

Each pipeline register is implemented as a SystemVerilog packed struct, making signal grouping explicit and allowing the entire register to be cleared with a single `<= '0` assignment.

| Register | Contents |
|---|---|
| IF/ID | PC, instruction word |
| ID/EX | PC, rd_data_1, rd_data_2, immediate, rs1, rs2, rd, all control signals |
| EX/MEM | ALU result, rd_data_2, rd, zero flag, reg_write, mem_write, mem_read, mem_to_reg, pc_src |
| MEM/WB | mem_read_data, ALU result, rd, reg_write, mem_to_reg |

Control signals travel with the instruction through the pipeline — each stage reads the control signals it needs from the appropriate pipeline register rather than re-decoding the instruction.

---

## Hazard Detection and Stalling

### The Problem

A RAW (Read After Write) data hazard occurs when an instruction needs a register value that a previous instruction hasn't finished computing yet. Without any mitigation, the pipeline would read a stale value from the register file and produce wrong results.

### Load-Use Hazard — the one case that still requires a stall

With data forwarding handling most RAW hazards, the only case that still requires a stall is the **load-use hazard** — when a LW instruction is immediately followed by an instruction that needs the loaded value:

```
LW  x1, 0(x0)      ← result not available until end of MEM stage
ADD x2, x1, x3     ← needs x1 in EX stage — too early to forward
```

The loaded value doesn't exist until the end of the MEM stage, which is one cycle too late to forward to the very next instruction's EX stage. One stall cycle is inserted to create the necessary gap.

### How stalling works

The hazard detection unit detects load-use hazards by checking:

```
id_ex_reg.mem_read == 1  (a LW is in EX stage)
AND
id_ex_reg.rd matches rs1 or rs2 of the instruction in ID
```

When a hazard is detected, three things happen simultaneously:

- **pc_write = 0** — the PC is frozen, it does not advance. The same instruction gets fetched again next cycle.
- **if_id_write = 0** — the IF/ID register is frozen, it does not update. The same instruction stays in the decode stage.
- **bubble = 1** — the ID/EX register is cleared to all zeros, inserting a NOP into the execute stage. This creates a one-cycle gap that lets the LW result propagate to MEM/WB before the dependent instruction reaches EX.

After one stall cycle, forwarding takes over and routes the loaded value from MEM/WB directly to the ALU.

---

## Data Forwarding

### The Problem

Most RAW hazards don't require a stall — the result exists somewhere in the pipeline, just not yet written back to the register file. Forwarding routes that result directly to where it's needed without waiting.

### Forwarding Paths

**EX→EX forwarding** — the most common case. The instruction one ahead has its result sitting in the EX/MEM pipeline register. That result is forwarded directly to the ALU input this cycle:

```
cycle N:   ADD x1, x2, x3     ← result in EX/MEM register
cycle N+1: ADD x4, x1, x5     ← needs x1 in EX, gets it from EX/MEM
```

**MEM→EX forwarding** — two instructions back. The result is in the MEM/WB pipeline register and gets forwarded to the current EX stage:

```
cycle N:   ADD x1, x2, x3     ← result in MEM/WB register
cycle N+1: ADD x5, x6, x7     ← unrelated instruction
cycle N+2: ADD x4, x1, x5     ← needs x1 in EX, gets it from MEM/WB
```

EX→EX takes priority over MEM→EX if both would match — the more recent result is always correct.

### How forwarding works

The forwarding unit is a pure combinational module. It compares the source register addresses of the instruction in EX against the destination register addresses of instructions in MEM and WB stages, and outputs two 2-bit select signals:

```
forward_a / forward_b:
    2'b00 → no forwarding, use register file value from ID/EX
    2'b01 → EX→EX, use ex_mem_reg.alu_result
    2'b10 → MEM→EX, use writeback value from MEM/WB
```

These signals drive 3-way muxes at the ALU inputs. For ALU input B, the forwarding mux output then feeds into the ALUSrc mux so that the immediate can still override when needed.

Forwarding never fires on x0 — writes to x0 are meaningless since it's hardwired to zero, so x0 is excluded from all forwarding comparisons.

---

## Branch Flush

### The Problem

When a branch instruction is executing in the EX stage, the processor has already fetched two more instructions from sequential memory addresses — the instructions immediately after the branch in the program. If the branch is taken, those two instructions should never execute. They need to be thrown away.

```
cycle 1: BEQ x1, x2, label    ← in EX, branch resolves as taken
         wrong_instr_1         ← in ID  — should never execute
         wrong_instr_2         ← in IF  — should never execute

cycle 2: label_instr           ← now correctly fetched from branch target
         NOP (flushed)         ← was wrong_instr_1
         NOP (flushed)         ← was wrong_instr_2
```

### How branch flush works

When the branch resolves as taken (`ex_mem_reg.pc_src && ex_mem_reg.zero`), a `branch_flush` signal is asserted. This signal clears both the IF/ID and ID/EX pipeline registers to all zeros in the same cycle, replacing the two wrong instructions with NOPs.

The PC simultaneously jumps to the branch target (`pc + imm`), so the correct instruction starts being fetched the very next cycle.

The flush always discards exactly two instructions regardless of how far the branch jumps — the branch distance only affects the PC target, not the pipeline cleanup. Two instructions are always in-flight after the branch, and both always need to be discarded when the branch is taken.

For BEQ specifically, the branch condition is checked using the ALU zero flag — the ALU subtracts rs1 - rs2, and if the result is zero (operands are equal), the branch is taken.

---

## Module Hierarchy

```
rv32i_top
├── instr_mem         — ROM, loads program.hex at simulation start
├── reg_file          — 32 x 32-bit registers, 2 read ports, 1 write port
├── imm_gen           — extracts and sign-extends immediate (I/S/B-type)
├── alu               — ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT
├── data_memory       — RAM for LW/SW, word-aligned access
├── control_unit      — opcode → control signals (combinational)
├── hazard_unit       — detects load-use hazards, generates stall signals
└── forwarding_unit   — detects RAW hazards, generates forwarding mux selects

rv32i_top also contains:
├── PC register
├── IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers (packed structs)
├── PC+4 adder
├── Branch target adder
├── ALUSrc mux
├── Forwarding muxes (3-way) for ALU inputs A and B
├── MemtoReg mux
└── PCSrc mux
```

---

## File Structure

```
rv32i-processor/
├── src/
│   ├── rv32i_pkg.sv        — shared constants (opcodes, ALU ops, pipeline structs)
│   ├── rv32i_top.sv        — top level
│   ├── instr_mem.sv        — instruction memory
│   ├── reg_file.sv         — register file
│   ├── imm_gen.sv          — immediate generator
│   ├── alu.sv              — ALU
│   ├── data_memory.sv      — data memory
│   ├── control_unit.sv     — control unit
│   ├── hazard_unit.sv      — hazard detection
│   └── forwarding_unit.sv  — forwarding unit
├── tb/
│   └── rv32i_top_tb.sv     — testbench
├── program.hex             — test program
└── README.md
```

---

## Key Design Decisions

**Packed structs for pipeline registers** — each pipeline register boundary is a single packed struct, allowing the entire register to be cleared with `<= '0` for reset, stall bubbles, and branch flushes. Fields are accessed with dot notation which makes the code self-documenting.

**Forwarding eliminates most stalls** — only load-use hazards require a stall cycle. All other RAW hazards are resolved through EX→EX or MEM→EX forwarding with no pipeline penalty.

**Branch resolved in EX stage** — branch condition is evaluated in the ALU (SUB to check equality for BEQ, zero flag asserted if equal). Two instructions are always flushed on a taken branch (2-cycle branch penalty). Moving branch resolution earlier (to ID stage) would reduce this to 1 cycle but adds complexity.

**Synchronous reset throughout** — all pipeline registers and the PC use synchronous active-high reset, consistent with FPGA best practices and simplifying timing analysis.

**Word-aligned memory** — instruction and data memory use `address[31:2]` for indexing. No byte or halfword access in this implementation.

---

## How to Simulate

**1. Create program.hex** — one hex instruction per line:

```
00500093
00300113
002081B3
```


**2. Synthesize (Vivado):**
- Create project targeting Basys3 (xc7a35tcpg236-1)
- Add all src/ files
- Run synthesis and implementation
- Check timing report for fmax and utilization

---

## Potential Future Additions

**More ISA coverage** — JAL, JALR, LUI, AUIPC would make the processor capable of running real compiled C programs. BNE, BLT, BGE, BLTU, BGEU would complete the branch instruction set.

**More pipeline stages** — a deeper pipeline (7-stage, 10-stage) could improve clock frequency by breaking the critical path into smaller pieces. Each additional stage reduces the combinational depth per stage but increases the branch penalty and forwarding complexity.

**Branch prediction** — instead of always flushing on a taken branch, a branch predictor guesses the outcome and speculatively fetches from the predicted target. A simple static predictor (always predict not-taken) would reduce the branch penalty from 2 cycles to 0 on correctly predicted branches.

**Cache** — instruction and data caches between the processor and main memory would dramatically improve performance on real programs. An L1 cache miss stalls the pipeline until the data arrives from slower memory.

**Multiplication and division** — the M extension adds MUL, MULH, DIV, REM instructions. These require multi-cycle execution units since a single-cycle multiplier/divider would create an extremely long critical path.

**Out-of-order execution** — a major architectural extension that allows instructions to execute as soon as their operands are ready rather than in program order. Requires a reorder buffer (ROB) and reservation stations — significantly more complex but dramatically improves instruction-level parallelism.

---

## References

- Patterson & Hennessy — Computer Organization and Design RISC-V Edition
- RISC-V ISA Specification (riscv.org)
- RVfpga — Imagination Technologies free RISC-V FPGA course
