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

# ╔═╡ 4ca2e164-7b49-11f0-3832-97601fc3d0c2
using Pkg; Pkg.activate("../.."); Pkg.status()

# ╔═╡ 4ca7bb44-7b49-11f0-087b-35656aa6fd7c
# `TensorQEC` utilizes the tensor network to study the properties of quantum error correction.
# `Yao` is a quantum simulator.
# `OMEinsum` is a tensor network contraction engine.
# `PlutoUI` is for control gadgets, e.g. the checkboxes
using TensorQEC, Yao, OMEinsum, Random, PlutoUI

# ╔═╡ 2cc025a6-142d-4145-a8c0-df171efd8d04
md"""
# Tensor network decoding for quantum error correction code
In this tutorial, we will use the tensor network to decode quantum error correction code with [TensorQEC.jl](https://github.com/nzy1997/TensorQEC.jl), which is a package contains multiple error correction methods, including integer programming decoder, tensor net work decoder, belief propagation decoder and so on. It could serve as a good starting point to benchmark different QEC decoding algorithms.
"""

# ╔═╡ 6eaef728-8b05-4e25-ba3d-f51d149bb988
PlutoUI.TableOfContents(aside=false)

# ╔═╡ 7072c60a-fff2-4e8e-ad33-0be412174e33
md"""
## Tensor network decoding for surface code
Decoding is a process to extract the error pattern from the syndrome. So, we will start from generating a syndrome for a quantum code.
"""

# ╔═╡ f16f3a9d-f8dd-42c0-b094-aa33b6e3ed85
md"""
### Step 1: define the code and error model
As a first example, we use the d=3 surface code, and the error model is independent depolarizing errors on each qubit.
"""

# ╔═╡ 00807971-4e26-435f-9534-098dab49f227
surface3 = SurfaceCode(3,3)

# ╔═╡ eab5a8ad-e493-43f7-bebe-7a9096d0deda
md"""
For covenience, we use the Tanner graph represetation of QEC codes in the following, as it offers a more convenient framework for syndrome extraction and decoding.
"""

# ╔═╡ b4305f5c-cf5b-4b10-8a16-15c3e1c87a0b
# `CSSTannerGraph` returns the tanner graph for a CSS quantum code.
tanner = CSSTannerGraph(surface3);

# ╔═╡ 6bf846f3-901d-424e-ae9e-3f7c549c72b2
# `iid_error` generates independent errors on each qubit
# The first three arguments are the error probabilities for X, Y, and Z errors, respectively.
# The last argument is the number of qubits.
error_model = iid_error(0.05, 0.05, 0.05, 9)

# ╔═╡ 6fb5f71b-9a66-4d16-9063-ab70149c489a
md"Then we generate a random error pattern"

# ╔═╡ dbd5ac0c-4a0c-4f22-9012-5bed0ab68f24
# `random_error_pattern` generates a random error pattern from the error model.
error_pattern = (Random.seed!(2); random_error_pattern(error_model))

# ╔═╡ b7b514bc-6629-4355-ab73-05b899b6d858
md"""
In practise, we will not see these error patterns, instead, we will get the error syndrome through measurements.
"""

# ╔═╡ d4f699d6-4d2e-4b09-89c7-2e597c7c482d
# `syndrome_extraction` takes a error pattern and a taner graph, returns the syndrome.
syndrome = syndrome_extraction(error_pattern, tanner)

# ╔═╡ 51330426-fd9e-4eeb-a084-a00fd3d7b036
md"""The goal is to infer the error pattern or its equivalent form from the above syndrome. Here, two error patterns are "equivalent", if and only if they can be reduced to each other by applying some stabilizers.
"""

# ╔═╡ 89b3099b-65cf-46df-b005-ee05b3e479d6
md"### Step 2: tensor network representation"

# ╔═╡ f1295d36-2ba1-4903-a835-d88ba215e921
md"""
The tensor network representation can be generated with the `compile` function, with the `TNMMAP` as the first argument. TNMMAP means Tensor Network based Marginal Maximum A Posteriori decoder.
"""

