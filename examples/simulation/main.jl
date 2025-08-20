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
# `PlutoUI` is for control gadgets, e.g. the checkboxes
using PlutoUI

# ╔═╡ f06c5c12-6721-42a3-896d-d75f3f487883
using OMEinsum   # Tensor network contraction backend

# ╔═╡ 1ef56e59-11a2-4460-a5ce-cebcdef62ec3
using BenchmarkTools  # use for benchmark

# ╔═╡ 5fdbc76c-f8ac-4fd1-b5d1-51dd7df6283f
using Graphs  # used for constructing graphs

# ╔═╡ c32e072a-5d26-4e61-bec3-3d90da466abb
using Yao   # Quantum circuit simulator

# ╔═╡ 9669e6e0-998c-4d6e-8fb5-7c99b465ca7a
# circuit reader
include("reader.jl"); using .YaoCircuitReader: yaocircuit_from_file

# ╔═╡ a5404349-bc77-417f-8e78-4f58a6c491e3
using LuxorGraphPlot  # Required by visualization extension

# ╔═╡ d70997f3-71ca-4240-b771-afd682e0ee10
md"# Quantum circuit simulation with tensor network contraction"

# ╔═╡ 1b4cfe64-d698-4cf6-bc0a-548acb049cb4
md"Link to the tutorial repository: [https://github.com/GiggleLiu/tutorial-tensornetwork](https://github.com/GiggleLiu/tutorial-tensornetwork)"

# ╔═╡ 1c65281e-f374-4cc7-b139-39d7a07970a9
PlutoUI.TableOfContents(aside=false)

# ╔═╡ 95e973b9-36bf-4279-a195-944f70ba0a74
md"## Tutorial: einsum notation"

# ╔═╡ ac1a4063-0aab-4e16-9e58-2cbf4fd3285b
md"""In this tutorial, we use [OMEinsum.jl](https://github.com/under-Peter/OMEinsum.jl) as our default tensor network contractor.
- State of the art performance in optimizing the contraction order
- Has GPU support
"""

# ╔═╡ 2511cebe-290b-4c42-a07c-c6acea3fe21e
md"Specify a tensor network with string literal `ein`"

# ╔═╡ 50973ca4-636a-47cf-a654-4170b05af63d
# `->` separates the input and output tensors
# `,` separates the indices of different input tensors
# each char represents an index

code = ein"ab,bc,cd->ad"  # using string literal

# ╔═╡ 3ab377e0-77f7-4726-a90a-51e317b2e12d
md"or programmatically"

# ╔═╡ ab1523d3-edfb-45a4-b63f-6d06d3117f09
EinCode([[1,2], [2, 3], [3, 4]], [1, 4]) # alternatively

# ╔═╡ 5cb8978f-2744-48f5-b203-9dbf28138bc6
getixsv(code)   # indices for input tensors

# ╔═╡ 45ead3b1-6d00-405f-bb1f-039d6c95a30c
getiyv(code)    # indices for the output tensor

# ╔═╡ 52b28fed-44df-4a27-91a9-058486b4cc0e
md"`variable_dimension` = $(variable_dimension = @bind variable_dimension Slider(1:100, default=2, show_value=true))"

# ╔═╡ d19208d4-d6c0-4b89-9c4c-6fcc29d69e58
label_sizes = uniformsize(code, variable_dimension)  # define the sizes of the indices

# ╔═╡ f75fa80f-0d77-44e6-bd94-c18c147fc856
# Time complexity: number of arithematic operations
# Space complexity: number of elements in the largest tensor
# Read-write complexity: number of elemental read-write operations
contraction_complexity(code, label_sizes)

# ╔═╡ 2bb754ae-60b6-4b6a-9fce-c6b758da6573
code(randn(2, 2), randn(2, 2), randn(2, 2))  # not recommended

# ╔═╡ b21822d7-09ac-4654-b465-72a1d6c2d5ea
nested_code = ein"(ab,bc),cd->ad"  # recommended

# ╔═╡ 2ffa144c-fcf5-4557-803d-c62c87f4633e
contraction_complexity(nested_code, label_sizes)

# ╔═╡ e573d942-790d-4605-86e7-038c9f680c99
md"`run_benchmark` = $(@bind run_benchmark CheckBox())"

# ╔═╡ 2e9a3226-8f3f-49b8-8b63-dade011b7528
run_benchmark && @btime code(randn(100, 100), randn(100, 100), randn(100, 100)); # unoptimized

# ╔═╡ 4418cd21-d42c-486a-b3f4-b93566e3ce24
run_benchmark && @btime nested_code(randn(100, 100), randn(100, 100), randn(100, 100)); # optimized

