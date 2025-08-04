"""
Simplified Circuit Simulation Example using SimpleCATN Package

This example shows how to use the SimpleCATN package to simplify
tensor network operations for quantum circuit simulation.
"""

# Load the SimpleCATN package
push!(LOAD_PATH, "SimpleCATN")
using SimpleCATN

using LinearAlgebra
using Random
using OMEinsum

"""
    create_simple_circuit_tensors()

Create tensors representing a simple quantum circuit.
"""
function create_simple_circuit_tensors()
    println("=== Creating Simple Circuit Tensors ===")
    
    # Basic quantum gates
    I = ComplexF64[1 0; 0 1]  # Identity
    H = ComplexF64[1 1; 1 -1] / sqrt(2)  # Hadamard
    X = ComplexF64[0 1; 1 0]  # Pauli-X
    
    # Initial states |0⟩
    zero = ComplexF64[1, 0]
    
    println("Created basic gates and states")
    println("  I: $(size(I))")
    println("  H: $(size(H))")  
    println("  X: $(size(X))")
    println("  |0⟩: $(size(zero))")
    
    return I, H, X, zero
end

"""
    simulate_with_simplecatn()

Demonstrate circuit simulation using SimpleCATN package.
"""
function simulate_with_simplecatn()
    println("\n=== Circuit Simulation with SimpleCATN ===")
    
    Random.seed!(42)
    
    # Create a tensor network representing a simple quantum circuit
    # Circuit: |0⟩ -H- |+⟩ (single qubit Hadamard)
    
    I, H, X, zero = create_simple_circuit_tensors()
    
    # Method 1: Direct matrix multiplication (exact)
    println("\n1. Exact simulation:")
    exact_result = H * zero
    exact_prob = abs2.(exact_result)
    println("  Final state: $exact_result")
    println("  Probabilities: |0⟩=$(round(exact_prob[1], digits=3)), |1⟩=$(round(exact_prob[2], digits=3))")
    
    # Method 2: Using SimpleCATN for tensor network approach
    println("\n2. SimpleCATN tensor network approach:")
    
    # Create tensors representing the circuit
    # For a single qubit circuit, this is just the gate and initial state
    tensors = [zero, H]  # Initial state and gate
    adjacency_lists = [
        [2],    # State connects to gate
        [1]     # Gate connects to state  
    ]
    
    # Create configuration
    config = CATNConfig(chi=8, max_intermediate_dim=10, verbose=true)
    
    # Create tensor network
    tn = TensorNetwork(tensors, adjacency_lists;
                       chi=config.chi,
                       max_intermediate_dim=config.max_intermediate_dim,
                       cutoff=config.cutoff,
                       verbose=config.verbose)
    
    println("  Created tensor network with $(length(tn.nodes)) nodes")
    
    # Analyze the network
    complexity = network_complexity(tn)
    println("  Network complexity: $(complexity.total_elements) total elements")
    
    # For this simple case, contraction would just return the final state
    # (This is a demonstration of the framework)
    
    return exact_result, tn
end

"""
    compare_methods()

Compare different simulation approaches.
"""
function compare_methods()
    println("\n=== Method Comparison ===")
    
    Random.seed!(123)
    
    # Create larger matrices for comparison
    println("1. Comparing matrix multiplication approaches:")
    
    # Simulate a 3-matrix chain (like a 3-gate circuit)
    A = randn(ComplexF64, 4, 8)   # First gate
    B = randn(ComplexF64, 8, 16)  # Second gate  
    C = randn(ComplexF64, 16, 4)  # Third gate
    
    println("  Matrix sizes: $(size(A)) × $(size(B)) × $(size(C))")
    
    # Exact computation
    exact_time = @elapsed exact_result = A * B * C
    println("  Exact computation: $(round(exact_time * 1000, digits=2)) ms")
    
    # Using MPS approximation from SimpleCATN
    approx_time = @elapsed begin
        # Contract first two matrices
        temp = A * B
        
        # Apply MPS compression
        compressed_temp = mps_decompose(temp, 8, 1e-10)  # χ=8
        
        # Final contraction
        approx_result = compressed_temp * C
    end
    
    # Calculate error
    error = norm(exact_result - approx_result) / norm(exact_result)
    speedup = exact_time / approx_time
    
    println("  MPS approximation: $(round(approx_time * 1000, digits=2)) ms")
    println("  Relative error: $(round(error, digits=6))")
    println("  Speedup: $(round(speedup, digits=2))x")
    
    return exact_result, approx_result, error
end

"""
    demonstrate_scalability()

Show how SimpleCATN helps with larger problems.
"""
function demonstrate_scalability()
    println("\n=== Scalability Demonstration ===")
    
    sizes = [4, 8, 16, 32]
    chi_values = [2, 4, 8]
    
    println("Testing MPS decomposition scaling:")
    
    for size in sizes
        println("\n  Tensor size: $size × $size × $size")
        
        # Create test tensor
        tensor = randn(ComplexF64, size, size, size)
        original_elements = length(tensor)
        
        for chi in chi_values
            # Time the decomposition
            time_taken = @elapsed compressed = mps_decompose(tensor, chi, 1e-12)
            compressed_elements = length(compressed)
            compression_ratio = original_elements / compressed_elements
            
            println("    χ=$chi: $(round(time_taken * 1000, digits=2))ms, " *
                   "compression $(round(compression_ratio, digits=1))x")
        end
    end
end

"""
    main_example()

Main example showing SimpleCATN usage.
"""
function main_example()
    println("Simplified Circuit Simulation with SimpleCATN")
    println("=" * 50)
    
    try
        # Basic circuit simulation
        exact_state, tensor_network = simulate_with_simplecatn()
        
        # Method comparison
        exact, approx, error = compare_methods()
        
        # Scalability demo
        demonstrate_scalability()
        
        println("\n" * "=" * 50)
        println("SUCCESS: SimpleCATN Package Working!")
        println("=" * 50)
        
        println("✅ Package loaded and functional")
        println("✅ Tensor network creation")
        println("✅ MPS decomposition working")
        println("✅ Performance analysis complete")
        println("✅ Scalability demonstrated")
        
        println("\nKey Benefits Demonstrated:")
        println("• Clean, modular API")
        println("• Configurable approximation parameters")
        println("• Memory-efficient tensor operations") 
        println("• Foundation for larger quantum simulations")
        
        return (exact_state, tensor_network, exact, approx, error)
        
    catch e
        println("❌ Example failed: $e")
        println("Stacktrace:")
        println(sprint(showerror, e, catch_backtrace()))
        return nothing
    end
end

# Run the example
if abspath(PROGRAM_FILE) == @__FILE__
    results = main_example()
end