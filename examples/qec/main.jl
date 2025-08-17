### A Pluto.jl notebook ###
# v0.20.16

using Markdown
using InteractiveUtils

# ╔═╡ 4ca2e164-7b49-11f0-3832-97601fc3d0c2
using Pkg; Pkg.activate("../.."); Pkg.status()

# ╔═╡ 4ca7bb44-7b49-11f0-087b-35656aa6fd7c
using TensorQEC, TensorQEC.Yao, TensorQEC.OMEinsum, Random

# ╔═╡ 4ca94e5a-7b49-11f0-1753-13bfd484cbca
md"""
## Circuit-level Quanutm Error Correction Decoding Problem
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
compiled_decoder = compile(TNMMAP(TreeSA(ntrials=1), true), dem);

# ╔═╡ 2a36c8a6-25bf-464a-be27-7420a4fa45f8
compiled_decoder.code;

# ╔═╡ 4cab0bc8-7b49-11f0-0201-95da346e4b52
contraction_complexity(compiled_decoder.code,uniformsize(compiled_decoder.code, 2))

# ╔═╡ 4cab0bdc-7b49-11f0-2647-15e2bd859e3c
md"## Compute the probability of different logical sectors by tensor network contraction"

# ╔═╡ b425cfd2-8b2f-4840-9305-5ff1c9c4311e
# Randomly generate an error pattern and measure the syndrome.  ## Should generated from the circuit?
ep = (Random.seed!(1234); random_error_qubits(IndependentFlipError(dem.error_rates)))

# ╔═╡ b3cf81f4-c775-449d-aa96-91fad4d57bbd
syndrome = syndrome_extraction(ep, compiled_decoder.tanner)

# ╔═╡ 5732ec9b-b65a-4db2-8b87-6c6ab3e69eec
# Update the syndrome and compute the probability of different logical sectors by tensor network contraction.
TensorQEC.update_syndrome!(compiled_decoder, syndrome);

# ╔═╡ 960724a5-3f9e-4375-b9b4-b325ad6f0bc5
compiled_decoder.code(compiled_decoder.tensors...)

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
