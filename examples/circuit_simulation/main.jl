using Yao

# circuit reader
include("reader.jl")
using .YaoQASMReader: yaocircuit_from_qasm

# load a visualize
filename = joinpath(@__DIR__, "data", "sycamore_53_8_0.txt")
@info "Circuit: $(filename)"
c = yaocircuit_from_qasm(filename)
vizcircuit(c)

# convert to tensor network and optimize the contraction order
optimizer = TreeSA(ntrials=1)
time_elapsed = @elapsed net = yao2einsum(c; initial_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), final_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), optimizer)
@info "Contraction complexity: $(contraction_complexity(net)), time cost: $(time_elapsed)s"

# contract!
contract(net)