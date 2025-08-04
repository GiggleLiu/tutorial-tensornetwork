"""
Simplified Examples using SimpleCATN Package

This replaces the complex catn_examples.jl (268 lines) with clean, 
simple examples that demonstrate SimpleCATN usage.
"""

push!(LOAD_PATH, "SimpleCATN")
using SimpleCATN
using LinearAlgebra 
using Random

"""
Example 1: Basic tensor compression
"""
function example_tensor_compression()
    println("=== Example 1: Tensor Compression ===")
    
    Random.seed!(42)
    
    # Create a large tensor
    original = randn(ComplexF64, 8, 8, 8, 8)
    println("Original tensor: $(size(original)) = $(length(original)) elements")
    
    # Compress with different bond dimensions
    for chi in [4, 8, 16, 32]
        compressed = mps_decompose(original, chi, 1e-12)
        ratio = length(original) / length(compressed)
        
        println("  χ=$chi: $(size(compressed)) = $(length(compressed)) elements")
        println("         Compression: $(round(ratio, digits=2))x")
    end
    
    println("✅ Tensor compression complete!\n")
end

"""  
Example 2: Simple tensor network
"""
function example_tensor_network()
    println("=== Example 2: Tensor Network ===")
    
    Random.seed!(123)
    
    # Create connected tensors
    tensors = [
        randn(ComplexF64, 2, 3),      # Tensor A: connects to B
        randn(ComplexF64, 3, 2, 4),   # Tensor B: connects to A and C  
        randn(ComplexF64, 4, 2)       # Tensor C: connects to B
    ]
    
    adjacency_lists = [
        [2, -1],        # A connects to B (index 2), has open edge
        [1, 3, -1],     # B connects to A (1) and C (3), has open edge
        [2, -1]         # C connects to B (2), has open edge
    ]
    
    println("Creating tensor network:")
    for (i, (tensor, neighbors)) in enumerate(zip(tensors, adjacency_lists))
        println("  Tensor $i: $(size(tensor)), neighbors: $neighbors")
    end
    
    # Create network using SimpleCATN
    tn = TensorNetwork(tensors, adjacency_lists; chi=16, verbose=true)
    
    # Analyze network
    complexity = network_complexity(tn)
    memory = memory_usage(tn)
    
    println("\nNetwork Analysis:")
    println("  Complexity: $(complexity.total_elements) total elements")
    println("  Memory: $(round(memory.total_mb, digits=3)) MB")
    println("  Max tensor: $(complexity.max_tensor_size) elements")
    
    println("✅ Tensor network creation complete!\n")
    return tn
end

"""
Example 3: Configuration comparison  
"""
function example_configurations()
    println("=== Example 3: Configuration Comparison ===")
    
    # Test different configurations
    configs = [
        CATNConfig(chi=8, max_intermediate_dim=15, verbose=false),
        CATNConfig(chi=16, max_intermediate_dim=20, verbose=false), 
        CATNConfig(chi=32, max_intermediate_dim=25, verbose=false)
    ]
    
    # Simple tensor for testing
    test_tensor = randn(ComplexF64, 4, 4, 4, 4)
    
    println("Testing different configurations on $(size(test_tensor)) tensor:")
    
    for (i, config) in enumerate(configs)
        compressed = mps_decompose(test_tensor, config.chi, config.cutoff)
        ratio = length(test_tensor) / length(compressed)
        
        println("  Config $i: χ=$(config.chi), max_dim=$(config.max_intermediate_dim)")
        println("           Compression: $(round(ratio, digits=2))x")
    end
    
    println("✅ Configuration comparison complete!\n")
end

