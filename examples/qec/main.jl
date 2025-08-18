### A Pluto.jl notebook ###
# v0.20.16

using Markdown
using InteractiveUtils

# ╔═╡ 4ca2e164-7b49-11f0-3832-97601fc3d0c2
using Pkg; Pkg.activate("../.."); Pkg.status()

# ╔═╡ 4ca7bb44-7b49-11f0-087b-35656aa6fd7c
using TensorQEC, TensorQEC.Yao, TensorQEC.OMEinsum, Random

# ╔═╡ 7072c60a-fff2-4e8e-ad33-0be412174e33
md"""
## Tensor network decoding for surface code
First, we generate the stabilizers of the surface code.
"""

# ╔═╡ 186f7287-8b02-4e82-89d1-cb721723ee9e
st = stabilizers(SurfaceCode(3,3))

# ╔═╡ eab5a8ad-e493-43f7-bebe-7a9096d0deda
md"""
Why tanner graph and cite!
"""

# ╔═╡ b4305f5c-cf5b-4b10-8a16-15c3e1c87a0b
tanner = CSSTannerGraph(st);

# ╔═╡ ea4c2857-6be8-49c6-987e-ef6061fa34aa
md"""
Now we generate a depolarizing error model, and randomly generate an error pattern
"""

# ╔═╡ 6bf846f3-901d-424e-ae9e-3f7c549c72b2
error_model = iid_error(0.05,0.05,0.05, 9)

# ╔═╡ 13f71b23-a277-4ec4-851a-6fdd4ec37d5e
Random.seed!(1)

# ╔═╡ dbd5ac0c-4a0c-4f22-9012-5bed0ab68f24
error_pattern = random_error_qubits(error_model)

# ╔═╡ b7b514bc-6629-4355-ab73-05b899b6d858
md"""
Now we can measure the syndrome:
"""

# ╔═╡ d4f699d6-4d2e-4b09-89c7-2e597c7c482d
syndrome = syndrome_extraction(error_pattern, tanner)

# ╔═╡ f1295d36-2ba1-4903-a835-d88ba215e921
md"""
Now we can generate the corresponding tensor network with `compile` function. `TNMMAP` is a tensor network based marginal maximum a posteriori (MMAP) decoder, which finds the most probable logical sector after marginalizing out the error pattern on qubits.
"""

# ╔═╡ 1791953d-cd6f-4a77-85fa-141e1f98e8c0
decoder = TNMMAP();

# ╔═╡ 59e0f320-c5fd-479c-8317-ac6240e11ea6
compiled_decoder = compile(decoder, tanner, error_model);

# ╔═╡ caf88828-bcfa-4962-bddf-9704ec70261b
md"""
The contraction order of the tensor network is optimized by the optimizer `decoder.optimizer`, the default optimizer is `TreeSA()` and the optimal contraction order is stored in `compiled_decoder.code`.
"""

# ╔═╡ e7a4c2f5-49eb-4e37-b4a0-e07c8462cc81
contraction_complexity(compiled_decoder.code,uniformsize(compiled_decoder.code, 2))

# ╔═╡ d1b6186e-e17c-4cd2-a416-8aea87c5dd3d
md"""
We update the syndrome in the tensors of the tensor network and compute the probability of different logical sectors by tensor network contraction.
"""

# ╔═╡ fcf4d0f6-0dea-4600-97b0-d0550a7056fd
TensorQEC.update_syndrome!(compiled_decoder.tensors, syndrome, compiled_decoder.zero_tensor, compiled_decoder.one_tensor);

# ╔═╡ 0bdc1a83-9ff7-4090-a0d8-2abbde2c1927
marginal_probability = compiled_decoder.code(compiled_decoder.tensors...)

# ╔═╡ 63d95e30-f427-484e-9397-92db129a0a92
md"""
Given this marginal probability, we can determine the logical information and further identify an error pattern corresponding to this logical sector. For brevity, we omit the details of this process. The `decode` function combines these computations with tensor network contraction.
"""

# ╔═╡ a8b7a1f1-9ec7-444e-ad1a-f207c13f6a96
result = decode(compiled_decoder, syndrome)

# ╔═╡ 5a7bc163-a8c2-494e-b276-a526ad56ba85
md"""
Finally, we can check whether the decoding result matches the syndrome and whether it contains any logical errors.
"""

# ╔═╡ 4b84bf82-65c8-446f-a327-dfe6a516c3b0
syndrome == syndrome_extraction(result.error_qubits, tanner)

