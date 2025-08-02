using Yao

# circuit reader
include("reader.jl")
using .YaoQASMReader: yaocircuit_from_qasm

using OMEinsum

function main(; optimizer=TreeSA(), circuit_name = "sycamore_53_8_0")
    @info("Running circuit `$(circuit_name)` with optimizer: $(optimizer)")

    # Create the TensorNetworkCircuit object for the circuit
    file = joinpath(@__DIR__, "data", circuit_name * ".txt")
    c = yaocircuit_from_qasm(file)
    time_elapsed = @elapsed net = yao2einsum(c; initial_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), final_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), optimizer)
    @info "Contraction complexity: $(contraction_complexity(net)), time cost: $(time_elapsed)s"
    return contraction_complexity(net)
end

main()