# ╔═╡ 1791953d-cd6f-4a77-85fa-141e1f98e8c0
# - `TreeSA()` is the optimizer for optimizing the tensor network contraction order.
compiled_decoder = compile(
	TNMMAP(; optimizer=TreeSA()),  # tensor network based decoder (Piveteau2024)
	tanner,
	error_model
);

# ╔═╡ caf88828-bcfa-4962-bddf-9704ec70261b
md"""
The contraction order of the tensor network is optimized by the optimizer `decoder.optimizer`, the default optimizer is `TreeSA()` and the optimal contraction order is stored in `compiled_decoder.code`.
"""

# ╔═╡ 4f202513-ea0a-4490-ac27-cefd462d4a47
# The tensor network topology
compiled_decoder.code

# ╔═╡ cf24bc7a-8040-4e83-8aff-c44b84e4c87e
md"The output is associated with the open indices at the top level, which is [27, 28]. They correspond to the marginal probabilities of logical X and Z flip."

# ╔═╡ d585574c-7077-4f21-a64a-bc263e5dba7b
# The tensor network data, here we have 27 tensors
compiled_decoder.tensors |> length

# ╔═╡ e7a4c2f5-49eb-4e37-b4a0-e07c8462cc81
# Time complexity: number of arithematic operations
# Space complexity: number of elements in the largest tensor
# Read-write complexity: number of elemental read-write operations
contraction_complexity(compiled_decoder)

# ╔═╡ ea4c2857-6be8-49c6-987e-ef6061fa34aa
md"""
### Step 3: decode
"""

# ╔═╡ a8b7a1f1-9ec7-444e-ad1a-f207c13f6a96
# `decode` function takes a compiled decoder and a syndrome, returns the decoding outcome. We will see what is actully happenes in this decode function.
# The decoder saves the deduced error pattern in `docoding_result.error_pattern`.
decoding_result = decode(compiled_decoder, syndrome)

# ╔═╡ f10fa13a-82d4-4bde-98b8-b4d83d7a5638
decoding_result.error_pattern

# ╔═╡ 5a7bc163-a8c2-494e-b276-a526ad56ba85
md"""
We can check whether the decoding result matches the syndrome.
"""

# ╔═╡ 4b84bf82-65c8-446f-a327-dfe6a516c3b0
syndrome == syndrome_extraction(decoding_result.error_pattern, tanner)

# ╔═╡ d1b6186e-e17c-4cd2-a416-8aea87c5dd3d
md"""
#### Tensor network decoder, explained

We firstly update the syndrome in the tensors of the tensor network and compute the probability of different logical sectors by tensor network contraction.
"""

# ╔═╡ fcf4d0f6-0dea-4600-97b0-d0550a7056fd
TensorQEC.update_syndrome!(compiled_decoder, syndrome);

# ╔═╡ 0bdc1a83-9ff7-4090-a0d8-2abbde2c1927
# the contraction result is the marginal probabilities on lx and lz
# p(no logical flip) = 0.00174541
# p(logical Z flip) = 0.014687
# p(logical X flip) = 4.50585e-5
# p(logical X and Z flip) = 0.000231682
marginal_probability = compiled_decoder.code(compiled_decoder.tensors...)

# ╔═╡ 63d95e30-f427-484e-9397-92db129a0a92
md"""
Given this marginal probability, we can determine the logical information and further identify an error pattern corresponding to this logical sector.
"""

# ╔═╡ ed7d0c5c-2b80-4da7-866a-8ced1532b978
# find the Cartesian coordinate of the most likely logical error
_, pos = findmax(marginal_probability)

# ╔═╡ 4a7f8d2b-71e0-4bbd-9d41-372db49d4e16
# Infer error pattern from the logical error.
# To correct errors on a physical device, just apply the same error pattern
TensorQEC.error_pattern(pos, compiled_decoder, syndrome)

