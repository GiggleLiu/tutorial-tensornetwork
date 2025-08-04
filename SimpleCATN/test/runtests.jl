using Test
using LinearAlgebra
using Random

# Add SimpleCATN to the load path for testing
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using SimpleCATN

@testset "SimpleCATN.jl Tests" begin

    @testset "Core Data Structures" begin
        @testset "CATNConfig" begin
            # Test default configuration
            config = CATNConfig()
            @test config.chi == 32
            @test config.max_intermediate_dim == 25
            @test config.cutoff ≈ 1e-12
            @test config.verbose == false
            @test config.heuristic == :min_dim
            
            # Test custom configuration
            config_custom = CATNConfig(chi=64, verbose=true, heuristic=:random)
            @test config_custom.chi == 64
            @test config_custom.verbose == true
            @test config_custom.heuristic == :random
        end
        
        @testset "TensorNode" begin
            # Create test tensor node
            tensor = randn(ComplexF64, 2, 3, 2)
            neighbors = [2, 3, -1]
            node = TensorNode(tensor, 1, neighbors, 16, 1e-10)
            
            @test node.id == 1
            @test node.neighbors == neighbors
            @test node.chi == 16
            @test size(node.tensor) == (2, 3, 2)
            @test haskey(node.edge_dims, 2)
            @test haskey(node.edge_dims, 3)
            @test !haskey(node.edge_dims, -1)  # Open edges not in edge_dims
        end
        
        @testset "TensorNetwork" begin
            # Create simple tensor network
            tensors = [randn(ComplexF64, 2, 3), randn(ComplexF64, 3, 2)]
            adjacency_lists = [[2, -1], [1, -1]]
            
            tn = TensorNetwork(tensors, adjacency_lists; verbose=false)
            
            @test length(tn.nodes) == 2
            @test length(tn.edges) == 1
            @test (1, 2) in tn.edges || (2, 1) in tn.edges
        end
    end
    
    @testset "Utility Functions" begin
        @testset "Tensor Operations" begin
            tensor = randn(ComplexF64, 3, 4, 2)
            node = TensorNode(tensor, 1, [2, 3, -1])
            
            # Test tensor_shape
            @test tensor_shape(node) == (3, 4, 2)
            
            # Test log_dimension
            expected_log_dim = log2(3) + log2(4) + log2(2)
            @test log_dimension(node) ≈ expected_log_dim
            
            # Test find_neighbor_index
            @test find_neighbor_index(node, 2) == 1
            @test find_neighbor_index(node, 3) == 2
            @test find_neighbor_index(node, -1) == 3
            @test find_neighbor_index(node, 99) == -1
        end
        
        @testset "Network Analysis" begin
            tensors = [randn(ComplexF64, 2, 3), randn(ComplexF64, 3, 4), randn(ComplexF64, 4, 2)]
            adjacency_lists = [[2, -1], [1, 3], [2, -1]]
            
            tn = TensorNetwork(tensors, adjacency_lists; verbose=false)
            
            # Test complexity analysis
            complexity = network_complexity(tn)
            @test complexity.num_nodes == 3
            @test complexity.num_edges == 2
            @test complexity.total_elements > 0
            
            # Test memory analysis
            memory = memory_usage(tn)
            @test memory.total_bytes > 0
            @test memory.total_mb > 0
        end
    end
    
    @testset "MPS Decomposition" begin
        # Test 2D tensor (should return unchanged)
        tensor_2d = randn(ComplexF64, 3, 4)
        result_2d = mps_decompose(tensor_2d, 10, 1e-10)
        @test size(result_2d) == size(tensor_2d)
        
        # Test higher dimensional tensor
        tensor_4d = randn(ComplexF64, 2, 2, 2, 2)
        result_4d = mps_decompose(tensor_4d, 4, 1e-10)
        
        # Result should be compressed
        @test length(result_4d) <= length(tensor_4d)
    end
    
    @testset "Edge Selection" begin
        tensors = [randn(ComplexF64, 2, 2), randn(ComplexF64, 2, 2)]
        adjacency_lists = [[2], [1]]
        
        tn = TensorNetwork(tensors, adjacency_lists; verbose=false)
        
        # Test minimum dimension heuristic
        edge = select_edge_heuristic(tn, :min_dim)
        @test edge !== nothing
        @test edge in tn.edges
        
        # Test random heuristic
        edge_random = select_edge_heuristic(tn, :random)
        @test edge_random !== nothing
        @test edge_random in tn.edges
    end
    
    @testset "Simple Contraction" begin
        # Test with very simple network
        tensors = [randn(ComplexF64, 2, 2)]
        adjacency_lists = [[-1, -1]]  # Single tensor with open edges
        
        tn = TensorNetwork(tensors, adjacency_lists; verbose=false)
        
        # Should return the single tensor
        result = contract_network!(tn)
        @test isa(result, Array)
    end
end

println("SimpleCATN tests completed! ✅")