# ╔═╡ 84351bd4-31a2-44fb-96f4-24ea64836f31
lx, lz = logical_operator(tanner);

# ╔═╡ 1e988866-2f37-44ca-bb51-3f0a66e67c03
check_logical_error(result.error_qubits, error_pattern, lx, lz)

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
        "surface_code:rotated_memory_z",  # (rotated) surface code, memory z???
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
# stim file stores the circuit and the error model
qc = parse_stim_file(joinpath(@__DIR__, "data", "surface_code_d=3_r=3.stim"), 26);

# ╔═╡ f9d2e640-681a-4b88-9419-e8401b3e145f
# red boxes are error channels
vizcircuit(qc)

# ╔═╡ 4cab0b64-7b49-11f0-3258-0df4519a55cd
md"""
- The circuit first measure and reset the ancilla qubits to state 0. The unmeasured lines represents the data qubits.
- After each gate, depolarizing error is added.
- Intermediate measurement outcomes are stored into the recorder, annotated by `rec[k]`
- Detectors checks the syndromes, it checks the recorder and computes the XOR of the annotated records.
"""

# ╔═╡ 4cab0b8e-7b49-11f0-2eee-4dd12b945c65
# dem file stores the detector error model, which can be used to sample the errors
# col 1: error probabilities with i.i.d assumption
# col 2: which detectors are flipped
# col 3: which logical operators are flipped
dem = TensorQEC.parse_dem_file(joinpath(@__DIR__, "data", "surface_code_d=3_r=3.dem"))

# ╔═╡ 4cab0ba0-7b49-11f0-2c1a-975e845fd400
md"""
### Generate the tensor network
Now we can generate the corresponding tensor network with `compile` function. `TNMMAP` is a tensor network based marginal maximum a posteriori (MMAP) decoder, which finds the most probable logical sector after marginalizing out the error pattern on qubits. `TreeSA()` is the optimizer for optimizing the tensor network contraction order. `true` means that we want to factorize the tensors to rank-3 tensors to avoid large tensors. (we should do this implicitly)
"""

# ╔═╡ 092ac9b0-263c-498b-9718-e13d25ec9591
compiled_dem_decoder = compile(TNMMAP(TreeSA(ntrials=1), true), dem);

# ╔═╡ 2a36c8a6-25bf-464a-be27-7420a4fa45f8
compiled_dem_decoder.code;

# ╔═╡ 4cab0bc8-7b49-11f0-0201-95da346e4b52
contraction_complexity(compiled_dem_decoder.code,uniformsize(compiled_dem_decoder.code, 2))

# ╔═╡ 4cab0bdc-7b49-11f0-2647-15e2bd859e3c
md"## Compute the probability of different logical sectors by tensor network contraction"

# ╔═╡ b425cfd2-8b2f-4840-9305-5ff1c9c4311e
# Randomly generate an error pattern and measure the syndrome.  ## Should generated from the circuit?
ep = (Random.seed!(1234); random_error_qubits(IndependentFlipError(dem.error_rates)))

# ╔═╡ b3cf81f4-c775-449d-aa96-91fad4d57bbd
syndrome_dem = syndrome_extraction(ep, compiled_dem_decoder.tanner)

# ╔═╡ 5732ec9b-b65a-4db2-8b87-6c6ab3e69eec
# Update the syndrome and compute the probability of different logical sectors by tensor network contraction.
TensorQEC.update_syndrome!(compiled_dem_decoder, syndrome_dem);

# ╔═╡ 960724a5-3f9e-4375-b9b4-b325ad6f0bc5
compiled_dem_decoder.code(compiled_dem_decoder.tensors...)

# ╔═╡ 4cab0c0e-7b49-11f0-26bc-b74e4105ca84
md"""
### Another hard example of [[144,12,12]] BB Code.
This file comes from [https://github.com/quantumlib/tesseract-decoder/tree/main/testdata/bivariatebicyclecodes](https://github.com/quantumlib/tesseract-decoder/tree/main/testdata/bivariatebicyclecodes)
"""

# ╔═╡ 27cffb7b-60de-478f-85c2-9609be6ec574
dem_bb = TensorQEC.parse_dem_file(joinpath(@__DIR__, "data", "r=12,d=12,p=0.001,noise=si1000,c=bivariate_bicycle_X,nkd=[[144,12,12]],q=288,iscolored=True,A_poly=x^3+y+y^2,B_poly=y^3+x+x^2.dem"))

