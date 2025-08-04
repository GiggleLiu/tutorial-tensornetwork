"""
SimpleCATN Package Demo

This demonstrates the SimpleCATN package functionality with simplified examples.
"""

# Add the SimpleCATN package to the load path
push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using SimpleCATN
using LinearAlgebra
using Random

"""
    demo_basic_tensor_network()

Basic tensor network creation and analysis.
"""
function demo_basic_tensor_network()
    println("=== Basic Tensor Network Demo ===")
    
    Random.seed!(42)
    
    # Create simple tensors
    println("1. Creating tensor network...")
    tensors = [
        randn(ComplexF64, 2, 3),      # Tensor 1: 2×3
        randn(ComplexF64, 3, 2, 4),   # Tensor 2: 3×2×4
        randn(ComplexF64, 4, 2)       # Tensor 3: 4×2
    ]
    
    # Define connectivity (adjacency lists)
    # -1 indicates open/external edge
    adjacency_lists = [
        [2, -1],        # Tensor 1 connects to tensor 2, has open edge
        [1, 3, -1],     # Tensor 2 connects to 1 and 3, has open edge  
        [2, -1]         # Tensor 3 connects to tensor 2, has open edge
    ]
    
    for (i, (tensor, neighbors)) in enumerate(zip(tensors, adjacency_lists))
        println("  Tensor $i: $(size(tensor)), neighbors: $neighbors")
    end
    
    # Create CATN tensor network using the package
    config = CATNConfig(chi=16, max_intermediate_dim=20, verbose=true)
    
    tn = TensorNetwork(tensors, adjacency_lists;
                       chi=config.chi,
                       max_intermediate_dim=config.max_intermediate_dim,
                       cutoff=config.cutoff,
                       verbose=config.verbose)
    
    println("\n2. Network analysis:")
    
    # Use package utilities
    visualize_tensor_network(tn)
    
    complexity = network_complexity(tn)
    println("\nComplexity analysis:")
    println("  Total elements: $(complexity.total_elements)")
    println("  Max tensor size: $(complexity.max_tensor_size)")
    println("  Estimated log complexity: $(round(complexity.estimated_log_complexity, digits=2))")
    
    memory = memory_usage(tn)
    println("  Memory usage: $(round(memory.total_mb, digits=3)) MB")
    
    return tn
end

"""
    demo_mps_approximation()

Demonstrate MPS decomposition using the package.
"""
function demo_mps_approximation()
    println("\n=== MPS Approximation Demo ===")
    
    Random.seed!(123)
    
    # Create a higher-dimensional tensor
    println("1. Testing MPS decomposition...")
    original_tensor = randn(ComplexF64, 4, 4, 4, 4)
    println("Original tensor: $(size(original_tensor)) = $(length(original_tensor)) elements")
    
    # Apply MPS decomposition with different chi values
    chi_values = [2, 4, 8, 16]
    
    for chi in chi_values
        compressed = mps_decompose(original_tensor, chi, 1e-12)
        compression_ratio = length(original_tensor) / length(compressed)
        
        println("  χ=$chi: $(size(compressed)) = $(length(compressed)) elements, " *
               "compression $(round(compression_ratio, digits=2))x")
    end
    
    return original_tensor
end

"""
    run_simplified_demos()

Run all simplified demonstrations using the SimpleCATN package.
"""
function run_simplified_demos()
    println("SimpleCATN Package Demonstrations")
    println("=================================")
    
    try
        # Basic functionality
        tn = demo_basic_tensor_network()
        
        # MPS approximation
        tensor = demo_mps_approximation()
        
        println("\n=== Summary ===")
        println("✅ SimpleCATN package loaded and working!")
        println("✅ Tensor network creation and analysis")
        println("✅ MPS decomposition with configurable χ")
        println()
        println("The SimpleCATN package successfully demonstrates:")
        println("• Memory-efficient tensor approximation")
        println("• Configurable accuracy vs. performance trade-offs")
        println("• Clean, modular API for tensor network operations")
        
        return (tn, tensor)
        
    catch e
        println("❌ Demo failed with error: $e")
        println("Stacktrace:")
        println(sprint(showerror, e, catch_backtrace()))
        return nothing
    end
end

# Run demonstrations if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    results = run_simplified_demos()
end