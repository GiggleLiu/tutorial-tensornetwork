## simulate a large scale shallow quantum circuit

using Yao

# Define the GHZ state preparation circuit
function ghz_circuit_simulation()
    # Create a 3-qubit register initialized to |000⟩
    reg = zero_state(3)
    
    # Apply Hadamard gate to first qubit
    reg |> put(1=>H)
    
    # Apply CNOT gates: control qubit 1, target qubit 2
    reg |> put((1,2)=>CNOT)
    
    # Apply CNOT gates: control qubit 2, target qubit 3  
    reg |> put((2,3)=>CNOT)
    
    return reg
end

# Alternative: Define circuit using chain syntax
ghz_circuit = chain(3, 
    put(1=>H),           # Hadamard on qubit 1
    put((1,2)=>CNOT),    # CNOT from qubit 1 to 2
    put((2,3)=>CNOT)     # CNOT from qubit 2 to 3
)

# Simulate the GHZ state preparation circuit
reg = zero_state(3) |> ghz_circuit

# Calculate measurement probabilities
probabilities = probs(reg)
println("GHZ state measurement probabilities:")
for (i, prob) in enumerate(probabilities)
    if prob > 1e-10
        # Convert index to binary representation
        binary = string(i-1, base=2, pad=3)
        println("|$binary⟩: $prob")
    end
end

# Expected output:
# |000⟩: 0.5
# |111⟩: 0.5