# ╔═╡ 99377317-ee92-4b5a-bc78-194ceabd0d5b
ct = compile(TNMMAP(TensorQEC.NoOptimizer(), true), dem_bb); # Here we use the NoOptimizer to avoid any optimization. Since the code is too large, the default optimizer will be too slow.

# ╔═╡ ef8f08f1-1a40-44b2-afe4-cbc51259a83a
length(ct.code.ixs)

# ╔═╡ 4cab0c2c-7b49-11f0-2d37-fd584e9466ba
# contraction_complexity(ct.code,uniformsize(ct.code, 2))

# ╔═╡ Cell order:
# ╠═4ca2e164-7b49-11f0-3832-97601fc3d0c2
# ╠═4ca7bb44-7b49-11f0-087b-35656aa6fd7c
# ╟─7072c60a-fff2-4e8e-ad33-0be412174e33
# ╠═186f7287-8b02-4e82-89d1-cb721723ee9e
# ╠═eab5a8ad-e493-43f7-bebe-7a9096d0deda
# ╠═b4305f5c-cf5b-4b10-8a16-15c3e1c87a0b
# ╟─ea4c2857-6be8-49c6-987e-ef6061fa34aa
# ╠═6bf846f3-901d-424e-ae9e-3f7c549c72b2
# ╠═13f71b23-a277-4ec4-851a-6fdd4ec37d5e
# ╠═dbd5ac0c-4a0c-4f22-9012-5bed0ab68f24
# ╟─b7b514bc-6629-4355-ab73-05b899b6d858
# ╠═d4f699d6-4d2e-4b09-89c7-2e597c7c482d
# ╟─f1295d36-2ba1-4903-a835-d88ba215e921
# ╠═1791953d-cd6f-4a77-85fa-141e1f98e8c0
# ╠═59e0f320-c5fd-479c-8317-ac6240e11ea6
# ╟─caf88828-bcfa-4962-bddf-9704ec70261b
# ╠═e7a4c2f5-49eb-4e37-b4a0-e07c8462cc81
# ╟─d1b6186e-e17c-4cd2-a416-8aea87c5dd3d
# ╠═fcf4d0f6-0dea-4600-97b0-d0550a7056fd
# ╠═0bdc1a83-9ff7-4090-a0d8-2abbde2c1927
# ╟─63d95e30-f427-484e-9397-92db129a0a92
# ╠═a8b7a1f1-9ec7-444e-ad1a-f207c13f6a96
# ╟─5a7bc163-a8c2-494e-b276-a526ad56ba85
# ╠═4b84bf82-65c8-446f-a327-dfe6a516c3b0
# ╠═84351bd4-31a2-44fb-96f4-24ea64836f31
# ╠═1e988866-2f37-44ca-bb51-3f0a66e67c03
# ╟─4ca94e5a-7b49-11f0-1753-13bfd484cbca
# ╠═dff73ca6-6fea-498b-bca4-06e000942685
# ╠═f9d2e640-681a-4b88-9419-e8401b3e145f
# ╟─4cab0b64-7b49-11f0-3258-0df4519a55cd
# ╠═4cab0b8e-7b49-11f0-2eee-4dd12b945c65
# ╟─4cab0ba0-7b49-11f0-2c1a-975e845fd400
# ╠═092ac9b0-263c-498b-9718-e13d25ec9591
# ╠═2a36c8a6-25bf-464a-be27-7420a4fa45f8
# ╠═4cab0bc8-7b49-11f0-0201-95da346e4b52
# ╟─4cab0bdc-7b49-11f0-2647-15e2bd859e3c
# ╠═b425cfd2-8b2f-4840-9305-5ff1c9c4311e
# ╠═b3cf81f4-c775-449d-aa96-91fad4d57bbd
# ╠═5732ec9b-b65a-4db2-8b87-6c6ab3e69eec
# ╠═960724a5-3f9e-4375-b9b4-b325ad6f0bc5
# ╟─4cab0c0e-7b49-11f0-26bc-b74e4105ca84
# ╠═27cffb7b-60de-478f-85c2-9609be6ec574
# ╠═99377317-ee92-4b5a-bc78-194ceabd0d5b
# ╠═ef8f08f1-1a40-44b2-afe4-cbc51259a83a
# ╠═4cab0c2c-7b49-11f0-2d37-fd584e9466ba