# ╔═╡ 4ca94e5a-7b49-11f0-1753-13bfd484cbca
md"""
## Circuit-level Quanutm Error Correction Decoding Problem
In quantum error correction, circuit-level decoding refers to the challenge of accurately identifying and correcting errors that occur during the execution of a quantum circuit, where errors may arise from imperfect gates, measurements, or idle qubit storage. Unlike idealized noise models, circuit-level noise incorporates realistic spatial and temporal correlations, making decoding more complex due to the interplay of gate errors, leakage, and crosstalk.
### Load data
The quantum circuits and the corresponding detector error model is placed under the `data` folder. Here we load the syndrome measurement circuit of code distance `d=3`, error correction cycle `r=3` surface code and the corresponding detector error model. It is generated with [stim](https://github.com/quantumlib/Stim) package.

```python
import stim

for d in [3, 5, 7, 9]:
    circuit = stim.Circuit.generated(
        "surface_code:rotated_memory_z",  # (rotated) surface code. z means the circuit initializes and measures the logical Z basis observable.
        rounds=d,                         # number of measurements rounds
        distance=d,
        after_clifford_depolarization=0.001,  # depolarizing errors
        after_reset_flip_probability=0.001,
        before_measure_flip_probability=0.001,
        before_round_data_depolarization=0.001)  # before each round
    circuit.to_file(f"data/surface_code_d={d}_r={d}.stim") # stim file
    dem = circuit.detector_error_model(flatten_loops=True)
    dem.to_file(f"data/surface_code_d={d}_r={d}.dem")  # dem file
```
"""

# ╔═╡ dff73ca6-6fea-498b-bca4-06e000942685
# stim file stores the circuit
qc = parse_stim_file(joinpath(@__DIR__, "data", "surface_code_d=3_r=3.stim"), 26);

# ╔═╡ f9d2e640-681a-4b88-9419-e8401b3e145f
# red boxes are error channels
# Hint: to zoom the circuit, please right click and open it in a new tab
vizcircuit(qc)

# ╔═╡ 4cab0b64-7b49-11f0-3258-0df4519a55cd
md"""
- The circuit first measure and reset the ancilla qubits to state 0. The unmeasured lines represents the data qubits.
- After each gate, depolarizing error is added.
- Intermediate measurement outcomes are stored into the recorder, annotated by `rec[k]`
- Detectors checks the syndromes, it checks the recorder and computes the XOR of the annotated records.
"""

# ╔═╡ 4cab0b8e-7b49-11f0-2eee-4dd12b945c65
# dem file stores the detector error model, which can be used to sample the errors and decode. This model is usually obtained from Clifford circuit simulation.
# col 1: error index
# col 2: error probabilities with i.i.d assumption
# col 3: which detectors are flipped
# col 4: which logical operators are flipped
dem = TensorQEC.parse_dem_file(joinpath(@__DIR__, "data", "surface_code_d=3_r=3.dem"))

# ╔═╡ 4cab0ba0-7b49-11f0-2c1a-975e845fd400
md"""
### Generate the tensor network
"""

# ╔═╡ 092ac9b0-263c-498b-9718-e13d25ec9591
compiled_dem_decoder = compile(TNMMAP(; optimizer=TreeSA(ntrials=1)), dem);

# ╔═╡ 09c37b01-e82f-44fb-b610-6b7eff0563de
contraction_complexity(compiled_dem_decoder)

# ╔═╡ b425cfd2-8b2f-4840-9305-5ff1c9c4311e
# Generate an error pattern and the corresponding syndrome.
syndrome_dem = let
	Random.seed!(2)
	error_pattern = random_error_pattern(IndependentFlipError(dem.error_rates))
	syndrome_extraction(error_pattern, compiled_dem_decoder.tanner)
end

# ╔═╡ 5732ec9b-b65a-4db2-8b87-6c6ab3e69eec
# update the tensor network
TensorQEC.update_syndrome!(compiled_dem_decoder, syndrome_dem);

# ╔═╡ 960724a5-3f9e-4375-b9b4-b325ad6f0bc5
compiled_dem_decoder.code(compiled_dem_decoder.tensors...)