"""
Example 4: Quantum circuit concepts
"""
function example_quantum_concepts()
    println("=== Example 4: Quantum Circuit Concepts ===")
    
    # Basic quantum gates as tensors
    I = ComplexF64[1 0; 0 1]  # Identity
    X = ComplexF64[0 1; 1 0]  # Pauli-X
    H = ComplexF64[1 1; 1 -1] / sqrt(2)  # Hadamard
    
    # Initial states
    zero = ComplexF64[1, 0]  # |0⟩
    one = ComplexF64[0, 1]   # |1⟩
    
    println("Basic quantum gates:")
    println("  I (Identity): $(size(I))")
    println("  X (Pauli-X): $(size(X))")
    println("  H (Hadamard): $(size(H))")
    
    # Simple circuit operations
    println("\nSimple circuit operations:")
    
    # |0⟩ → H → |+⟩ (superposition)
    plus_state = H * zero
    probs = abs2.(plus_state)
    println("  H|0⟩ = $plus_state")
    println("  Probabilities: |0⟩=$(round(probs[1],digits=3)), |1⟩=$(round(probs[2],digits=3))")
    
    # |1⟩ → H → |-⟩ (superposition)
    minus_state = H * one
    probs2 = abs2.(minus_state)
    println("  H|1⟩ = $minus_state") 
    println("  Probabilities: |0⟩=$(round(probs2[1],digits=3)), |1⟩=$(round(probs2[2],digits=3))")
    
    println("✅ Quantum concepts demonstration complete!\n")
    
    return (I, X, H, plus_state, minus_state)
end

"""
Example 5: Performance comparison
"""
function example_performance()
    println("=== Example 5: Performance Comparison ===")
    
    sizes = [4, 8, 16]
    
    println("Comparing exact vs approximate tensor operations:")
    
    for size in sizes
        println("\nTensor size: $size×$size×$size")
        
        # Create test tensors
        A = randn(ComplexF64, size, size, size)
        B = randn(ComplexF64, size, size, size)
        
        # Exact computation
        exact_time = @elapsed exact_result = A .* B  
        
        # Approximate computation using MPS
        approx_time = @elapsed begin
            A_compressed = mps_decompose(A, 8, 1e-12)
            B_compressed = mps_decompose(B, 8, 1e-12) 
            approx_result = A_compressed .* B_compressed
        end
        
        # Calculate error and speedup
        if size(exact_result) == size(approx_result)
            error = norm(exact_result - approx_result) / norm(exact_result)
            speedup = exact_time / approx_time
            
            println("  Exact: $(round(exact_time*1000, digits=2))ms")
            println("  Approx: $(round(approx_time*1000, digits=2))ms")
            println("  Speedup: $(round(speedup, digits=2))x")
            println("  Error: $(round(error, digits=6))")
        else
            println("  Exact: $(round(exact_time*1000, digits=2))ms")
            println("  Approx: $(round(approx_time*1000, digits=2))ms")
            println("  Note: Sizes differ due to compression")
        end
    end
    
    println("✅ Performance comparison complete!\n")
end

"""
Run all simplified examples
"""
function run_all_examples()
    println("SimpleCATN Package Examples")
    println("=" * 40)
    println("This replaces the complex catn_examples.jl with clean, simple examples.\n")
    
    try
        # Run all examples
        example_tensor_compression()
        tn = example_tensor_network()
        example_configurations()
        gates = example_quantum_concepts()
        example_performance()
        
        # Summary
        println("=" * 40)
        println("🎉 ALL EXAMPLES COMPLETED SUCCESSFULLY!")
        println("=" * 40)
        
        println("\nSimplification achieved:")
        println("• Original catn_examples.jl: 268 lines of complex code")
        println("• New examples_simple.jl: ~200 lines of clean, readable code")
        println("• 5 focused examples vs scattered functionality")
        println("• Easy to understand and modify")
        println("• Direct SimpleCATN package usage")
        
        println("\nThe SimpleCATN package dramatically simplifies:")
        println("✅ Tensor compression and MPS decomposition")
        println("✅ Tensor network creation and analysis")
        println("✅ Configuration management")  
        println("✅ Quantum circuit concepts")
        println("✅ Performance optimization")
        
        return (tn, gates)
        
    catch e
        println("❌ Example failed: $e")
        println("Note: Examples demonstrate SimpleCATN API structure")
        return nothing
    end
end

# Run examples if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_all_examples()
end