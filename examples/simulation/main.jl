### A Pluto.jl notebook ###
# v0.20.16

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 24ab1a9a-7b3b-11f0-2569-3df1f2955d62
# check the current environment
using Pkg; Pkg.activate("../.."); Pkg.status()

# ╔═╡ ba2a2526-047a-4d25-a558-ec1d197dbdeb
using Yao, PlutoUI

# ╔═╡ 9669e6e0-998c-4d6e-8fb5-7c99b465ca7a
# circuit reader
include("reader.jl"); using .YaoCircuitReader: yaocircuit_from_file

# ╔═╡ a5404349-bc77-417f-8e78-4f58a6c491e3
using LuxorGraphPlot  # Required by visualization extension

# ╔═╡ 24b20e68-7b3b-11f0-2684-0792efd482b9
md"""
## Circuit loading
Some popular shallow quantum circuits are placed in the `data` folder, they are from [qfelx](https://github.com/s-mandra/qflex) (Ref. qflex datasets, check bottom). To load the circuits to [Yao.jl](https://github.com/QuantumBFS/Yao.jl), please use the `YaoCircuitReader` module provided in file `reader.jl`:
"""

# ╔═╡ 24b5ee52-7b3b-11f0-20c7-658956fed1fe
# check available circuits
readdir(joinpath(@__DIR__, "data", "circuits"))

# ╔═╡ 24b5ee96-7b3b-11f0-12a7-dd2e2f0dc089
md"""
We load the circuit to Julia with [Yao](https://github.com/QuantumBFS/Yao.jl) (幺), a high performance quantum simulator.
"""

# ╔═╡ 24b5eec0-7b3b-11f0-0812-35ba32c4680c
# Hint: please try replacing "test.txt" with "bristlecone_70_1-12-1_0.txt", a circuit with 70 qubits, 12 layers, see what happens
filename = joinpath(@__DIR__, "data", "circuits", "test.txt")

# ╔═╡ ac1115a6-5678-4343-88e2-4ef7d773e7e3
c = yaocircuit_from_file(filename);   # circuit in Yao's data-format

# ╔═╡ bceb5b78-661a-4306-a56a-c4bcd979a6c4
n = nqubits(c)  # number of qubits

# ╔═╡ 171961d1-68c9-48e8-b508-5d48dc1726e9
vizcircuit(c)

# ╔═╡ 24b5eee8-7b3b-11f0-0c04-23b83c038f6b
md"""
## Example 1: compute <0|c|0> with tensor networks

During the convertion, we also specify an optimizer to specify the contraction order.
"""

# ╔═╡ 2e6e1acd-20fe-46e4-89e6-963bbf05d929
net = yao2einsum(c;
			initial_state= Dict(zip(1:n, zeros(Int,n))),
			final_state = Dict(zip(1:n, zeros(Int,n))),
		    optimizer = TreeSA(ntrials=1)  # contraction order optimizer
		)

# ╔═╡ 88c6b213-9819-443f-b0ea-ccbc974bdb0f
# Time complexity: number of arithematic operations
# Space complexity: number of elements in the largest tensor
# Read-write complexity: number of elemental read-write operations
contraction_complexity(net)

# ╔═╡ 12e29146-19df-42df-a8de-f5f73152053b
viznet(net; scale=60)

# ╔═╡ 24b5ef24-7b3b-11f0-1635-737c9e87ebba
md"The space complexity is the number of elements in the largest itermediate tensor. For tensor network backend, it can be a much smaller number compared with the full amplitude simulation given the circuit is shallow enough. Learn more about contraction order optimizers: [https://tensorbfs.github.io/OMEinsumContractionOrders.jl/dev/optimizers/](https://tensorbfs.github.io/OMEinsumContractionOrders.jl/dev/optimizers/)"

# ╔═╡ 24b5ef2e-7b3b-11f0-3008-d15614ad193a
fieldnames(typeof(net))

# ╔═╡ 24b5ef3a-7b3b-11f0-1a4f-e735820b44de
length(net.tensors)

# ╔═╡ 8e280a08-ce6c-4961-ae7f-7569ed0b6ba9
md"""
If your circuit has space complexity less than 28, the tensor newtork is proababily contractable on your local device. Then please go ahead to check the following box.
"""

# ╔═╡ 80714cc8-77e5-469f-ba86-f47546159f57
md"`contract_network` = $(@bind contract_network CheckBox())"

# ╔═╡ 24b5ef42-7b3b-11f0-024f-91ef48dcd568
contract_network && contract(net)[]

# ╔═╡ 1cebfafa-9806-42dc-bca8-03d76136d67d
md"The result should be consistent with the exact simulation."

# ╔═╡ e0b200b7-ffe9-4fa9-b269-5232f28166af
md"`exact_simulate` = $(@bind exact_simulate CheckBox())"

# ╔═╡ 6c1b1ef4-b44c-408a-9420-0f88c102ea34
exact_simulate && apply(zero_state(n), c)' * zero_state(n)

# ╔═╡ 24b5ef56-7b3b-11f0-1966-fd1220651ad3
md"""
## Case 2: Add noise and compute <ψ|X₁X₂|ψ>, where |ψ> = c |0>

During the convertion, we also specify an optimizer to specify the contraction order.
"""

# ╔═╡ fa2ea274-a731-4148-8bdd-d8326cab08a2
mat(c) |> Matrix

# ╔═╡ 3236fab4-ef2c-4f76-8ba2-f56250c85448
# ## Case 2: add noise and compute <ψ|X₁X₂|ψ>, where |ψ> = c |0>
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

