# CATN: Contracting Arbitrary Tensor Networks in Julia

This directory contains a Julia implementation of the CATN (Contracting Arbitrary Tensor Networks) algorithm for approximate quantum circuit simulation.

## Overview

CATN is an algorithm for approximately contracting large tensor networks using matrix product state (MPS) representations and heuristic edge selection. It's particularly useful for simulating quantum circuits that are too large for exact simulation.

**Reference**: Pan Zhang, "Contracting arbitrary tensor networks: approximate methods," arXiv:1912.03014

## Files

- `catn.jl` - Core CATN tensor network implementation
- `catn_quantum.jl` - Integration with Yao.jl quantum circuits  
- `catn_examples.jl` - Usage examples and demonstrations
- `catn_main.jl` - Main entry point and command-line interface
- `README_CATN.md` - This documentation

## Key Features

### Core Algorithm
- **MPS-based tensor representation** for memory efficiency
- **SVD decomposition** with configurable bond dimensions and cutoff thresholds  
- **Heuristic edge selection** for optimal contraction order
- **Approximate contraction** that trades accuracy for computational feasibility

### Integration
- **Yao.jl compatibility** for quantum circuit simulation
- **OMEinsum integration** for tensor operations
- **Configurable parameters** for accuracy vs. performance trade-offs

## Usage

### Basic Usage

```julia
using Pkg; Pkg.activate(".")
include("catn_main.jl")

# Create a simple tensor network
tensors = [randn(ComplexF64, 2, 2, 2), randn(ComplexF64, 2, 2), randn(ComplexF64, 2, 2, 2)]
adjacency_lists = [[2, 3, -1], [1, 3], [1, 2, -1]]

# Create CATN tensor network
tn = TensorNetwork(tensors, adjacency_lists; chi=32, max_intermediate_dim=25)

# Contract the network
result = contract_network!(tn)
```

### Quantum Circuit Simulation

```julia
using Yao
include("catn_main.jl")

# Create a quantum circuit
circuit = chain(4, put(1=>H), put(2=>X), put((1,2)=>CNOT))

# Load from file
circuit = yaocircuit_from_qasm("data/circuits/test.txt")

# Simulate with CATN (integration in development)
config = CATNConfig(chi=32, max_intermediate_dim=25, verbose=true)
result = simulate_circuit_file("test.txt", config)
```

### Command Line Usage

```bash
# Simulate a specific circuit file
julia catn_main.jl data/circuits/test.txt --chi 32 --max-dim 25 --verbose

# Run demonstrations
julia catn_main.jl

# Run examples
julia catn_examples.jl
```

## Parameters

### Core Parameters
- `chi`: Maximum MPS bond dimension (default: 32)
- `max_intermediate_dim`: Maximum intermediate tensor dimension (default: 25)  
- `cutoff`: SVD cutoff threshold (default: 1e-12)
- `verbose`: Enable detailed output (default: false)

### Edge Selection Heuristics
- `:min_dim`: Select edge minimizing intermediate tensor dimension (default)
- `:random`: Random edge selection

## Implementation Details

### TensorNode Structure
Each tensor in the network is represented as a `TensorNode` containing:
- The tensor data
- Connectivity information (neighbors, edge dimensions)
- MPS parameters (chi, cutoff)
- Canonical form tracking

### Contraction Algorithm
1. **Initialize**: Create tensor network from input tensors and connectivity
2. **Edge Selection**: Use heuristics to select optimal contraction order
3. **Contraction**: Contract pairs of tensors using OMEinsum
4. **Approximation**: Apply MPS decomposition when tensors become too large
5. **Iteration**: Repeat until single tensor remains

### Memory Management
- SVD-based dimension reduction prevents exponential memory growth
- Configurable bond dimensions balance accuracy vs. memory usage
- Canonical forms optimize subsequent operations

## Examples

### Example 1: Basic Tensor Network
```julia
include("catn_examples.jl")
example_basic_tensor_network()
```

### Example 2: Random Quantum Circuit
```julia
circuit = create_random_circuit(6, 4)  # 6 qubits, depth 4
# Process with CATN...
```

### Example 3: Benchmarking
```julia
benchmark_catn_vs_exact(max_qubits=8, depths=[2, 3, 4])
```

## Current Status

### Completed Features
✅ Core tensor network data structures  
✅ MPS-based tensor node representation  
✅ SVD approximation with configurable parameters  
✅ Edge selection heuristics  
✅ Basic contraction algorithm  
✅ Integration framework with Yao.jl  
✅ Example usage and demonstrations  

### In Development
🔄 Full quantum circuit tensor extraction  
🔄 Optimized contraction path algorithms  
🔄 GPU acceleration support  
🔄 Advanced approximation methods  

### Planned Features
📋 PEPS (Projected Entangled Pair States) support  
📋 Noise model integration  
📋 Parallel/distributed contraction  
📋 Automatic parameter tuning  

## Comparison with Original CATN

This Julia implementation follows the core algorithms from the original Python CATN:

| Feature | Original CATN | Julia CATN |
|---------|---------------|------------|
| MPS representation | ✅ | ✅ |
| SVD approximation | ✅ | ✅ |
| Edge selection heuristics | ✅ | ✅ |
| Quantum circuit support | ✅ | 🔄 |
| PEPS support | ✅ | 📋 |
| GPU acceleration | ✅ | 📋 |

## Performance Notes

- **Memory scaling**: O(χ^d) where χ is bond dimension, d is connectivity
- **Time complexity**: Depends on contraction order and approximation quality
- **Accuracy**: Controlled by χ and cutoff parameters
- **Scalability**: Can handle much larger circuits than exact methods

## Dependencies

- Julia 1.6+
- Yao.jl (quantum circuit framework)
- OMEinsum.jl (tensor contraction)
- LinearAlgebra.jl (matrix operations)
- Random.jl, Statistics.jl (utilities)
- BenchmarkTools.jl (performance testing)

## Installation

```julia
using Pkg
Pkg.activate("examples/circuit_simulation")
Pkg.instantiate()
```

## Testing

```julia
# Run all examples
include("catn_examples.jl")
run_all_examples()

# Run main demonstrations  
include("catn_main.jl")
main()
```

## Contributing

Contributions welcome! Priority areas:
1. Completing quantum circuit tensor extraction
2. Optimizing contraction algorithms
3. Adding GPU support
4. Implementing PEPS representations

## License

This implementation is part of the tutorial-tensornetwork project and follows the same license terms.