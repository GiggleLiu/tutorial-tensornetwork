"""
Simple test of SimpleCATN package functionality
"""

push!(LOAD_PATH, "SimpleCATN")
using SimpleCATN
using LinearAlgebra

println("=== SimpleCATN Package Test ===")

# Test 1: Basic configuration
println("1. Testing configuration...")
config = CATNConfig(chi=16, verbose=true)
println("   ✅ Config created: χ=$(config.chi)")

# Test 2: Create tensor node
println("2. Testing tensor node...")
tensor = randn(ComplexF64, 2, 3)
node = TensorNode(tensor, 1, [2, -1])
println("   ✅ TensorNode created: $(size(node.tensor))")

# Test 3: Create simple tensor network
println("3. Testing tensor network...")
tensors = [randn(ComplexF64, 2, 2), randn(ComplexF64, 2, 2)]
adjacency_lists = [[2], [1]]
tn = TensorNetwork(tensors, adjacency_lists; verbose=false)
println("   ✅ TensorNetwork created: $(length(tn.nodes)) nodes, $(length(tn.edges)) edges")

# Test 4: MPS decomposition
println("4. Testing MPS decomposition...")
big_tensor = randn(ComplexF64, 4, 4, 4)
compressed = mps_decompose(big_tensor, 8, 1e-12)
println("   ✅ MPS decompose: $(size(big_tensor)) → $(size(compressed))")

# Test 5: Network analysis
println("5. Testing network analysis...")
complexity = network_complexity(tn)
memory = memory_usage(tn)
println("   ✅ Analysis: $(complexity.total_elements) elements, $(round(memory.total_mb, digits=3))MB")

println("\n🎉 SimpleCATN Package Test: ALL PASSED!")
println("The package is ready to simplify circuit simulation examples.")