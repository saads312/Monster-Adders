# Monster Adders: High-Frequency 2048-bit Adders on Intel Agilex 5 FPGAs

A high-performance FPGA implementation of 2048-bit binary adders optimized for maximum clock frequency on Intel Agilex 5 devices. This project explores and compares two distinct architectural approaches: a conventional pipelined adder and an advanced prefix-tree based design inspired by "monster adder" techniques.

## Overview

Adding very wide integers (2048 bits) at high frequencies on FPGAs presents significant challenges due to long carry propagation chains. This project targets Intel Agilex 5 FPGAs and leverages their advanced Logic Array Block (LAB) architecture with built-in dedicated carry chains for optimal performance.

The project implements and compares two solutions:

1. **Naive Adder**: A straightforward pipelined carry-select adder (CSA) design that exploits LAB carry chains
2. **Clever Adder**: An optimized Type-2 architecture using parallel prefix trees for faster carry computation, minimizing reliance on long carry chains

Both designs are fully parameterized and include comprehensive testbenches and FPGA synthesis flows specifically tuned for Agilex 5's ALM (Adaptive Logic Module) and LAB structures.

## Architecture

### Type-2 "Clever" Adder

The clever adder uses a three-stage pipeline to minimize critical path delay:

```
Stage 1: Chunk Addition
  - Split 2048-bit inputs into M-bit chunks
  - Compute each chunk twice: with carry-in=0 (Generate) and carry-in=1 (Propagate)

Stage 2: Prefix Tree
  - Use Kogge-Stone prefix network to compute actual carries between chunks
  - Logarithmic depth: O(log N) where N = 2048/M

Stage 3: Final Selection
  - Select correct sum for each chunk based on computed carries
  - Combine chunks into final 2048-bit result
```

This approach achieves higher Fmax by replacing long ripple-carry chains with a parallel prefix tree structure, better exploiting Agilex 5's parallel routing resources while minimizing pressure on the dedicated carry chains.

### Naive Adder

Uses a parameterized carry-select adder with pipelining for comparison baseline. This design makes direct use of Agilex 5's efficient LAB carry chain implementation for ripple-carry propagation within chunks.

## Project Structure

```
Monster-Adders/
├── rtl/                    # RTL source files
│   ├── naiveadder2048b.sv  # Naive pipelined adder
│   ├── cleveradder2048b.sv # Type-2 prefix tree adder
│   ├── prefix_tree.sv      # Kogge-Stone prefix network
│   ├── rca.sv              # Ripple-carry adder (building block)
│   └── csa_pipe.sv         # Carry-select adder (building block)
├── tb/                     # Testbench files
│   ├── test_adder.sv       # SystemVerilog testbench for adders
│   ├── test_prefix_tree.sv # Testbench for prefix tree
│   ├── test.cpp            # C++ Verilator test harness
│   └── tb_base.h           # Test infrastructure
├── data/                   # Test vector generation
│   ├── generate_adder_data.py       # Generate random/exhaustive test cases
│   └── generate_prefix_tree_data.py # Generate prefix tree test cases
├── fpga/                   # FPGA synthesis scripts
│   ├── setup.tcl           # Quartus project setup
│   ├── synth.tcl           # Synthesis flow
│   └── impl.tcl            # Place & route flow
├── results/                # Performance results
│   ├── winner_naive.csv    # Best naive design metrics
│   └── winner_clever.csv   # Best clever design metrics
├── Makefile               # Build automation
├── naive.sh               # Run naive adder optimization
├── clever.sh              # Run clever adder optimization
├── sweep_naive.sh         # Parameter sweep for naive design
├── sweep_clever.sh        # Parameter sweep for clever design
└── extract.sh             # Extract timing/area metrics from FPGA reports
```

## Requirements

- **Simulation**: Verilator (for functional verification)
- **Synthesis**: Intel Quartus Prime Pro (for FPGA implementation)
- **Target Device**: Intel Agilex 5 FPGA (configured in Quartus project)
  - Utilizes Agilex 5 LAB carry chains and ALM structure
  - Optimized for Agilex 5's advanced routing architecture
- **Python**: 3.x (for test vector generation)

## Usage

### Generate Test Data

```bash
# Generate test vectors for adders
make data DUT=naiveadder2048b W=2048 TESTS=100

# Generate exhaustive tests for small widths
make data DUT=prefix_tree N=8 TESTS=exhaustive
```

### Simulation

```bash
# Simulate naive adder with M=128 chunk size
make sim DUT=naiveadder2048b W=2048 M=128

# Simulate clever adder with M=64 chunk size
make sim DUT=cleveradder2048b W=2048 M=64

# Simulate standalone prefix tree
make sim DUT=prefix_tree N=32
```

### FPGA Synthesis & Implementation

```bash
# Synthesis only
make synth DUT=cleveradder2048b W=2048 M=64

# Full place & route
make fit DUT=cleveradder2048b W=2048 M=64

# Extract performance metrics (Fmax, area, latency)
make extract DUT=cleveradder2048b W=2048 M=64
```

### Optimization & Parameter Sweeps

```bash
# Find best naive design
./naive.sh

# Find best clever design
./clever.sh

# Sweep over different M values
./sweep_naive.sh 16 32 64 128
./sweep_clever.sh 16 32 64 128
```

## Parameters

Both adder designs are highly parameterized:

- **W**: Total bit width (fixed at 2048)
- **M**: Chunk size for partitioning (power of 2 recommended)
  - Smaller M: Shorter prefix tree, more chunks
  - Larger M: Longer RCA per chunk, fewer prefix levels
  - Optimal M balances these tradeoffs
- **PIPE**: Pipeline enable (1 = pipelined, 0 = combinational)

For the prefix tree:
- **N**: Number of inputs (automatically set to W/M for adders)

## Performance

The clever adder typically achieves 1.5-2x higher Fmax than the naive design by reducing critical path depth through parallel prefix computation. On Agilex 5 FPGAs, performance is optimized by:

- Leveraging dedicated carry chains within LABs for short ripple-carry segments
- Using parallel prefix networks to avoid long carry chain dependencies
- Exploiting Agilex 5's high-speed ALM interconnect for prefix tree logic

Performance varies with chunk size parameter M - use the sweep scripts to find the optimal point that balances LAB carry chain efficiency with prefix tree depth for your specific Agilex 5 device variant.

Results are stored in CSV format:
- `results/winner_naive.csv`: Best naive configuration
- `results/winner_clever.csv`: Best clever configuration

## Design Notes

- All designs use valid/ready handshaking (`in_valid`, `out_valid`)
- Variable latency supported through valid signaling
- Carry-in (`c_in`) is treated as a true carry (A+B+1), not subtraction
- Retiming and Intel Hyper-Flex registers can be leveraged for further optimization on Agilex 5
- The prefix tree uses Kogge-Stone topology (O(log N) depth, O(N log N) area)
- Designs are tuned to map efficiently to Agilex 5 LAB structure:
  - Ripple-carry segments utilize dedicated carry chains
  - Prefix logic uses general routing and ALM resources
  - Pipelining aligned with LAB boundaries where beneficial

## SDC Constraints

Timing constraints are specified in `adder.sdc` for synthesis.

## References

This project implements techniques from the "monster adders" literature, which explores efficient wide-integer addition on FPGAs through chunking and prefix networks.
