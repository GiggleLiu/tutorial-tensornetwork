using Yao

# circuit reader
include("reader.jl")
using .YaoQASMReader: yaocircuit_from_qasm

# load a visualize
filename = joinpath(@__DIR__, "data", "sycamore_53_8_0.txt")
@info "Circuit: $(filename)"
c = yaocircuit_from_qasm(filename)
vizcircuit(c)

# # convert to tensor network and optimize the contraction order
# ## Case 1: compute <0|c|0>
optimizer = TreeSA(ntrials=1)
time_elapsed = @elapsed net = yao2einsum(c; initial_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), final_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), optimizer)
@info "Contraction complexity: $(contraction_complexity(net)), time cost: $(time_elapsed)s"
psi0 = contract(net)

# ## Case 2: add noise and compute <ψ|X₁X₂|ψ>, where |ψ> = c |0>
function add_noise(c::AbstractBlock; depolarizing1, depolarizing2)
    Optimise.replace_block(c) do blk
        if blk isa PrimitiveBlock && nqubits(blk) == 1  # two qubits
            return chain(blk, DepolarizingChannel(1, depolarizing1))
        elseif (blk isa PrimitiveBlock || blk isa ControlBlock) && nqubits(blk) == 2
            return chain(blk, DepolarizingChannel(2, depolarizing2))
        else
            return blk
        end
    end
end
noisy_c = add_noise(c; depolarizing1=0.01, depolarizing2=0.01)
vizcircuit(noisy_c)
time_elapsed = @elapsed net = yao2einsum(c; initial_state=Dict(zip(1:nqubits(c), zeros(Int,nqubits(c)))), observable=kron(nqubits(c), 1=>X, 2=>X), optimizer, mode=DensityMatrixMode())
@info "Contraction complexity: $(contraction_complexity(net)), time cost: $(time_elapsed)s"
# xx = contract(net)