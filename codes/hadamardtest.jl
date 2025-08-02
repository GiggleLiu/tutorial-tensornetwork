using Yao

function hadamard_test(psi::AbstractRegister, U::AbstractBlock)
    # Ensure psi is a single-qubit state
    @assert nqubits(psi) == 1
    
    # Create ancilla qubit initialized to |0⟩
    ancilla = zero_state(1)
    
    # Combine qubits: [ancilla, psi]
    reg = join(ancilla, psi)
    
    # Apply Hadamard test circuit
    reg |> put(1=>H)                    # H on ancilla
    reg |> put((1,2)=>control(1, 2=>U)) # Controlled-U
    reg |> put(1=>H)                    # H on ancilla
    
    # Measure ancilla qubit
    result = measure!(reg, 1)
    
    # Return probability of measuring |0⟩
    return result[1] == 0 ? 1.0 : 0.0
end

# Example usage: estimating expectation value of Z gate on |+⟩ state
psi = zero_state(1) |> put(1=>H)  # |+⟩ state
U = Z                             # Pauli-Z gate

# Run Hadamard test multiple times to estimate probability
num_trials = 1000
success_count = 0

for _ in 1:num_trials
    psi_copy = copy(psi)
    success_count += hadamard_test(psi_copy, U)
end

prob_zero = success_count / num_trials
expectation_value = 2 * prob_zero - 1

println("Probability of measuring |0⟩: $prob_zero")
println("Estimated ⟨ψ|U|ψ⟩: $expectation_value")
println("Theoretical ⟨+|Z|+⟩: 0.0")

# Example with different unitary: X gate
println("\nTesting with X gate:")
U_x = X
success_count_x = 0

for _ in 1:num_trials
    psi_copy = copy(psi)
    success_count_x += hadamard_test(psi_copy, U_x)
end

prob_zero_x = success_count_x / num_trials
expectation_value_x = 2 * prob_zero_x - 1

println("Probability of measuring |0⟩: $prob_zero_x")
println("Estimated ⟨ψ|X|ψ⟩: $expectation_value_x")
println("Theoretical ⟨+|X|+⟩: 1.0")