# ╔═╡ 10e53b4a-92fc-4df5-81ba-f8ed192c9bbc
md"
Reasons why order matters:
1. Contraction order reduces the computational complexity
2. Binary contraction can make use of BLAS
"

# ╔═╡ 3b5fe2ee-dbb7-4c97-9074-dd2b50e7f005
md"""### Contraction order optimization
- Contracting a tensor network is #P-hard, the complexity is $O(2^{{\rm tw}(\overline{T})})$, i.e. exponential to the tree width of the line graph of the tensor network hypergraph topology $T$.
- Optimizing the contraction order is NP-hard
"""

# ╔═╡ 4e84a98c-23f6-45c1-884c-bd5214cd0ba9
function demo_network(n::Int; seed=2)
	# random regular graph
    g = random_regular_graph(n, 3; seed)
	# place a matrix on each edge
    code = EinCode([[e.src, e.dst] for e in edges(g)], Int[])
	# each input matrix has size 2x2
    sizes = uniformsize(code, 2)
    tensors = [randn([sizes[leg] for leg in ix]...) for ix in getixsv(code)]
    return code, tensors, sizes
end

# ╔═╡ 04772512-2827-42ef-b348-e000eb14d32d
code_r3, tensors_r3, sizes_r3 = demo_network(100);

# ╔═╡ ed1ec4bd-e33a-4925-87b8-fc77f359d64c
optcode = optimize_code(
	code_r3,   # tensor network topology
	sizes_r3,  # variable sizes
	TreeSA()   # optimizer
);

# ╔═╡ 81e1f9c0-21b5-476f-b225-356f2dccae80
cc_r3 = contraction_complexity(optcode, sizes_r3)

# ╔═╡ 5ff2ba46-add0-4e6f-b137-da553de4c373
md"For more choices of optimizers, please check: [OMEinsumContractionOrdersBenchmark](https://github.com/TensorBFS/OMEinsumContractionOrdersBenchmark) and [issue](https://github.com/TensorBFS/OMEinsumContractionOrders.jl/issues/58#issuecomment-3100527416)"

# ╔═╡ 5de1f7fe-c57b-4e35-adce-76d2d83910fb
# reduce the memory cost by slicing
sliced_code = slice_code(
	optcode,
	sizes_r3,
	TreeSASlicer(score=ScoreFunction(sc_target=cc_r3.sc-3))  # keep slicing until the space complexity target `sc_target` is reached.
);

# ╔═╡ f50074c6-9e86-46b0-8bec-71ef1b521ec5
cc_r3_sliced = contraction_complexity(sliced_code, sizes_r3)

# ╔═╡ e7d40cf3-3aeb-4861-9661-21e6e177636a
md"## Example 1: GHZ state generation circuit"

# ╔═╡ 685f9abb-2ebe-4377-b284-9f40d9cebe7e
md"""
We use [Yao.jl](https://github.com/QuantumBFS/Yao.jl) as our default quantum simulation tool.
  - State of the art performance, has GPU support
  - Supports tensor network backend
  - Supports noisy channel simulation
"""

# ╔═╡ c5a3865a-701d-436f-b320-0cbfeaaef83d
md"Let us first define a GHZ state generation circuit."

# ╔═╡ 04073c5e-3a52-4a6e-b242-a8098b66f018
# chain: connect the component gates
# put(n, k=>G): place gate G at location k of a n qubits system.
# control(n, c, k=>G): place controlled gate G at location k, c is the control qubit
ghz_circuit(n) = chain(put(n, 1=>H), [control(n, i-1, i=>X) for i=2:n]...)

# ╔═╡ 43cd6549-cf66-409f-a8d8-2f6a6812c5bb
vizcircuit(ghz_circuit(4))

# ╔═╡ 32fef0de-5eb6-49d9-974c-8d872fc2fe65
# 1st argument is a Yao circuit
# `initial_state` takes a dictionary
# `final_state` is left unspecified
net_ghz = yao2einsum(ghz_circuit(4);
		initial_state= Dict(zip(1:4, zeros(Int,4))),
		optimizer = TreeSA(ntrials=1)  # contraction order optimizer
	)

# ╔═╡ 53467c66-43b3-49e3-8499-b2bc5e730541
md"The tensor network contraction is represented as a binary tree. It contains both the tensor network topology and an optimized contraction order."

# ╔═╡ 644b8135-e302-4da7-bca7-6927436b26cf
net_ghz.code  # contraction code in (nested) einsum notation

