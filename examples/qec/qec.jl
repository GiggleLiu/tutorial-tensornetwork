## circuit level decode: surface code as an example
using TensorQEC, OMEinsum

## Exact contraction

d = 9
tanner = CSSTannerGraph(SurfaceCode(d, d))

ct = compile(TNMAP(optimizer=TreeSA()), tanner)

em = iid_error(0.05, 0.05, 0.05, d*d)
ep = random_error_qubits(em)
syn = syndrome_extraction(ep, tanner)

# TODO: visualize syndrome

res = decode(ct, syn)

# TODO: visualize decoding result

syndrome_extraction(res.error_qubits, tanner) == syn

## Belief propagation

## Open problem: B. B. Code