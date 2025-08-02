using OMEinsum, Graphs

function demo_network(n::Int)
    g = random_regular_graph(n, 3)
    code = EinCode([[e.src, e.dst] for e in edges(g)], Int[])
    sizes = uniformsize(code, 2)
    tensors = [randn([sizes[leg] for leg in ix]...) for ix in getixsv(code)]
    return code, tensors, sizes
end

code, tensors, sizes = demo_network(100)

# contraction order optimization
optcode = optimize_code(code, sizes, TreeSA())
cc = contraction_complexity(optcode, sizes)

# autodiff
cost_and_gradient(optcode, (tensors...,))

# slicing
sliced_code = slice_code(optcode, sizes, TreeSASlicer(score=ScoreFunction(sc_target=cc.sc-3)))
sliced_code.slicing

@assert sliced_code(tensors...) ≈ optcode(tensors...)