# ╔═╡ 4cab0c0e-7b49-11f0-26bc-b74e4105ca84
md"""
### Challenge: Tensor network decoder for [[144,12,12]] BB Code.
The circuit level decoder for BB code is notoriously hard problem for tensor network decoders. Here, we load the dem file from [https://github.com/quantumlib/tesseract-decoder/tree/main/testdata/bivariatebicyclecodes](https://github.com/quantumlib/tesseract-decoder/tree/main/testdata/bivariatebicyclecodes). The belief propagation based approach is efficient, but the accuracy is not enough. The integer programming based approach is only efficient when the error rate is low enough (check below). For additional decoders applicable to this example, please refer to (Beni2025).

Goal: Develop a decoder that achieves both high accuracy and computational efficiency.
"""

# ╔═╡ 27cffb7b-60de-478f-85c2-9609be6ec574
dem_bb = TensorQEC.parse_dem_file(joinpath(@__DIR__, "data", "r=12,d=12,p=0.001,noise=si1000,c=bivariate_bicycle_X,nkd=[[144,12,12]],q=288,iscolored=True,A_poly=x^3+y+y^2,B_poly=y^3+x+x^2.dem"))

# ╔═╡ 99377317-ee92-4b5a-bc78-194ceabd0d5b
compiled_dem_decoder_bb = compile(TNMMAP(; optimizer=TensorQEC.NoOptimizer()), dem_bb); # Here we use the NoOptimizer to avoid any optimization. Since the code is too large, the default optimizer will be too slow.

# ╔═╡ ef8f08f1-1a40-44b2-afe4-cbc51259a83a
length(compiled_dem_decoder_bb.code.ixs)

# ╔═╡ 25c583c9-d5ee-42a5-a852-ff8722ff1162
md"`compute_complexity` = $(@bind compute_complexity CheckBox())"

# ╔═╡ 4cab0c2c-7b49-11f0-2d37-fd584e9466ba
# Too slow!
if compute_complexity
	contraction_complexity(compiled_dem_decoder_bb)
end

# ╔═╡ bf2eeeb5-9d83-44d1-8d59-bd7260be4c80
md"It has ~585k tensors! Can you come up with a tensor network based decoder for it?"

# ╔═╡ a18e130d-1e61-4dbf-a226-9bc962354dd2
md"""
#### The performance of integer programming decoder
"""

# ╔═╡ d131882f-8d6e-4703-afd1-898c394d0626
syndrome_bb = let
Random.seed!(110);error_pattern = random_error_pattern(dem_bb)
syndrome_extraction(error_pattern, compiled_dem_decoder_bb.tanner)
end

# ╔═╡ c04c3a4d-a13d-4037-b073-24bc5c299335
let
# decode with a integer programming decoder
res = decode(IPDecoder(),compiled_dem_decoder_bb.tanner,syndrome_bb) 

# test weather we get a same syndrome
syndrome_bb == syndrome_extraction(res.error_pattern, compiled_dem_decoder_bb.tanner)
end

# ╔═╡ 784fdc67-2cfb-4855-9f22-dc17728af54e
md"Integer programming decoder takes about 30 seconds. Can you beat it?"

# ╔═╡ dac4001b-e265-4219-9ee5-e175b9bc732a
md"""
## References
- **(Piveteau2024)** Piveteau, C.; Chubb, C. T.; Renes, J. M. Tensor Network Decoding Beyond 2D. PRX Quantum 2024, 5 (4), 040303. https://doi.org/10.1103/PRXQuantum.5.040303.
- **(Beni2025)** Beni, L. A.; Higgott, O.; Shutty, N. Tesseract: A Search-Based Decoder for Quantum Error Correction. arXiv March 14, 2025. https://doi.org/10.48550/arXiv.2503.10988.
"""

