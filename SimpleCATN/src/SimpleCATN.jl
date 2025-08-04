"""
# SimpleCATN.jl

A Julia implementation of CATN (Contracting Arbitrary Tensor Networks) for 
approximate tensor network contraction with applications to quantum circuit simulation.

Based on the algorithm from arXiv:1912.03014.

## Key Features

- **MPS-based tensor approximation** with configurable bond dimensions
- **SVD decomposition** for memory-efficient tensor compression  
- **Heuristic edge selection** for optimal contraction order
- **Quantum circuit integration** framework
- **Memory-efficient scaling** O(χ^d) instead of O(2^n)

## Basic Usage

```julia
using SimpleCATN

# Create tensor network
tensors = [randn(ComplexF64, 2, 3, 2), randn(ComplexF64, 3, 2, 4)]
adjacency_lists = [[2, -1, -1], [1, -1, -1]]

# Configure parameters
config = CATNConfig(chi=32, max_intermediate_dim=25, cutoff=1e-12)

# Create and contract network
tn = TensorNetwork(tensors, adjacency_lists; 
                   chi=config.chi, 
                   max_intermediate_dim=config.max_intermediate_dim, 
                   cutoff=config.cutoff)
result = contract_network!(tn)
```
"""
module SimpleCATN

using LinearAlgebra
using OMEinsum
using Random
using Statistics

# Core functionality
include("core.jl")
include("utils.jl")

# Export main types
export TensorNode, TensorNetwork, CATNConfig

# Export main functions
export contract_network!, mps_decompose, select_edge_heuristic

# Export utility functions
export tensor_shape, log_dimension, find_neighbor_index
export left_canonical!, right_canonical!
export dimension_after_merge, visualize_tensor_network
export network_complexity, memory_usage

end # module SimpleCATN