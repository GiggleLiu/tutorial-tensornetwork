"""
CATN Examples and Usage

This file demonstrates how to use the CATN (Contracting Arbitrary Tensor Networks)
implementation for quantum circuit simulation.
"""

using Yao
using Random
using BenchmarkTools

# Import our CATN modules
include("catn.jl")
include("catn_quantum.jl")
include("reader.jl")

using .CATN
using .YaoQASMReader: yaocircuit_from_qasm

"""
    create_random_circuit(n_qubits::Int, depth::Int; seed::Int=1234)

Create a random quantum circuit for testing.
"""
function create_random_circuit(n_qubits::Int, depth::Int; seed::Int=1234)
    Random.seed!(seed)
    
    circuit = chain(n_qubits)
    
    # Single qubit gates
    single_gates = [X, Y, Z, H, ConstGate.S, ConstGate.T]
    
    # Two qubit gates  
    two_gates = [CNOT]
    
    for layer in 1:depth
        # Add some single qubit gates
        for i in 1:n_qubits
            if rand() < 0.3  # 30% chance of single qubit gate
                gate = rand(single_gates)
                push!(circuit, put(n_qubits, i=>gate))
            end
        end
        
        # Add some two qubit gates
        for i in 1:(n_qubits-1)
            if rand() < 0.5  # 50% chance of two qubit gate
                gate = rand(two_gates)
                push!(circuit, put(n_qubits, (i, i+1)=>gate))
            end
        end
    end
    
    return circuit
end

"""
    example_basic_tensor_network()

Basic example of CATN tensor network contraction.
"""
function example_basic_tensor_network()
    println("=== Basic CATN Tensor Network Example ===")
    
    # Create some simple test tensors
    # This represents a small tensor network
    tensor1 = randn(ComplexF64, 2, 3, 2)  # 3-way tensor
    tensor2 = randn(ComplexF64, 3, 2, 4)  # 3-way tensor  
    tensor3 = randn(ComplexF64, 2, 4)     # 2-way tensor
    
    tensors = [tensor1, tensor2, tensor3]
    
    # Define connectivity (adjacency lists)
    # tensor1 connects to tensor2 via index 2, to tensor3 via index 3
    # tensor2 connects to tensor1 via index 1, to tensor3 via index 3  
    # tensor3 connects to tensor1 via index 1, to tensor2 via index 2
    adjacency_lists = [
        [2, 3, -1],  # tensor1: connected to tensor2, tensor3, open edge
        [1, -1, 3],  # tensor2: connected to tensor1, open edge, tensor3
        [1, 2]       # tensor3: connected to tensor1, tensor2
    ]
    
    # Create CATN tensor network
    tn = TensorNetwork(tensors, adjacency_lists; 
                       chi=16, max_intermediate_dim=20, verbose=true)
    
    # Contract the network
    result = contract_network!(tn)
    
    println("Result shape: $(size(result))")
    println("Result norm: $(norm(result))")
    println()
    
    return result
end

"""
    example_quantum_circuit_simulation()

Example of quantum circuit simulation using CATN.
"""
function example_quantum_circuit_simulation()
    println("=== Quantum Circuit CATN Simulation Example ===")
    
    # Create a test circuit
    n_qubits = 6
    depth = 4
    circuit = create_random_circuit(n_qubits, depth)
    
    println("Created random circuit: $n_qubits qubits, $depth layers")
    println("Circuit gates: $(length(circuit))")
    
    # Create CATN simulator
    simulator = CATNSimulator(chi=32, max_intermediate_dim=25, verbose=true)
    
    # Note: The quantum integration is not fully complete yet
    # This would require proper implementation of tensor extraction from Yao circuits
    println("CATN quantum simulation would be called here")
    println("(Full integration pending)")
    println()
end

"""
    example_load_circuit_file()

Example of loading and processing a circuit from file.
"""
function example_load_circuit_file()
    println("=== Circuit File Loading Example ===")
    
    # Try to load a test circuit
    test_file = joinpath(@__DIR__, "data", "circuits", "test.txt")
    
    if isfile(test_file)
        println("Loading circuit from: $test_file")
        
        # Load circuit using existing reader
        circuit = yaocircuit_from_qasm(test_file)
        
        println("Loaded circuit: $(nqubits(circuit)) qubits")
        println("Circuit depth: $(length(circuit))")
        
        # Convert to tensor network format (using Yao's built-in conversion)
        initial_state = Dict(i => 0 for i in 1:nqubits(circuit))
        final_state = Dict(i => 0 for i in 1:nqubits(circuit))
        
        net = yao2einsum(circuit; initial_state, final_state, TreeSA(ntrials=1))
        
        println("Tensor network complexity:")
        complexity = contraction_complexity(net)
        println("  $complexity")
        
        # Contract using standard OMEinsum
        println("Contracting with OMEinsum...")
        @time result = contract(net)
        println("Result: $result")
        println("Probability: $(abs2(result))")
        
    else
        println("Test circuit file not found: $test_file")
        println("Available files:")
        data_dir = joinpath(@__DIR__, "data", "circuits")
        if isdir(data_dir)
            for file in readdir(data_dir)
                println("  $file")
            end
        end
    end
    println()
end

"""
    benchmark_catn_parameters()

Benchmark different CATN parameters on small circuits.
"""
function benchmark_catn_parameters()
    println("=== CATN Parameter Benchmarking ===")
    
    # Test different tensor network sizes
    sizes = [(3, 2), (4, 3), (5, 3)]
    chi_values = [8, 16, 32]
    
    for (n_qubits, depth) in sizes
        println("\nTesting ${n_qubits}-qubit circuit, depth $depth")
        
        circuit = create_random_circuit(n_qubits, depth)
        
        # Exact simulation
        println("Exact simulation:")
        initial_state = Dict(i => 0 for i in 1:n_qubits)
        final_state = Dict(i => 0 for i in 1:n_qubits)
        net = yao2einsum(circuit; initial_state, final_state, TreeSA(ntrials=1))
        
        @time exact_result = contract(net)
        println("Exact result: $exact_result")
        
        # Test basic tensor operations (placeholder for full CATN)
        println("CATN tensor operations:")
        for chi in chi_values
            println("  chi=$chi: [Placeholder - would test CATN contraction]")
            # This would call the actual CATN simulation once fully integrated
        end
    end
    println()
end

"""
    run_all_examples()

Run all CATN examples.
"""
function run_all_examples()
    println("Running CATN Examples")
    println("====================")
    
    try
        example_basic_tensor_network()
    catch e
        println("Basic tensor network example failed: $e")
    end
    
    try
        example_quantum_circuit_simulation()
    catch e
        println("Quantum circuit simulation example failed: $e")
    end
    
    try
        example_load_circuit_file()
    catch e
        println("Circuit file loading example failed: $e")
    end
    
    try
        benchmark_catn_parameters()
    catch e
        println("Parameter benchmarking failed: $e")
    end
    
    println("Examples complete!")
end

# Helper function to demonstrate the tensor network structure
"""
    visualize_tensor_network(tn::TensorNetwork)

Print a simple visualization of the tensor network structure.
"""
function visualize_tensor_network(tn::TensorNetwork)
    println("Tensor Network Structure:")
    println("Nodes: $(length(tn.nodes))")
    println("Edges: $(length(tn.edges))")
    
    for (id, node) in tn.nodes
        println("  Node $id: shape $(size(node.tensor)), neighbors $(node.neighbors)")
    end
    
    println("Edges:")
    for edge in tn.edges
        println("  $edge")
    end
end

# Run examples if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_all_examples()
end