"""
Simple test for basic CATN functionality without quantum circuit integration
"""

using LinearAlgebra
using Random

# Load only the core CATN module 
include("catn.jl")
using .CATN

function test_basic_catn()
    println("Testing Basic CATN Functionality")
    println("================================")
    
    Random.seed!(1234)
    
    # Create some simple test tensors
    tensor1 = randn(ComplexF64, 2, 3, 2)  # 3-way tensor
    tensor2 = randn(ComplexF64, 3, 2, 4)  # 3-way tensor  
    tensor3 = randn(ComplexF64, 2, 4)     # 2-way tensor
    
    tensors = [tensor1, tensor2, tensor3]
    
    println("Created test tensors:")
    for (i, t) in enumerate(tensors)
        println("  Tensor $i: $(size(t))")
    end
    
    # Define connectivity (adjacency lists)
    # tensor1 connects to tensor2 via shared dimension, to tensor3 via shared dimension
    adjacency_lists = [
        [2, 3, -1],  # tensor1: connected to tensor2, tensor3, open edge
        [1, -1, 3],  # tensor2: connected to tensor1, open edge, tensor3
        [1, 2]       # tensor3: connected to tensor1, tensor2
    ]
    
    println("\nAdjacency lists:")
    for (i, adj) in enumerate(adjacency_lists)
        println("  Tensor $i neighbors: $adj")
    end
    
    # Create CATN tensor network
    println("\nCreating CATN tensor network...")
    tn = TensorNetwork(tensors, adjacency_lists; 
                       chi=16, max_intermediate_dim=20, cutoff=1e-14 + 0.0im, verbose=true)
    
    println("Network created successfully!")
    println("Nodes: $(length(tn.nodes))")
    println("Edges: $(length(tn.edges))")
    
    # Display network structure
    println("\nNetwork structure:")
    for (id, node) in tn.nodes
        println("  Node $id: shape $(size(node.tensor)), neighbors $(node.neighbors)")
    end
    
    println("Edges: $(collect(tn.edges))")
    
    # Contract the network
    println("\nContracting tensor network...")
    result = contract_network!(tn)
    
    println("Contraction complete!")
    println("Result shape: $(size(result))")
    println("Result norm: $(norm(result))")
    println("Maximum intermediate dimension reached: $(tn.max_dim_reached)")
    
    return result
end

function test_tensor_operations()
    println("\nTesting Tensor Operations")
    println("========================")
    
    # Test MPS decomposition
    println("Testing MPS decomposition...")
    tensor = randn(ComplexF64, 4, 4, 4, 4)
    println("Original tensor shape: $(size(tensor))")
    
    decomposed = mps_decompose(tensor, 8, 1e-12 + 0.0im)
    println("Decomposed tensor shape: $(size(decomposed))")
    
    # Test canonical forms
    println("\nTesting canonical forms...")
    node = TensorNode(randn(ComplexF64, 3, 4), 1, [2, -1], 32, 1e-14 + 0.0im)
    println("Original tensor shape: $(size(node.tensor))")
    
    left_canonical!(node)
    println("After left canonical: $(size(node.tensor))")
    
    return true
end

function run_basic_tests()
    println("CATN Basic Tests")
    println("================\n")
    
    try
        test_tensor_operations()
        result = test_basic_catn()
        println("\n✅ All basic tests passed!")
        return true
    catch e
        println("\n❌ Test failed with error: $e")
        println("Stacktrace:")
        println(sprint(showerror, e, catch_backtrace()))
        return false
    end
end

# Run tests if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_basic_tests()
end