# ╔═╡ 7f5b480e-1632-4819-b722-4e3dec908d38
noisy_c = add_depolarizing_noise(c, 0.001);

# ╔═╡ bfcdead1-31af-44ef-b427-31fac064a005
vizcircuit(noisy_c)

# ╔═╡ 9a9f9b2a-4fee-4740-9261-b35991d9efb9
observable = kron(n, 1=>Z, 4=>Z)

# ╔═╡ bbf9005b-20ce-46c9-a786-07a99d798096
noisy_net = yao2einsum(noisy_c;
					   initial_state=Dict(zip(1:n, zeros(Int,n))),
					   observable,
					   optimizer = TreeSA(ntrials=1),
					   mode=DensityMatrixMode())

# ╔═╡ 6c144ddb-50a6-4485-9a7d-25da77f69de9
contraction_complexity(noisy_net)

# ╔═╡ 24b5ef7e-7b3b-11f0-1f8e-8dddae7f921d
viznet(noisy_net; scale=60)

# ╔═╡ c6e2b89e-6a3d-4e91-94a7-cd2d77e4dd6f
md"`contract_noisy` = $(@bind contract_noisy CheckBox())"

# ╔═╡ 24b5ef92-7b3b-11f0-0a85-bffde55b12b8
contract_noisy && contract(noisy_net)

# ╔═╡ d217150f-e253-4fba-aa0b-4cc5b26b118a
md"`exact_noisy` = $(@bind exact_noisy CheckBox())"

# ╔═╡ 424ae2dc-d5e6-490d-b187-fceaf62dbb58
exact_noisy && expect(observable, apply(density_matrix(zero_state(n)), noisy_c))

# ╔═╡ 24b5ef9a-7b3b-11f0-1ca9-27a018a39232
md"""
## References
- **(qflex datasets)** B. Villalonga, et al., "A flexible high-performance simulator for verifying and benchmarking quantum circuits implemented on real hardware", NPJ Quantum Information 5, 86 (2019)
- **(Efficient simulation of noisy circuits)** Gao, Xun, and Luming Duan. "Efficient classical simulation of noisy quantum computation." arXiv preprint arXiv:1810.03176 (2018).
- **Tutorial page of YaoToEinsum**: [https://docs.yaoquantum.org/dev/man/yao2einsum.html](https://docs.yaoquantum.org/dev/man/yao2einsum.html)
"""

# ╔═╡ Cell order:
# ╠═24ab1a9a-7b3b-11f0-2569-3df1f2955d62
# ╟─24b20e68-7b3b-11f0-2684-0792efd482b9
# ╠═ba2a2526-047a-4d25-a558-ec1d197dbdeb
# ╠═9669e6e0-998c-4d6e-8fb5-7c99b465ca7a
# ╠═24b5ee52-7b3b-11f0-20c7-658956fed1fe
# ╟─24b5ee96-7b3b-11f0-12a7-dd2e2f0dc089
# ╠═24b5eec0-7b3b-11f0-0812-35ba32c4680c
# ╠═ac1115a6-5678-4343-88e2-4ef7d773e7e3
# ╠═bceb5b78-661a-4306-a56a-c4bcd979a6c4
# ╠═171961d1-68c9-48e8-b508-5d48dc1726e9
# ╟─24b5eee8-7b3b-11f0-0c04-23b83c038f6b
# ╠═2e6e1acd-20fe-46e4-89e6-963bbf05d929
# ╠═88c6b213-9819-443f-b0ea-ccbc974bdb0f
# ╠═a5404349-bc77-417f-8e78-4f58a6c491e3
# ╠═12e29146-19df-42df-a8de-f5f73152053b
# ╟─24b5ef24-7b3b-11f0-1635-737c9e87ebba
# ╠═24b5ef2e-7b3b-11f0-3008-d15614ad193a
# ╠═24b5ef3a-7b3b-11f0-1a4f-e735820b44de
# ╟─8e280a08-ce6c-4961-ae7f-7569ed0b6ba9
# ╟─80714cc8-77e5-469f-ba86-f47546159f57
# ╠═24b5ef42-7b3b-11f0-024f-91ef48dcd568
# ╟─1cebfafa-9806-42dc-bca8-03d76136d67d
# ╟─e0b200b7-ffe9-4fa9-b269-5232f28166af
# ╠═6c1b1ef4-b44c-408a-9420-0f88c102ea34
# ╟─24b5ef56-7b3b-11f0-1966-fd1220651ad3
# ╠═fa2ea274-a731-4148-8bdd-d8326cab08a2
# ╠═3236fab4-ef2c-4f76-8ba2-f56250c85448
# ╠═7f5b480e-1632-4819-b722-4e3dec908d38
# ╠═bfcdead1-31af-44ef-b427-31fac064a005
# ╠═9a9f9b2a-4fee-4740-9261-b35991d9efb9
# ╠═bbf9005b-20ce-46c9-a786-07a99d798096
# ╠═6c144ddb-50a6-4485-9a7d-25da77f69de9
# ╠═24b5ef7e-7b3b-11f0-1f8e-8dddae7f921d
# ╟─c6e2b89e-6a3d-4e91-94a7-cd2d77e4dd6f
# ╠═24b5ef92-7b3b-11f0-0a85-bffde55b12b8
# ╟─d217150f-e253-4fba-aa0b-4cc5b26b118a
# ╠═424ae2dc-d5e6-490d-b187-fceaf62dbb58
# ╟─24b5ef9a-7b3b-11f0-1ca9-27a018a39232
