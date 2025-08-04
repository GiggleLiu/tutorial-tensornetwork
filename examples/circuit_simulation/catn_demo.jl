"""
CATN Demo - A working demonstration of core CATN concepts

This provides a simplified but functional demonstration of the main CATN ideas:
- Tensor network representation
- Edge selection heuristics  
- Approximate contraction methods
- Integration with quantum circuits
"""

using LinearAlgebra
using Random
using OMEinsum

"""
Simple working demo of CATN tensor network concepts
"""
function demo_catn_basic()
    println("=== CATN Basic Concepts Demo ===")
    
    Random.seed!(42)
    
    # Create a simple tensor network example
    println("1. Creating a simple tensor network...")
    
    # Two 2x2 matrices that we'll contract
    A = randn(ComplexF64, 2, 2)
    B = randn(ComplexF64, 2, 2)
    
    println("Tensor A: $(size(A))")
    println("Tensor B: $(size(B))")
    
    # Exact contraction using OMEinsum
    println("\n2. Exact contraction using OMEinsum...")
    exact_result = A * B  # Simple matrix multiplication for this case
    println("Exact result shape: $(size(exact_result))")
    println("Exact result norm: $(norm(exact_result))")
    
    # Approximate contraction using SVD (CATN-like approach)
    println("\n3. Approximate contraction using SVD...")
    
    # Decompose matrix A using SVD with reduced rank
    U, S, V = svd(A)
    
    # Keep only top k singular values (this is the CATN approximation)
    k = min(1, length(S))  # Very aggressive truncation for demo
    U_trunc = U[:, 1:k]
    S_trunc = S[1:k]
    V_trunc = V[1:k, :]
    
    A_approx = U_trunc * Diagonal(S_trunc) * V_trunc
    
    println("Original A norm: $(norm(A))")
    println("Approximated A norm: $(norm(A_approx))")
    println("Approximation error: $(norm(A - A_approx))")
    
    # Contract with approximated tensor
    approx_result = A_approx * B
    println("Approximate result norm: $(norm(approx_result))")
    println("Contraction error: $(norm(exact_result - approx_result))")
    
    return exact_result, approx_result
end

"""
Demonstrate tensor network optimization concepts
"""
function demo_tensor_network_optimization()
    println("\n=== Tensor Network Optimization Demo ===")
    
    Random.seed!(123)
    
    # Create a simpler tensor network that demonstrates the concepts
    println("1. Creating a simple tensor network...")
    
    # Create tensors that can actually be contracted properly
    A = randn(ComplexF64, 3, 4)      # 3x4 matrix
    B = randn(ComplexF64, 4, 5)      # 4x5 matrix  
    C = randn(ComplexF64, 5, 2)      # 5x2 matrix
    
    println("  A: $(size(A)) (connects to B)")
    println("  B: $(size(B)) (connects to A and C)")
    println("  C: $(size(C)) (connects to B)")
    
    # Different contraction orders demonstrate CATN optimization principles
    println("\n2. Testing different contraction orders...")
    
    # Order 1: (A*B)*C
    println("Order 1: (A*B)*C")
    temp_AB = A * B  # 3x5 intermediate
    result1 = temp_AB * C  # 3x2 final
    println("  Intermediate shape: $(size(temp_AB))")
    println("  Final shape: $(size(result1))")
    println("  Intermediate size: $(length(temp_AB)) elements")
    
    # Order 2: A*(B*C)
    println("Order 2: A*(B*C)")
    temp_BC = B * C  # 4x2 intermediate
    result2 = A * temp_BC  # 3x2 final
    println("  Intermediate shape: $(size(temp_BC))")
    println("  Final shape: $(size(result2))")
    println("  Intermediate size: $(length(temp_BC)) elements")
    
    # Compare memory usage
    if length(temp_AB) < length(temp_BC)
        println("  Order 1 uses less memory ($(length(temp_AB)) vs $(length(temp_BC)))")
    else
        println("  Order 2 uses less memory ($(length(temp_BC)) vs $(length(temp_AB)))")
    end
    
    # Results should be identical
    println("  Results match: $(isapprox(result1, result2, rtol=1e-10))")
    
    # Demonstrate approximation effect
    println("\n3. Demonstrating approximation...")
    
    # Apply SVD approximation to intermediate result
    U, S, V = svd(temp_AB)
    
    # Keep only top singular values
    k = min(2, length(S))  # Aggressive truncation
    temp_AB_approx = U[:, 1:k] * Diagonal(S[1:k]) * V[:, 1:k]'  # Note: V' and correct indexing
    result1_approx = temp_AB_approx * C
    
    println("  Original intermediate rank: $(length(S))")
    println("  Approximated rank: $k")
    println("  Approximation error: $(norm(result1 - result1_approx))")
    println("  Relative error: $(norm(result1 - result1_approx) / norm(result1))")
    
    return result1, result2, result1_approx
