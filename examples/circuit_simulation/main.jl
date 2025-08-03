using Yao

# circuit reader
include("reader.jl")
using .YaoQASMReader: yaocircuit_from_qasm
using OMEinsum

function dump_network(input::String; bitstring, output_folder, sc_target::Int=Inf, optimizer=TreeSA(ntrials=1), overwrite=false)
    filename = joinpath(@__DIR__, "data", "circuits", input)
    output = joinpath(@__DIR__, "data", "networks", output_folder)
    isfile(output) && !overwrite && return

    c = yaocircuit_from_qasm(filename)
    initial_state = Dict(zip(1:nqubits(c), zeros(Int,nqubits(c))))
    final_state = Dict(zip(1:nqubits(c), bitstring))
    net = yao2einsum(c; initial_state, final_state, optimizer, slicer=TreeSASlicer(score=ScoreFunction(sc_target=sc_target)))

    # save the network
    YaoToEinsum.save_tensor_network(net; folder=output)
    return c
end

function dump_noisy_network(input::String; observable, depolarizing, output_folder, sc_target::Int=Inf, optimizer=TreeSA(ntrials=1), overwrite=false)
    filename = joinpath(@__DIR__, "data", "circuits", input)
    output = joinpath(@__DIR__, "data", "networks_noisy", output_folder)
    isfile(output) && !overwrite && return

    c = yaocircuit_from_qasm(filename)
    noisy_c = add_depolarizing_noise(c, depolarizing)
    initial_state = Dict(zip(1:nqubits(noisy_c), zeros(Int,nqubits(noisy_c))))
    net = yao2einsum(noisy_c; initial_state, observable, optimizer, slicer=TreeSASlicer(score=ScoreFunction(sc_target=sc_target)), mode=DensityMatrixMode())

    # save the network
    YaoToEinsum.save_tensor_network(net; folder=output)
    return noisy_c
end

function add_depolarizing_noise(c::AbstractBlock, depolarizing)
    Optimise.replace_block(c) do blk
        if blk isa PutBlock || blk isa ControlBlock
            rep = chain(blk)
            for loc in occupied_locs(blk)
                push!(rep, put(nqubits(blk), loc=>DepolarizingChannel(1, depolarizing)))
            end
            return rep
        else
            return blk
        end
    end
end

function main()
    for filename in readdir(joinpath(@__DIR__, "data", "circuits"))
        @info "Processing $filename"
        c = dump_network(filename, bitstring=zeros(Int, nqubits(yaocircuit_from_qasm(joinpath(@__DIR__, "data", "circuits", filename)))), output_folder=filename[1:end-4], sc_target=30)
        # net = load_tensor_network(joinpath(@__DIR__, "data", "networks", filename[1:end-4]))
        dump_noisy_network(filename, observable=kron(nqubits(c), 1=>X, 2=>X), depolarizing=0.01, output_folder=filename[1:end-4], sc_target=30)
    end
end

main()