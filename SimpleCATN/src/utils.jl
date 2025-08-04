"""
Utility functions for SimpleCATN.

This file contains helper functions for tensor operations, 
canonical forms, and tensor network analysis.
"""

"""
    tensor_shape(node::TensorNode)

Get the shape of the tensor stored in the node.
"""
tensor_shape(node::TensorNode) = size(node.tensor)

"""
    log_dimension(node::TensorNode, exclude_idx::Int=-1)

Compute the logarithm of the total dimension, optionally excluding an index.
"""
function log_dimension(node::TensorNode, exclude_idx::Int=-1)
    dims = size(node.tensor)
    if exclude_idx > 0 && exclude_idx <= length(dims)
        dims = dims[setdiff(1:length(dims), exclude_idx)]
    end
    return sum(log2.(dims))
end

"""
    find_neighbor_index(node::TensorNode, neighbor_id::Int)

Find the tensor index corresponding to a neighbor.
"""
function find_neighbor_index(node::TensorNode, neighbor_id::Int)
    for (i, neighbor) in enumerate(node.neighbors)
        if neighbor == neighbor_id
            return i
        end
    end
    return -1
end

"""
    left_canonical!(node::TensorNode)

Convert tensor to left canonical form using QR decomposition.
"""
function left_canonical!(node::TensorNode)
    if ndims(node.tensor) <= 1
        return
    end
    
    # Reshape to matrix for QR
    dims = size(node.tensor)
    left_dim = dims[1]
    right_dim = prod(dims[2:end])
    
    mat = reshape(node.tensor, left_dim, right_dim)
    Q, R = qr(mat)
    
    # Update tensor
    node.tensor = reshape(Matrix(Q), dims[1], size(Q, 2))
    node.canonical_center = 1
end

"""
    right_canonical!(node::TensorNode)

Convert tensor to right canonical form using LQ decomposition.
"""
function right_canonical!(node::TensorNode)
    if ndims(node.tensor) <= 1
        return
    end
    
    # Reshape to matrix for LQ (using QR on transpose)
    dims = size(node.tensor)
    left_dim = prod(dims[1:end-1])
    right_dim = dims[end]
    
    mat = reshape(node.tensor, left_dim, right_dim)
    Q, R = qr(mat')  # LQ = (QR on transpose)
    
    # Update tensor
    node.tensor = reshape(Matrix(Q'), size(R, 2), dims[end])
    node.canonical_center = ndims(node.tensor)
end

"""
    dimension_after_merge(tn::TensorNetwork, i::Int, j::Int)

Estimate the log dimension of the tensor after merging nodes i and j.
"""
function dimension_after_merge(tn::TensorNetwork, i::Int, j::Int)
    if !haskey(tn.nodes, i) || !haskey(tn.nodes, j)
        return Inf
    end
    
    node_i = tn.nodes[i]
    node_j = tn.nodes[j]
    
    # Find the connecting edge dimension
    neighbor_idx = find_neighbor_index(node_i, j)
    if neighbor_idx <= 0
        return Inf
    end
    
    dim_i = log_dimension(node_i)
    dim_j = log_dimension(node_j)
    connecting_dim = log2(size(node_i.tensor, neighbor_idx))
    
    # Result dimension is sum minus twice the connecting dimension
    return dim_i + dim_j - 2 * connecting_dim
end

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

"""
    network_complexity(tn::TensorNetwork)

Estimate the computational complexity of contracting the tensor network.
"""
function network_complexity(tn::TensorNetwork)
    total_elements = 0
    max_tensor_size = 0
    
    for (id, node) in tn.nodes
        tensor_size = length(node.tensor)
        total_elements += tensor_size
        max_tensor_size = max(max_tensor_size, tensor_size)
    end
    
    return (
        total_elements = total_elements,
        max_tensor_size = max_tensor_size,
        num_nodes = length(tn.nodes),
        num_edges = length(tn.edges),
        estimated_log_complexity = log2(total_elements) + length(tn.edges)
    )
end

"""
    memory_usage(tn::TensorNetwork)

Estimate memory usage of the tensor network.
"""
function memory_usage(tn::TensorNetwork)
    total_memory = 0
    
    for (id, node) in tn.nodes
        # Estimate memory for complex numbers (16 bytes each typically)
        tensor_memory = sizeof(node.tensor)
        total_memory += tensor_memory
    end
    
    return (
        total_bytes = total_memory,
        total_mb = total_memory / (1024^2),
        avg_tensor_mb = total_memory / (1024^2) / length(tn.nodes)
    )
end