# ╔═╡ 24b5ef2e-7b3b-11f0-3008-d15614ad193a
fieldnames(typeof(net_ghz))

# ╔═╡ 7ac4a056-2669-46e5-8781-4c5ffd0118e9
OMEinsum.getixsv(net_ghz.code)  # input tensor labels

# ╔═╡ 24b5ef3a-7b3b-11f0-1a4f-e735820b44de
length(net_ghz.tensors)   # input tensor data

# ╔═╡ bbe8da89-c08f-49ad-b880-21097bc5e3ae
OMEinsum.getiyv(net_ghz.code)  # open indices

# ╔═╡ c93ff4e5-037f-4718-8aaf-93f755809d52
# red/gray nodes are variables/open variables, transparent nodes are tensors
# 0 tensor is defined as: [1, 0]
# + tensor is the XOR gate
viznet(net_ghz; scale=60)

# ╔═╡ 21c90cee-912c-4709-a50e-b920bb7f9083
contraction_complexity(net_ghz)

# ╔═╡ f81fb594-2fea-4f02-8da3-0a591f66415a
Yao.contract(net_ghz)

# ╔═╡ b1e38f66-5b3d-4d73-bc51-d2250938a846
md"## Example 2: Simulate quantum supremacy experiments"

# ╔═╡ 068abc9b-d80b-4d78-ac91-9e17fe47e389
md"In this example, we will load the quantum supremacy circuit from the disk, and compute probability of having state $|0\rangle$ by computing $\langle 0|U|0\rangle$, where $U$ is the quantum circuit of interest."

# ╔═╡ 24b20e68-7b3b-11f0-2684-0792efd482b9
md"""
### Step 1: circuit loading
Some popular shallow quantum circuits are placed in the `data` folder, they are from [qfelx](https://github.com/s-mandra/qflex) (Ref. qflex datasets, check bottom). To load the circuits to Yao, please use the `YaoCircuitReader` module provided in file `reader.jl`:
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
### Step 2: construct tensor network

During the convertion, we also specify an optimizer to specify the contraction order.
"""

# ╔═╡ 2e6e1acd-20fe-46e4-89e6-963bbf05d929
net = yao2einsum(c;
			initial_state= Dict(zip(1:n, zeros(Int,n))),
			final_state = Dict(zip(1:n, zeros(Int,n))),
		    optimizer = TreeSA(ntrials=1)  # contraction order optimizer
		)

# ╔═╡ 88c6b213-9819-443f-b0ea-ccbc974bdb0f
contraction_complexity(net)

# ╔═╡ 12e29146-19df-42df-a8de-f5f73152053b
# red nodes are variables, transparent nodes are tensors
# h = [1 1; 1 -1] is the unnormalized version of Hadamard gate
# 0 tensor is defined as: [1, 0]
viznet(net; scale=60)

# ╔═╡ 24b5ef24-7b3b-11f0-1635-737c9e87ebba
md"The space complexity is the number of elements in the largest itermediate tensor. For tensor network backend, it can be a much smaller number compared with the full amplitude simulation given the circuit is shallow enough. Learn more about contraction order optimizers: [https://tensorbfs.github.io/OMEinsumContractionOrders.jl/dev/optimizers/](https://tensorbfs.github.io/OMEinsumContractionOrders.jl/dev/optimizers/)"

# ╔═╡ 7336bc5d-d155-4116-976e-94958aa42fef
md"### Step 3: contract the tensor network"

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
## Example 3: Construct tensor network for computing observables (channel simulation)

