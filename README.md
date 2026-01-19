# SDRAM Module Design
This project includes the implementation of an SDRAM Module ( Synchronous Dynamic Random Access Memory ) in verilog and my understanding of the timing and control signals involved in the operation. It was inspired by the work found in [SDRAM_Verilog](https://github.com/yigitbektasgursoy/SDRAM_Verilog)

## Contents

1. [SDRAM Module (Behavioral)](#behavioral)
2. [SDRAM Module (Realistic)](#realistic)
3. [My Changes](#changes)
4. [Verification](#verification)
5. [To Do](#todo)
---
## SDRAM Module (Behavioral)
### Features
- **Clock (`clk`):** Clock of SDRAM chip.
- **Chip Select (`cs_n`):** Selects the SDRAM chip.
- **Write Enable (`we_n`):** Enables write operations.
- **Column Address Strobe (`cas_n`):** Activates column address.
- **Row Address Strobe (`ras_n`):** Activates row address.
- **Bank Select (`bank_select`):** Selects the memory bank.
- **SDRAM Address (`sdram_addr`):** Address bus for SDRAM.
- **SDRAM Write Data (`dq_in`):** Data bus for write operations.
- **SDRAM Read Data (`dq_out`):** Data bus for read operations.

---
## SDRAM Module (Realistic)
### Features


---
## My Changes
With the help of the work done in the repository mentioned below, I changed a few things in the algorithm of the SDRAM Module 

1. Created a testbench to initiate the commands - NOP, ACTIVATE, READ, WRITE 
2. Corrected the array size calculation of the Memory initialized in the repository: 32Mb (4MB)
3. Writes to memory are sequential, with an additional buffer to store each write at the specific address ( preventing data corruption)
4. Multiple writes can be handled correctly with the write_flag
5. Synthesizable design with the NOP counter concept (acts as tRCD for the SDRAM)


---
## Verification




---
## To Do
- **Update** - README file with Realistic module features and Verification, add simulation waveforms
