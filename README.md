# Design-and-Verification-of-an-LC-3-Microcontroller-Using-SV-Testbench-and-Bubble-Sort-Execution
Implemented the LC-3 microcontroller in SystemVerilog, including control unit, datapath, and memory. Verified each block with directed testbenches, then validated the full system using a SystemVerilog test environment (generator, monitor, scoreboard etc). Ran bubble sort firmware in LC-3 assembly to show correct execution.

# Repository layout:
## Assembly_Program_BubbleSort
Contains the LC-3 assembly program for the **bubble sort** algorithm.  
- Includes `.asm` source and assembled `.hex` / `.mem` files.  
- Program starts at `.ORIG x3000`.  
- Data memory map:
  - `x3FFE` → length of array (N)  
  - `x3FFF` → DONE flag (set to `1` when sort completes)  
  - `x4000..` → array base address  
- Used as the firmware workload to validate the complete LC-3 processor.

## Control_Signals
Defines the **microcode control store** that drives the LC-3.  
- Stored as a CSV file describing each microinstruction (52-bit wide).  
- Key fields: `IRD`, `COND`, `J`, loads (`LD_*`), gates (`Gate*`), mux selects, ALU op, and memory controls.  
- Each row corresponds to a microstate in the controller.  
- This ensures proper sequencing of fetch, decode, execute, memory access, and writeback.

## Control_Unit
Implements the **control logic** of the LC-3.  
- Components:
  - **Microsequencer**: determines the next microstate using `IRD`, `COND`, `J`, and status inputs (`BEN`, `Ready`, `IR[11]`, etc.).  
  - **Control Store**: ROM initialized from `Control_Signals` CSV.  
  - **Decoder**: expands the 52-bit microinstruction into named control signals.  
- Responsible for coordinating all datapath, memory, and register operations.

## Memory_Unit
Implements the **LC-3 memory subsystem**.  
- `memory.sv`: parameterizable synchronous RAM (instruction + data).  
- `memory_control.sv`: manages MAR, MDR, and handshake with control signals.  
- Behavior:
  - `LD_MAR` loads MAR from bus.  
  - `LD_MDR` loads MDR from memory or bus.  
  - `MIO.EN` + `R/W` initiate single-cycle read/write pulses.  
  - `Ready` indicates data availability for reads.  
- Fully compliant with LC-3 memory protocol.

## Processing_Unit
Implements the **datapath (execution unit)** of the LC-3.  
- Components:
  - Register file (R0–R7)  
  - ALU (ADD, AND, NOT, etc.)  
  - Shifter  
  - Program Counter (PC) and Incrementer  
  - Instruction Register (IR) and NZP flags  
  - Address adders and multiplexers  
- Executes instructions under the control signals from the Control Unit.

### SV_Test_Env/

The **SystemVerilog test environment** verifies the LC-3 at the system level by running the bubble sort assembly program and checking its correctness against a golden reference model.  
It is built from modular components, each serving a specific role:

- **generator.sv**  
  Produces abstract transactions (e.g., instruction/data requests) that stimulate the DUT.  
  In this setup, the generator provides initial sequences and helps drive corner cases if needed.

- **driver.sv**  
  Interfaces directly with the DUT inputs.  
  It takes items from the generator and applies them to the LC-3 (e.g., program/data loading, reset sequences).

- **monitor.sv**  
  Passively observes signals of interest from the DUT (e.g., instruction fetch, program counter, memory operations).  
  It forwards this information to the scoreboard and checker for later comparison and logging.

- **scoreboard.sv**  
  Records the **program counter (PC) values** at each instruction fetch stage.  
  This provides a complete trace of instruction execution and is used to validate whether the program is flowing as expected.

- **lc3_checker.sv**  
  Implements a **golden reference model** of the LC-3 instruction set.  
  For each executed instruction, it compares the DUT’s state (registers, memory, PC) with the expected state from the reference.  
  Any mismatches are reported as functional errors.

- **mem_tap.sv**  
  Observes and logs memory transactions.  
  It includes an **assertion** that flags **consecutive writes to the same memory address**, which helps debug incorrect swap/overwrite behavior during the bubble sort execution.  
  This is particularly useful for catching bugs in `STR` or memory addressing logic.

- **env.sv**  
  The top-level environment module.  
  It instantiates the generator, driver, monitor, scoreboard, checker, and memory tap, and connects them via mailboxes/interfaces to enable transaction-level communication.

- **test.sv**  
  The main testbench file.  
  - Instantiates the LC3_Top (the DUT).  
  - Instantiates `env.sv` to bring together all verification components.  
  - Loads the **bubble sort assembly program** into memory.  
  - Manages the simulation (reset, clock, run, end condition).  
  - Final verdict is reported when the DONE flag is set in memory.

---

Together, these files form a lightweight **SystemVerilog test environment (not UVM)** that:  
1. Stimulates the LC-3 design,  
2. Observes its behavior,  
3. Checks execution against a golden reference,  
4. Logs instruction flow (via PC tracing), and  
5. Flags memory hazards (via assertions in mem_tap).  


  

