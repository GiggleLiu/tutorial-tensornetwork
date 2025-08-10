using ZXCalculus.ZX
using Vega, DataFrames
using Graphs

"""
Quantum teleportation circuit in ZX calculus.
Alice wants to teleport qubit 1 (unknown state |ψ⟩) to Bob's qubit 3.
Qubits 2 and 3 form the Bell pair shared between Alice and Bob.
"""
function quantum_teleportation()
    # Create 3-qubit ZX diagram
    zxd = ZXDiagram(1)
    ZX.add_ancilla!(zxd, SpiderType.Z, SpiderType.Out)
    ZX.add_ancilla!(zxd, SpiderType.Z, SpiderType.Out)
    
    # Step 1: Prepare Bell pair on qubits 2,3
    # |00⟩ → |Φ+⟩ = (|00⟩ + |11⟩)/√2
    push_gate!(zxd, Val{:H}(), 2)     # Hadamard on qubit 2
    push_gate!(zxd, Val{:CNOT}(), 2, 3)  # CNOT: 2→3
    
    # Step 2: Alice's Bell measurement on qubits 1,2
    push_gate!(zxd, Val{:CNOT}(), 1, 2)  # CNOT: 1→2
    push_gate!(zxd, Val{:H}(), 1)     # Hadamard on qubit 1
    
    # Step 3: Bob's correction gates (conditional on measurement)
    # These would be applied based on Alice's measurement results
    # For demonstration, we use the control gates instead
    push_gate!(zxd, Val{:CNOT}(), 2, 3)  # M2
    push_gate!(zxd, Val{:CZ}(), 1, 3)
    
    return zxd
end

"""
Simplified teleportation showing ZX calculus rewrite rules.
This version demonstrates spider fusion and Hadamard cancellation.
"""
function teleportation_zx_rewrite()
    zxd = quantum_teleportation()

    println("Original teleportation circuit:")
    println("Number of vertices: $(nv(zxd))")
    println("Number of edges: $(ne(zxd))")
    
    # Apply ZX calculus simplification rules
    simplified_zxd = zxd |> phase_teleportation |> clifford_simplification
    
    println("After ZX simplification:")
    println("Number of vertices: $(nv(simplified_zxd))")
    println("Number of edges: $(ne(simplified_zxd))")
    
    return simplified_zxd
end

# Generate and plot quantum teleportation
println("=== Quantum Teleportation in ZX Calculus ===")
teleport_circuit = quantum_teleportation()
println("Teleportation circuit created with $(nv(teleport_circuit)) vertices")

# Show ZX graph visualization
plot(teleport_circuit)
plot(ZXGraph(teleport_circuit))

# Demonstrate ZX calculus simplification
println("\n=== ZX Calculus Simplification ===")
simplified_circuit = teleportation_zx_rewrite()
plot(simplified_circuit)