end

"""
Demonstrate quantum circuit tensor network concepts
"""
function demo_quantum_circuit_concepts()
    println("\n=== Quantum Circuit Tensor Network Demo ===")
    
    # This shows the conceptual structure without needing full Yao integration
    println("1. Quantum circuit as tensor network concept...")
    
    # Single qubit gates (2x2 matrices)
    H = [1 1; 1 -1] / sqrt(2)  # Hadamard
    X = [0 1; 1 0]             # Pauli-X
    
    # Two-qubit gate (4x4 matrix, reshaped to 2x2x2x2 tensor)
    CNOT_matrix = [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
    CNOT = reshape(ComplexF64.(CNOT_matrix), 2, 2, 2, 2)
    
    # Initial state |0⟩ for each qubit
    zero_state = ComplexF64[1, 0]
    
    println("Gate shapes:")
    println("  H: $(size(H))")
    println("  X: $(size(X))")
    println("  CNOT: $(size(CNOT))")
    println("  |0⟩: $(size(zero_state))")
    
    # Simple 2-qubit circuit: H ⊗ I, then CNOT
    println("\n2. Simulating simple 2-qubit circuit...")
    
    # Apply H to first qubit, I to second qubit
    h_applied = H * zero_state
    state1 = h_applied * zero_state'  # Outer product
    println("After H⊗I: $(size(state1))")
    
    # Apply CNOT gate
    state1_vec = reshape(state1, 4)
    final_state_vec = CNOT_matrix * state1_vec
    final_state = reshape(final_state_vec, 2, 2)
    
    println("Final state shape: $(size(final_state))")
    println("Final state probabilities:")
    for i in 1:2, j in 1:2
        prob = abs2(final_state[i,j])
        if prob > 1e-10
            println("  |$(i-1)$(j-1)⟩: $(prob)")
        end
    end
    
    return final_state
end

"""
Main demo function
"""
function run_catn_demo()
    println("CATN (Contracting Arbitrary Tensor Networks) Demo")
    println("================================================")
    println()
    
    try
        demo_catn_basic()
        demo_tensor_network_optimization() 
        demo_quantum_circuit_concepts()
        
        println("\n=== Demo Summary ===")
        println("✅ Demonstrated core CATN concepts:")
        println("   - SVD-based tensor approximation")
        println("   - Contraction order optimization")
        println("   - Quantum circuit tensor networks")
        println()
        println("This demonstrates the key ideas behind CATN:")
        println("1. Approximate tensor contractions using SVD")
        println("2. Optimize contraction order to minimize memory")
        println("3. Apply to quantum circuit simulation")
        println()
        println("For full quantum circuit integration, see the other CATN files.")
        
    catch e
        println("Demo failed with error: $e")
        println("Stacktrace:")
        println(sprint(showerror, e, catch_backtrace()))
    end
end

# Run demo if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_catn_demo()
end