In this example, we show how to compute $\langle ψ|X₁X₂|ψ\rangle$ through quantum channel simulation, where $|ψ\rangle = U |0\rangle$, where $U$ is the quantum circuit with interest.
During the convertion, we also specify an optimizer to specify the contraction order.
"""

# ╔═╡ 3236fab4-ef2c-4f76-8ba2-f56250c85448
# add depolarizing noise
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

# ╔═╡ 308ebb49-dc4b-4fa2-8bdc-1d791915bbd8
md"Hint: please change the noise probability see how the result change with it."

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
# the green dots are dual variables
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
# ╟─d70997f3-71ca-4240-b771-afd682e0ee10
# ╟─1b4cfe64-d698-4cf6-bc0a-548acb049cb4
# ╠═24ab1a9a-7b3b-11f0-2569-3df1f2955d62
# ╠═ba2a2526-047a-4d25-a558-ec1d197dbdeb
# ╠═1c65281e-f374-4cc7-b139-39d7a07970a9
# ╟─95e973b9-36bf-4279-a195-944f70ba0a74
# ╟─ac1a4063-0aab-4e16-9e58-2cbf4fd3285b
# ╠═f06c5c12-6721-42a3-896d-d75f3f487883
# ╟─2511cebe-290b-4c42-a07c-c6acea3fe21e
# ╠═50973ca4-636a-47cf-a654-4170b05af63d
# ╟─3ab377e0-77f7-4726-a90a-51e317b2e12d
# ╠═ab1523d3-edfb-45a4-b63f-6d06d3117f09
# ╠═5cb8978f-2744-48f5-b203-9dbf28138bc6
# ╠═45ead3b1-6d00-405f-bb1f-039d6c95a30c
# ╟─52b28fed-44df-4a27-91a9-058486b4cc0e
# ╠═d19208d4-d6c0-4b89-9c4c-6fcc29d69e58
# ╠═f75fa80f-0d77-44e6-bd94-c18c147fc856
# ╠═2bb754ae-60b6-4b6a-9fce-c6b758da6573
# ╠═b21822d7-09ac-4654-b465-72a1d6c2d5ea
# ╠═2ffa144c-fcf5-4557-803d-c62c87f4633e
# ╠═1ef56e59-11a2-4460-a5ce-cebcdef62ec3
# ╟─e573d942-790d-4605-86e7-038c9f680c99
# ╠═2e9a3226-8f3f-49b8-8b63-dade011b7528
# ╠═4418cd21-d42c-486a-b3f4-b93566e3ce24
# ╟─10e53b4a-92fc-4df5-81ba-f8ed192c9bbc
# ╟─3b5fe2ee-dbb7-4c97-9074-dd2b50e7f005
# ╠═5fdbc76c-f8ac-4fd1-b5d1-51dd7df6283f
# ╠═4e84a98c-23f6-45c1-884c-bd5214cd0ba9
# ╠═04772512-2827-42ef-b348-e000eb14d32d
# ╠═ed1ec4bd-e33a-4925-87b8-fc77f359d64c
# ╠═81e1f9c0-21b5-476f-b225-356f2dccae80
# ╟─5ff2ba46-add0-4e6f-b137-da553de4c373
# ╠═5de1f7fe-c57b-4e35-adce-76d2d83910fb
# ╠═f50074c6-9e86-46b0-8bec-71ef1b521ec5
# ╟─e7d40cf3-3aeb-4861-9661-21e6e177636a
# ╟─685f9abb-2ebe-4377-b284-9f40d9cebe7e
# ╠═c32e072a-5d26-4e61-bec3-3d90da466abb
# ╟─c5a3865a-701d-436f-b320-0cbfeaaef83d
# ╠═04073c5e-3a52-4a6e-b242-a8098b66f018
# ╠═43cd6549-cf66-409f-a8d8-2f6a6812c5bb
# ╠═32fef0de-5eb6-49d9-974c-8d872fc2fe65
# ╟─53467c66-43b3-49e3-8499-b2bc5e730541
# ╠═644b8135-e302-4da7-bca7-6927436b26cf
# ╠═24b5ef2e-7b3b-11f0-3008-d15614ad193a
# ╠═7ac4a056-2669-46e5-8781-4c5ffd0118e9
# ╠═24b5ef3a-7b3b-11f0-1a4f-e735820b44de
# ╠═bbe8da89-c08f-49ad-b880-21097bc5e3ae
# ╠═c93ff4e5-037f-4718-8aaf-93f755809d52
# ╠═21c90cee-912c-4709-a50e-b920bb7f9083
# ╠═f81fb594-2fea-4f02-8da3-0a591f66415a
# ╟─b1e38f66-5b3d-4d73-bc51-d2250938a846
# ╟─068abc9b-d80b-4d78-ac91-9e17fe47e389
# ╟─24b20e68-7b3b-11f0-2684-0792efd482b9
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
# ╟─7336bc5d-d155-4116-976e-94958aa42fef
# ╟─8e280a08-ce6c-4961-ae7f-7569ed0b6ba9
# ╟─80714cc8-77e5-469f-ba86-f47546159f57
# ╠═24b5ef42-7b3b-11f0-024f-91ef48dcd568
# ╟─1cebfafa-9806-42dc-bca8-03d76136d67d
# ╟─e0b200b7-ffe9-4fa9-b269-5232f28166af
# ╠═6c1b1ef4-b44c-408a-9420-0f88c102ea34
# ╟─24b5ef56-7b3b-11f0-1966-fd1220651ad3
# ╠═3236fab4-ef2c-4f76-8ba2-f56250c85448
# ╟─308ebb49-dc4b-4fa2-8bdc-1d791915bbd8
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
