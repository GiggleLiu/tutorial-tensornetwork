# Data Description

This directory contains data files for quantum circuit simulation using tensor networks[^Villalonga2019]. The data is organized into four main categories:

## 1. Circuit Files (`circuits/`)

Contains quantum circuit definitions in QASM-like format for various quantum devices and topologies.

### Circuit Naming Convention

**Bristlecone model:**
- Format: `bristlecone_{qubits}_{layers}-{depth}-{layers}_{instance}.txt`
- Example: `bristlecone_60_1-24-1_0.txt` means a 60-qubit circuit with 24 depth cycles, one layer of Hadamard gates at beginning and end

**Sycamore model:**
- Format: `sycamore_{qubits}_{depth}_{instance}.txt`
- Example: `sycamore_53_10_0.txt` means a 53-qubit Sycamore circuit with depth 10

**Rectangular grids:**
- Format: `rectangular_{width}x{height}_{layers}-{depth}-{layers}_{instance}.txt`
- Example: `rectangular_8x8_1-32-1_0.txt` means an 8x8 grid circuit with depth 32

**Rochester (IBM) model:**
- Format: `rochester_{qubits}_{depth}_{instance}_{pattern}.txt`
- Example: `rochester_53_16_0_pABC.txt` means a 53-qubit Rochester circuit with patterns A, B, C

## 2. Grid Files (`grid/`)

Define the physical qubit connectivity topology for quantum devices.

- **Format**: Binary adjacency matrices where `1` indicates connected qubits, `0` indicates no connection
- **Purpose**: Represents the actual physical layout and connectivity of quantum processors
- **Examples**: 
  - `sycamore_53.txt` - Google Sycamore 53-qubit processor topology
  - `rochester_53.txt` - IBM Rochester 53-qubit processor topology
  - `bristlecone_*.txt` - Google Bristlecone processor variants
  - `rectangular_*x*.txt` - Regular rectangular grid topologies

## 3. Ordering Files (`ordering/`)

Contains tensor network contraction ordering strategies for efficient classical simulation.

- **Format**: Script-like commands defining contraction strategies
- **Commands**:
  - `cut () i j` - Make cuts between tensors i and j
  - `expand patch_name tensor_id` - Expand a tensor patch
  - `merge patch1 patch2` - Merge tensor patches
- **Purpose**: Optimize tensor network contractions to reduce computational complexity
- **Examples**: Pre-computed optimal orderings for Sycamore, Rochester, and Bristlecone devices

## 4. Pattern Files (`patterns/`)

Define gate application patterns for different layers in quantum circuits.

- **Format**: Python dictionary-like syntax mapping pattern names to qubit pairs
- **Structure**: Each pattern (A, B, C, etc.) defines which qubit pairs can have two-qubit gates applied simultaneously
- **Purpose**: Ensure gate applications respect device topology and avoid conflicts
- **Examples**:
  - `ibm_rochester.txt` - Gate patterns for IBM Rochester processor
  - `rigetti_aspen.txt` - Gate patterns for Rigetti Aspen processor

## Usage

These data files work together in the quantum circuit simulation pipeline:

1. **Grid files** define device topology constraints
2. **Pattern files** define valid gate application schemes
3. **Circuit files** contain actual quantum circuits using these patterns
4. **Ordering files** provide optimized simulation strategies

The `main.jl` script demonstrates how to load circuits and convert them to tensor networks for classical simulation, utilizing these data files for realistic quantum hardware modeling.

[^Villalonga2019]: Villalonga, B., Boixo, S., Nelson, B., Henze, C., Rieffel, E., Biswas, R., Mandrà, S., 2019. A flexible high-performance simulator for verifying and benchmarking quantum circuits implemented on real hardware. npj Quantum Inf 5, 86. https://doi.org/10.1038/s41534-019-0196-1