# ╔═╡ Cell order:
# ╟─2cc025a6-142d-4145-a8c0-df171efd8d04
# ╠═4ca2e164-7b49-11f0-3832-97601fc3d0c2
# ╠═4ca7bb44-7b49-11f0-087b-35656aa6fd7c
# ╟─6eaef728-8b05-4e25-ba3d-f51d149bb988
# ╟─7072c60a-fff2-4e8e-ad33-0be412174e33
# ╟─f16f3a9d-f8dd-42c0-b094-aa33b6e3ed85
# ╠═00807971-4e26-435f-9534-098dab49f227
# ╟─eab5a8ad-e493-43f7-bebe-7a9096d0deda
# ╠═b4305f5c-cf5b-4b10-8a16-15c3e1c87a0b
# ╠═6bf846f3-901d-424e-ae9e-3f7c549c72b2
# ╟─6fb5f71b-9a66-4d16-9063-ab70149c489a
# ╠═dbd5ac0c-4a0c-4f22-9012-5bed0ab68f24
# ╟─b7b514bc-6629-4355-ab73-05b899b6d858
# ╠═d4f699d6-4d2e-4b09-89c7-2e597c7c482d
# ╟─51330426-fd9e-4eeb-a084-a00fd3d7b036
# ╟─89b3099b-65cf-46df-b005-ee05b3e479d6
# ╟─f1295d36-2ba1-4903-a835-d88ba215e921
# ╠═1791953d-cd6f-4a77-85fa-141e1f98e8c0
# ╟─caf88828-bcfa-4962-bddf-9704ec70261b
# ╠═4f202513-ea0a-4490-ac27-cefd462d4a47
# ╟─cf24bc7a-8040-4e83-8aff-c44b84e4c87e
# ╠═d585574c-7077-4f21-a64a-bc263e5dba7b
# ╠═e7a4c2f5-49eb-4e37-b4a0-e07c8462cc81
# ╟─ea4c2857-6be8-49c6-987e-ef6061fa34aa
# ╠═a8b7a1f1-9ec7-444e-ad1a-f207c13f6a96
# ╠═f10fa13a-82d4-4bde-98b8-b4d83d7a5638
# ╟─5a7bc163-a8c2-494e-b276-a526ad56ba85
# ╠═4b84bf82-65c8-446f-a327-dfe6a516c3b0
# ╟─d1b6186e-e17c-4cd2-a416-8aea87c5dd3d
# ╠═fcf4d0f6-0dea-4600-97b0-d0550a7056fd
# ╠═0bdc1a83-9ff7-4090-a0d8-2abbde2c1927
# ╟─63d95e30-f427-484e-9397-92db129a0a92
# ╠═ed7d0c5c-2b80-4da7-866a-8ced1532b978
# ╠═4a7f8d2b-71e0-4bbd-9d41-372db49d4e16
# ╟─4ca94e5a-7b49-11f0-1753-13bfd484cbca
# ╠═dff73ca6-6fea-498b-bca4-06e000942685
# ╠═f9d2e640-681a-4b88-9419-e8401b3e145f
# ╟─4cab0b64-7b49-11f0-3258-0df4519a55cd
# ╠═4cab0b8e-7b49-11f0-2eee-4dd12b945c65
# ╟─4cab0ba0-7b49-11f0-2c1a-975e845fd400
# ╠═092ac9b0-263c-498b-9718-e13d25ec9591
# ╠═09c37b01-e82f-44fb-b610-6b7eff0563de
# ╠═b425cfd2-8b2f-4840-9305-5ff1c9c4311e
# ╠═5732ec9b-b65a-4db2-8b87-6c6ab3e69eec
# ╠═960724a5-3f9e-4375-b9b4-b325ad6f0bc5
# ╟─4cab0c0e-7b49-11f0-26bc-b74e4105ca84
# ╠═27cffb7b-60de-478f-85c2-9609be6ec574
# ╠═99377317-ee92-4b5a-bc78-194ceabd0d5b
# ╠═ef8f08f1-1a40-44b2-afe4-cbc51259a83a
# ╟─25c583c9-d5ee-42a5-a852-ff8722ff1162
# ╠═4cab0c2c-7b49-11f0-2d37-fd584e9466ba
# ╟─bf2eeeb5-9d83-44d1-8d59-bd7260be4c80
# ╟─a18e130d-1e61-4dbf-a226-9bc962354dd2
# ╠═d131882f-8d6e-4703-afd1-898c394d0626
# ╠═c04c3a4d-a13d-4037-b073-24bc5c299335
# ╠═784fdc67-2cfb-4855-9f22-dc17728af54e
# ╟─dac4001b-e265-4219-9ee5-e175b9bc732a
