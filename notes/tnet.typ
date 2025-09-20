#import "@preview/cetz:0.4.0": canvas, draw, tree, coordinate
#import "@preview/cetz-plot:0.1.2": *
#import "@preview/ctheorems:1.1.3": *
#import "@preview/ouset:0.2.0": ouset
#import "@preview/quill:0.7.1": *
// #import "@preview/qec-thrust:0.1.0": *

#set math.equation(numbering: "(1)")
#show link: set text(blue)
#show heading.where(level: 1): set text(20pt)
#show: thmrules

#show raw.where(block: true): it=>{
  block(fill:rgb("#fcf9ec"),inset:1.5em,width:99%,text(it))
}

#let definition = thmbox("definition", "Definition", inset: (x: 1.2em, top: 1em, bottom: 1em), base: none, stroke: none, fill: rgb("#e8f4fd"), namefmt: x => [(#strong[#x.])], titlefmt: x => [(#emph[#x])])
#let theorem = thmbox("theorem", "Theorem", base: none, stroke: none, fill: rgb("#f0f9e8"), namefmt: x => [(#strong[#x.])], titlefmt: x => [(#emph[#x])])
#let lemma = thmbox("lemma", "Lemma", base: "theorem", stroke: none, fill: rgb("#f0f9e8"), namefmt: x => [(#strong[Lemma #x.])], titlefmt: x => [(#emph[#x])])
#let corollary = thmbox("corollary", "Corollary", base: "theorem", stroke: none, fill: rgb("#f0f9e8"), namefmt: x => [(#strong[Corollary #x.])], titlefmt: x => [(#emph[#x])])
#let proposition = thmbox("proposition", "Proposition", base: "theorem", stroke: none, fill: rgb("#f0f9e8"), namefmt: x => [(#strong[Proposition #x.])], titlefmt: x => [(#emph[#x])])
#let proof = thmproof("proof", "Proof")
#let ket(it) = [$|#it angle.r$]

// hide contents under development
#let hide-dev = true
#let dev(it) = if not hide-dev {it}
#let hide-solution = false
#let solution(it) = if not hide-solution {[*Solution:*\ #it]}

#let exampleblock(it) = block(fill: rgb("#ffffff"), width:100%, inset: 1em, radius: 4pt, stroke: black, it)
#let tensor(location, name, label) = {
  import draw: *
  circle(location, radius: 10pt, name: name)
  content((), text(black, label))
}

#let labelnode(loc, label, name: none) = {
  import draw: *
  content(loc, text(black, label), align: center, fill:silver, frame:"rect", padding:0.07, stroke: none, name: name)
}
#let labeledge(from, to, label, name: none) = {
  import draw: *
  line(from, to, name: "line")
  if label != none {
    labelnode("line.mid", label, name: name)
  }
}

#let infobox(title, body, stroke: blue) = {
  set text(black)
  set align(left)
  rect(
    stroke: stroke,
    inset: 8pt,
    radius: 4pt,
    width: 100%,
    [*#title:*\ #body],
  )
}

#align(center, [#text(22pt)[Tensor Networks for quantum circuit simulation and quantum error correction]\ #v(1em)
_Jin-Guo Liu_ and _Zhong-Yi Ni_\
Advanced Materials Thrust, Function Hub, HKUST(GZ)])
#v(1em)
#outline(depth: 2)

#pagebreak()

= Tensor Networks

== Representations of Multilinear Algebra
A _tensor network_ is a mathematical framework that represents multilinear algebra operations as intuitive graphical structures, where tensors become nodes and shared indices become connecting edges. This diagrammatic approach transforms complex high-dimensional contractions into accessible visual networks that expose underlying computational structure.

The framework exhibits remarkable universality, emerging across diverse domains: _einsum_ notation@Harris2020 in numerical computing, _factor graphs_@Bishop2006 in probabilistic inference, _sum-product networks_ in machine learning, and _junction trees_@Villescas2023 in graphical models. Tensor networks have revolutionized quantum circuit simulation@Markov2008, quantum error correction@Piveteau2024, neural network compression@Qing2024, and strongly correlated quantum materials@Haegeman2016.


#definition([Multilinear algebra])[
  _Multilinear algebra_ is the study of functions that are linear in each of their arguments separately. A function $f: V_1 times V_2 times dots times V_k -> W$ is called _multilinear_ if it is linear with respect to each argument when all other arguments are held fixed. That is, for any $i in {1, 2, dots, k}$ and fixed values of all arguments except the $i$-th, the function
  $
  v_i mapsto f(v_1, dots, v_(i-1), v_i, v_(i+1), dots, v_k)
  $
  is linear. The canonical example is the inner product $angle.l x, y angle.r$, which is _bilinear_—linear in $x$ when $y$ is fixed, and linear in $y$ when $x$ is fixed.
]

To build intuition, we begin by recalling that a function $f$ is _linear_ if it satisfies the fundamental properties of additivity, where $f(x + y) = f(x) + f(y)$ for any vectors $x$ and $y$, and homogeneity, where $f(alpha x) = alpha f(x)$ for any scalar $alpha$. 

Consider the chain multiplication of matrices:
$
  O_(i n) = sum_(j,k,l,m) A_(i j) B_(j k) C_(k l) D_(l m) E_(m n)
$ <eq:tensor-contraction>
This expression exemplifies a _tensor contraction_—a multilinear map where the output $O_(i n)$ depends linearly on each input tensor $A, B, C, D, E$. The summation over repeated indices $(j, k, l, m)$ constitutes the "contraction" operation that eliminates internal degrees of freedom.

#exampleblock([
*Exercise: Multilinear algebra*

Identify the multilinear algebra in the following expression
1. scalar product: $f(x, y, z) = x y z$
2. trace multiplication: $f(A, B, C) = tr(A B C)$
3. kronecker product: $f(X, Y, Z) = X times.circle Y times.circle Z$
4. addition: $f(x, y, z) = x + y + z$

#solution([
  1. Yes
  2. Yes
  3. Yes
  4. No
])
])

#definition([Tensor Network])[
  A _tensor network_ is a mathematical framework for defining multilinear maps, which can be represented by a triple $cal(N) = (Lambda, cal(T), V_0)$, where:
  - $Lambda$ is the set of variables (indices) present in the network $cal(N)$
  - $cal(T) = {T_(V_k)}_(k=1)^K$ is the set of input tensors, where each tensor $T_(V_k)$ is associated with the index set $V_k$
  - $V_0$ specifies the indices of the output tensor
  
  Each tensor $T_(V_k) in cal(T)$ is labeled by a set of variables $V_k subset.eq Lambda$, where the cardinality $|V_k|$ equals the rank of $T_(V_k)$. The variables in $Lambda without V_0$ are the internal indices that will be contracted (summed over).
]

#definition([Tensor network contraction])[
  The multilinear map, or _contraction_, applied to a tensor network $cal(N) = (Lambda, cal(T), V_0)$ is defined as:
  $
  T_(V_0) = "contract"(Lambda, cal(T), V_0) := sum_(m in "dom"(Lambda without V_0)) product_(T_V in cal(T)) T_V (m)
  $
  where $m$ represents an assignment of values to the variables in $Lambda without V_0$, and the summation runs over all possible such assignments.
]

#exampleblock([
*Example*: Matrix multiplication can be described as the contraction of a tensor network:
$
(A B)_({i, k}) = "contract"({i,j,k}, {A_({i, j}), B_({j, k})}, {i, k})
$
where matrices $A$ and $B$ are input tensors with variable sets ${i, j}$ and ${j, k}$ respectively, which are subsets of $Lambda = {i, j, k}$. The output tensor has variables ${i, k}$ and the summation runs over variables $Lambda without {i, k} = {j}$. The contraction corresponds to:
$
(A B)_({i, k}) = sum_j A_({i,j}) B_({j, k})
$ <eq:matrix-multiplication-contraction>

In the following discussion, we will ignore the set notation and use the more compact subscript notation for the variable sets: $(A B)_(i k) = sum_j A_(i j) B_(j k)$.
])

*Generalization*: This definition introduces a minor generalization of the standard tensor network definition commonly used in physics. It allows a label to appear more than twice across the tensors in the network, deviating from the conventional practice of restricting each label to two appearances. This generalized form, while maintaining the same level of representational power, has been demonstrated to potentially reduce the network's treewidth, a metric that measures its connectivity.

#definition([Tensor network diagram])[
  A _tensor network diagram_ is a graphical representation of a tensor network that provides an intuitive visualization of the mathematical structure. In this representation:
  - Each tensor $T_i in cal(T)$ becomes a _node_ (represented as a circle or geometric shape)
  - Each index of tensor $T_i$ becomes an _edge_ or "leg" extending from the corresponding node
  - Internal indices become _internal edges_ connecting different nodes that share the same index
  - External indices become _external edges_ representing the dimensions of the final result
  
  The diagram transforms abstract index manipulations into intuitive network topology where the computational structure becomes immediately apparent.
]

This graphical notation extends the algebraic concept of tensor contraction through powerful visual representation, rendering complex multilinear operations more accessible and revealing underlying computational structure that guides optimization strategies.

#align(center, text(10pt, canvas({
  import draw: *
  tensor((-7, 1), "V", [$V$])
  labeledge("V", (rel: (0, 1.5)), [$i$])
  content((rel: (0, -1), to: "V"), [Vector $V_i$])
  tensor((-3, 1), "M", [$M$])
  labeledge("M", (rel: (-1.5, 0)), [$i$])
  labeledge("M", (rel: (1.5, 0)), [$j$])
  content((rel: (0, -1), to: "M"), [Matrix $M_(i j)$])
  tensor((1, 1), "A", [$A$])
  labeledge("A", (rel: (1.5, 0)), [$i$])
  labeledge("A", (rel: (0, 1.5)), [$j$])
  labeledge("A", (rel: (-1.5, 0)), [$k$])
  content((rel: (0, -1), to: "A"), [Rank-3 tensor $A_(i j k)$])
})))

The diagrammatic representation of @eq:tensor-contraction reveals the underlying structure more clearly:
#align(center, text(10pt, canvas({
  import draw: *
  let tensors = ("A", "B", "C", "D", "E")
  for (i, t) in tensors.enumerate() {
    tensor((1.5*i, 1), t, [$#t$])
  }
  for (label, (a, b)) in (("j", ("A", "B")), ("k", ("B", "C")), ("l", ("C", "D")), ("m", ("D", "E"))) {
    labeledge(a, b, label)
  }
  labeledge("A", (rel: (-1, 0)), "i")
  labeledge("E", (rel: (1, 0)), "n")
})))

This visual approach proves indispensable when analyzing complex tensor contractions, as illustrated in the following example.

#exampleblock([
*Example: Trace Permutation Rule*

The cyclic property of matrix traces provides an excellent introduction to tensor network reasoning. Consider three square matrices $A$, $B$, and $C$ of compatible dimensions. The trace permutation rule states:
$
"tr"(A B C) = "tr"(C A B) = "tr"(B C A)
$

In the algebraic proof, this identity follows from the definition of matrix multiplication and trace, but requires careful index manipulation. In the tensor network approach, the graphical approach reveals why this identity holds at a topological level.

#figure(canvas({
  import draw: *
  tensor((1, 1), "A", "A")
  tensor((3, 1), "B", "B")
  tensor((5, 1), "C", "C")
  labeledge("A", "B", "j")
  labeledge("B", "C", "k")
  bezier("A.north", "C.north", (1, 3), (5, 3), name:"line")
  content("line.mid", "i", align: center, fill:white, frame:"rect", padding:0.1, stroke: none)
}), numbering: none)

The tensor network reveals the essential structure—a closed loop where indices connect cyclically. The trace operation corresponds to this loop contraction, and the cyclic symmetry becomes immediately apparent.

*Key lesson*: Regardless of where we "cut" the loop to begin algebraic evaluation, the result remains identical. The three expressions $"tr"(A B C)$, $"tr"(C A B)$, and $"tr"(B C A)$ represent the same geometric object viewed from different starting points. This topological invariance provides deeper insight than purely algebraic derivations.
])

#exampleblock([
*Exercise: Tensor network diagram*

Draw the tensor network diagram for the multilinear algebra operations in the first excerise.
#solution([
  1. #align(center, text(10pt, canvas({
  import draw: *
  tensor((0, 0), "x", [$x$])
  tensor((1, 0), "y", [$y$])
  tensor((2, 0), "z", [$z$])
})))
2. see above.
3. #align(center, text(10pt, canvas({
  import draw: *
  tensor((0, 0), "X", [$X$])
  tensor((1, 0), "Y", [$Y$])
  tensor((2, 0), "Z", [$Z$])
  line("X", (rel: (0, 0.7)))
  line("X", (rel: (0, -0.7)))
  line("Y", (rel: (0, 0.7)))
  line("Y", (rel: (0, -0.7)))
  line("Z", (rel: (0, 0.7)))
  line("Z", (rel: (0, -0.7)))
})))
])
])

== Einsum Notation and Computational Complexity

#definition([Einsum notation])[
  _Einsum notation_ (short for "Einstein summation notation") is a compact string-based representation for specifying tensor network topologies and contractions. The notation consists of:
  - Input tensor specifications on the left side, separated by commas
  - The symbol `->` separating inputs from outputs
  - Output tensor specification on the right side
  - Each character represents a unique tensor index
  
  The contraction rules are:
  - Indices appearing only on the right side become output dimensions
  - Indices appearing on the left but not on the right are summed over (contracted)
  
  For example, matrix multiplication $C = A B$ is represented as `ij,jk->ik`, where $i$ and $k$ are preserved output indices, and $j$ is contracted (summed over).
]

In computational practice, this notation provides a concise way to encode contraction structure through simple syntax, making complex tensor operations easily readable and implementable.

#exampleblock([
*Exercise: Einsum notation*

1. Express the multilinear algebra operations in the first excerise using einsum notation.
 #solution([
  1. `,,->`
  2. `ij,jk,ki->`
  3. `ij,kl,mn->ikmjln`
])
2. Identify the operations:
  1. `aa->`
  2. `aa->a`
  3. `ab->`
  4. `ijl,jkl->ikl`
  5. `i->ii`
  6. `->i`
  7. `j,j->`
  8. `i,j->ij`

  #solution([
    1. `aa->`: trace of a matrix
    2. `aa->a`: diagonal extraction of a matrix
    3. `ab->`: summation of a matrix
    4. `ijl,jkl->ikl`: batched matrix multiplication
    5. `i->ii`: create a diagonal matrix from a vector
    6. `->i`: broadcast a scalar into a vector
    7. `j,j->`: dot product of two vectors
    8. `i,j->ij`: outer product of two vectors
  ])
])

The following examples use the #link("https://github.com/under-Peter/OMEinsum.jl", "OMEinsum") package to demonstrate tensor network specification, contraction order optimization, and execution. Tensor network topologies can be defined using either the convenient `ein` string literal or the more flexible `EinCode` constructor for programmatic construction.

```julia
julia> using OMEinsum

julia> code = ein"ab,bc,cd->ad"  # using string literal
ab, bc, cd -> ad

julia> EinCode([[1,2], [2, 3], [3, 4]], [1, 4]) # alternatively
1∘2, 2∘3, 3∘4 -> 1∘4
```

Its defining properties can be obtained with the `getixsv` and `getiyv` functions.
```julia
julia> getixsv(code)  # get the indices of the input tensors
3-element Vector{Vector{Char}}:
 ['a', 'b']
 ['b', 'c']
 ['c', 'd']

julia> getiyv(code)  # get the indices of the output tensor
2-element Vector{Char}:
 'a': ASCII/Unicode U+0061 (category Ll: Letter, lowercase)
 'd': ASCII/Unicode U+0064 (category Ll: Letter, lowercase)
```

The complexity of the contraction can be computed with the `contraction_complexity` function. It requires the sizes of the indices, which can be specified with a dictionary that maps the indices to their sizes. Here, we use the `uniformsize` function to specify that all indices have the same size.

```julia
julia> label_sizes = uniformsize(code, 100)  # define the sizes of the indices
Dict{Char, Int64} with 4 entries:
  'a' => 100
  'c' => 100
  'd' => 100
  'b' => 100

julia> contraction_complexity(code, label_sizes)
Time complexity: 2^26.575424759098897
Space complexity: 2^13.287712379549449
Read-write complexity: 2^15.287712379549449
```

Tensor contraction complexity can be analyzed through three complementary lenses:

*Time complexity* ($≈ 100^4$ operations): The total number of floating-point operations (FLOPs) required for contraction. For einsum operations, this generally equals the product of all unique index dimensions—each combination of index values requires one multiplication and addition. Crucially, intelligent contraction ordering can dramatically reduce this from exponential to polynomial scaling.

*Space complexity* ($≈ 100^2$ elements): The peak memory footprint needed to store the largest intermediate tensor during contraction. This represents the computational "bottleneck" that determines whether a calculation is feasible on available hardware.

*Read-write complexity* ($≈ 4 × 100^2$ operations): The total memory bandwidth consumed by transferring all intermediate results between storage and processor. On modern architectures where memory access often dominates arithmetic costs, this metric frequently determines practical performance.

While `EinCode` objects are callable and can directly perform contractions:

```julia
julia> code(randn(2, 2), randn(2, 2), randn(2, 2))  # not recommended
2×2 Matrix{Float64}:
 -0.974692  3.06151
 -0.674225  1.40281
```

This direct approach is *strongly discouraged* because `OMEinsum` defaults to an unoptimized contraction order that can be exponentially inefficient. The naive left-to-right evaluation frequently creates unnecessarily large intermediate tensors.

A superior approach explicitly specifies the contraction order using parentheses to guide the computation:

```julia
julia> nested_code = ein"(ab,bc),cd->ad"
ac, cd -> ad
├─ ab, bc -> ac
│  ├─ ab
│  └─ bc
└─ cd
```

The resulting `NestedEinsum` object represents a structured two-step contraction: first computing the intermediate tensor from the first two inputs, then contracting this result with the third tensor. This explicit ordering achieves dramatic complexity reduction:

```julia
julia> contraction_complexity(nested_code, label_sizes)
Time complexity: 2^20.931568569324174
Space complexity: 2^13.287712379549449
Read-write complexity: 2^15.872674880270605
```

Beyond theoretical complexity improvements, practical performance gains are even more substantial. `OMEinsum` leverages optimized BLAS routines for binary tensor contractions, leading to remarkable speedups:

```julia
julia> using BenchmarkTools

julia> @btime code(randn(100, 100), randn(100, 100), randn(100, 100)); # unoptimized
  86.418 ms (36 allocations: 385.48 KiB)

julia> @btime nested_code(randn(100, 100), randn(100, 100), randn(100, 100)); # optimized
  133.167 μs (157 allocations: 486.06 KiB)
```

This represents over 600× speedup, demonstrating how proper contraction ordering transforms intractable computations into practical ones.

// #raw(read("examples/basic/basic.jl"), lang: "julia", block: true)

#exampleblock([
*Example A: Star Contraction Pattern*

Star contractions demonstrate how tensor networks can create higher-dimensional outputs from matrix inputs. Given three matrices $A, B, C in bb(R)^(n times n)$, the star contraction produces a rank-3 tensor:
$
O_(i j k) = sum_a A_(i a) B_(a j) C_(a k)
$

*Geometric interpretation*: Three matrices "radiate" from a central summation index $a$, creating a star-like topology. This pattern frequently appears in quantum many-body problems and machine learning applications.

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((-1.0, 0), "A", s[$A$])
  tensor((1.0, 0), "B", s[$B$])
  tensor((0, 1.0), "C", s[$C$])
  labeledge("A", (rel: (-1.2, 0)), s[$i$])
  labeledge("B", (rel: (1.2, 0)), s[$j$])
  labeledge("C", (rel: (0, 1.2)), s[$k$])
  labelnode((0, 0), s[$a$], name: "a")
  line("a", "A")
  line("a", "B")
  line("a", "C")
}), numbering: none)

The einsum notation is `ai,aj,ak->ijk` with time complexity $O(n^4)$, where the shared index $a$ creates the characteristic "star" topology.

*Example B: Kronecker Product Structure*

The Kronecker product illustrates tensor networks with disconnected components. For matrices $A, B in bb(R)^(n times n)$, their Kronecker product creates:
$
C_(i j k l) = A_(i j) B_(k l)
$

*Structural insight*: The absence of shared indices reflects the direct product structure—no information flows between the matrix components. This disconnected topology contrasts sharply with the connected star pattern.

#figure(canvas({
  import draw: *
  tensor((1, 1), "A", "A")
  tensor((3, 1), "B", "B")
  labeledge("A", (rel: (0, -1.5)), "j")
  labeledge("A", (rel: (0, 1.5)), "i")
  labeledge("B", (rel: (0, -1.5)), "l")
  labeledge("B", (rel: (0, 1.5)), "k")
}), numbering: none)

The einsum notation `ij,kl->ijkl` reveals the $O(n^4)$ complexity, which arises from forming all possible index combinations rather than performing contractions. This disconnected structure makes the Kronecker product trivially parallelizable.
])

=== Tensor Network Contraction is \#P-Complete

Understanding the computational complexity of tensor network contraction requires connecting it to established hard problems in computer science. We achieve this through the concept of computational reduction.

*Computational reduction*: To establish computational hardness, we use the technique of _reduction_. If we can transform any instance of problem $cal(A)$ into an instance of problem $cal(B)$ using polynomial-time operations, then $cal(B)$ is at least as hard as $cal(A)$. When $cal(A)$ is known to be computationally intractable, this proves that $cal(B)$ is also intractable.

#definition([2-SAT formula])[
    A _2-SAT formula_ is a Boolean formula in conjunctive normal form (CNF) where each clause contains at most two literals. For those not familiar with Boolean logic:
    - A _literal_ is a Boolean variable or its negation ($not$)
    - A _clause_ is a disjunction (logical or: $or$) of literals  
    - A Boolean formula in _conjunctive normal form_ is a conjunction (logical and: $and$) of clauses
    
    The _satisfiability problem_ asks whether there exists an assignment of truth values that makes the formula true. The _counting problem_ asks how many such satisfying assignments exist.
]

*Example*: Consider the 2-SAT formula:
$
  (x_1 or x_2) and (x_2 or x_3) and (x_3 or x_4) and (x_4 or x_5) and (x_5 or x_1) and (x_3 or not x_5)
$ <eq:2sat>

This formula contains six clauses and five Boolean variables. A satisfying assignment is: $x_1 = 1, x_2 = 0, x_3 = 1, x_4 = 0, x_5 = 1$. A non-satisfying assignment is: $x_1 = 1, x_2 = 0, x_3 = 0, x_4 = 0, x_5 = 1$, since it violates the clauses $x_2 or x_3$, $x_3 or x_4$ and $x_3 or not x_5$.

*Computational complexity*: While determining satisfiability (finding any solution) for 2-SAT formulas is polynomial-time solvable, counting the number of satisfying assignments is \#P-complete—a complexity class considered even more challenging than NP-complete problems.

#theorem([\#P-Completeness of Tensor Network Contraction])[
  General tensor network contraction is \#P-complete. That is, the problem of computing the scalar result of contracting a tensor network belongs to the \#P-complete complexity class.
]

#proof[
We establish \#P-completeness through a polynomial-time reduction from the canonical \#P-complete problem of counting satisfying assignments of 2-SAT Boolean formulas.

*Reduction construction*: Given a 2-SAT formula $c_1 and c_2 and dots and c_n$, we construct a tensor network that computes the number of its satisfying assignments.

_Step 1: Variable encoding._ Boolean variables $x_1, x_2, dots, x_n$ map directly to tensor indices in the network, denoted as $Lambda = {x_1, x_2, dots, x_n}$.

_Step 2: Clause encoding._ Each clause becomes a rank-2 tensor encoding its truth table. For a clause $c_i$ involving variables $x_i, x_j$, we construct tensor $T(c_i)$ indexed by $x_i, x_j$ where entry $T_(v_i v_j)$ equals 1 if the clause is satisfied by assignment $x_i = v_i, x_j = v_j$, and 0 otherwise.

_Step 3: Network contraction._ The counting problem reduces to the tensor contraction:
$
"count" = "contract"({x_1, x_2, dots, x_n}, {T(c_i) | i=1 dots n}, emptyset)
$

This contraction precisely counts satisfying assignments because each valid assignment contributes 1 to the sum (all clause tensors evaluate to 1), while invalid assignments contribute 0 (at least one clause tensor evaluates to 0).

Since counting satisfying assignments for 2-SAT is \#P-complete, and this reduction can be performed in polynomial time, general tensor network contraction is also \#P-complete.
]

To illustrate this reduction, we apply it to the formula in @eq:2sat. For the clause $(x_3 or not x_5)$, we construct tensor $T_(+-)$ where entry $(i,j)$ indicates whether the clause is satisfied when $x_3 = i$ and $x_5 = j$:
$
T_(+-) = mat(1, 0; 1, 1)
$

The complete tensor network for this formula is:
#figure(canvas({
  import draw: *
  let s(it) = text(10pt)[#it]
  let v0 = (0, 2)
  for (i, label) in ("++", "++", "++", "++", "++").enumerate() {
    rotate(72deg)
    tensor(v0, "T"+str(i), s[$T_(#label)$])
  }
  tensor((0, 0), "T5", s[$T_(+-)$])
  for (i, (a, b)) in (("T0", "T1"), ("T1", "T2"), ("T2", "T3"), ("T3", "T4"), ("T4", "T0")).enumerate() {
    labeledge(a, b, s[$x_#(i+1)$], name: "x"+str(i+1))
  }
  line("T5", "x3")
  line("T5", "x5")
}))

This \#P-completeness result explains why approximate methods and heuristic algorithms dominate practical tensor network computations, motivating the optimization techniques discussed in subsequent sections.

== Contraction order optimization and slicing

The computational cost of tensor network contraction depends critically on the chosen *contraction order*—the sequence in which pairwise tensor multiplications are performed. This order can be represented as a binary tree where leaves correspond to input tensors and internal nodes represent intermediate results.

Consider the contraction `ein"ab,bc,cd->ad"`, which admits multiple valid orderings with dramatically different costs:

#figure(canvas({
  import draw: *
  set-origin((4, 0.35))
  let DY = 1.2
  let DX1 = 1.5
  let DX2 = 0.9
  let root = (0, DY)
  let left = (-DX1, 0)
  let right = (DX1, 0)
  let left_left = (-DX1 - DX2, -DY)
  let left_right = (-DX1 + DX2, -DY)

  for (l, t, lb) in ((root, [$a d$], "C"), (left, [$a c$], "A"), (right, [$c d$], "B"), (left_left, [$a b$], "T_1"), (left_right, [$b c$], "T_4")){
    tensor(l, lb, text(11pt, t))
  }
  for (a, b) in (("C", "A"), ("C", "B"), ("A", "T_1"), ("A", "T_4")){
    line(a, b)
  }
  content((0, -2), text(10pt)[`ein"(ab,bc),cd->ad"`])
  set-origin((6, 0))
  for (l, t, lb) in ((root, [$a d$], "C"), (left, text(8pt)[$a b c d$], "A"), (right, [$b c$], "B"), (left_left, [$a b$], "T_1"), (left_right, [$c d$], "T_4")){
    tensor(l, lb, text(11pt, t))
  }
  for (a, b) in (("C", "A"), ("C", "B"), ("A", "T_1"), ("A", "T_4")){
    line(a, b)
  }
  content((0, -2), text(10pt)[`ein"(ab,cd),bc->ad"`])
}), numbering: none)

The left ordering proves dramatically superior: it achieves $O(n^3)$ time and $O(n^2)$ space complexity by first contracting compatible matrices. The right ordering creates a $O(n^4)$ intermediate tensor through an inefficient Kronecker product, illustrating how ordering choice can determine computational feasibility.

Finding the globally optimal contraction order constitutes an NP-complete optimization problem@Markov2008. Fortunately, near-optimal solutions often suffice for practical applications and can be obtained efficiently through sophisticated heuristic methods. Modern optimization algorithms have achieved remarkable scalability, successfully handling tensor networks with over $10^4$ tensors@Gray2021,@Roa2024.

The optimal contraction order has a deep mathematical connection to the _tree decomposition_@Markov2008 of the tensor network's line graph.
#definition([Tree decomposition and treewidth])[A _tree decomposition_ of a (hyper)graph $G=(V,E)$ is a tree $T=(B,F)$ where each node $B_i in B$ contains a subset of vertices in $V$ (called a "bag"), satisfying:

1. Every vertex $v in V$ appears in at least one bag.
2. For each (hyper)edge $e in E$, there exists a bag containing all vertices in $e$.
3. For each vertex $v in V$, the bags containing $v$ form a connected subtree of $T$.

The _width_ of a tree decomposition is the size of its largest bag minus one. The _treewidth_ of a graph is the minimum width among all possible tree decompositions.
]


The line graph of a tensor network is a graph where vertices represent indices and edges represent tensors sharing those indices. The relationship between a tensor network's contraction order and the tree decomposition of its line graph can be understood through several key correspondences:

- Each leg (index) in the tensor network becomes a vertex in the line graph, while each tensor becomes a hyperedge connecting multiple vertices.
- The tree decomposition's first two requirements ensure that all tensors are accounted for in the contraction sequence - each tensor must appear in at least one bag, with each bag representing a contraction step.
- The third requirement of the tree decomposition maps to an important constraint in tensor contraction: an index can only be eliminated after considering all tensors connected to it.
- For tensor networks with varying index dimensions, we can extend this relationship to weighted tree decompositions, where vertex weights correspond to the logarithm of the index dimensions.

The figure below illustrates these concepts with (a) a tensor network containing four tensors $T_1$, $T_2$, $T_3$ and $T_4$ and eight indices labeled $A$ through $H$, (b) its corresponding line graph, and (c) a tree decomposition of that line graph.

#figure(canvas({
  import draw: *
  let d = 1.1
  let s(it) = text(11pt, it)
  let locs_labels = ((0, 0), (d, 0), (0, -d), (0, -2 * d), (d, -2 * d), (2 * d, 0), (2 * d, -d), (2 * d, -2 * d))
  for (loc, t, name) in (((0.5 * d, -0.5 * d), s[$T_1$], "T_1"), ((1.5 * d, -0.5 * d), s[$T_2$], "T_2"), ((1.5 * d, -1.5 * d), s[$T_3$], "T_3"), ((0.5 * d, -1.5 * d), s[$T_4$], "T_4")) {
    circle(loc, radius: 0.3, name: name)
    content(loc, s[#t])
  }
  for ((loc, t), name) in locs_labels.zip((s[$A$], s[$B$], s[$C$], s[$D$], s[$E$], s[$F$], s[$G$], s[$H$])).zip(("A", "B", "C", "D", "E", "F", "G", "H")) {
    labelnode(loc, t, name: name)
  }
  for (src, dst) in (("A", "T_1"), ("B", "T_1"), ("C", "T_1"), ("F", "T_2"), ("G", "T_2"), ("B", "T_2"), ("H", "T_3"), ("E", "T_3"), ("G", "T_3"), ("D", "T_4"), ("C", "T_4"), ("E", "T_4")) {
    line(src, dst)
  }
  content((d, -3), text(12pt)[(a)])
  content((3.5, -1), text(12pt)[$arrow.double.r$])
  content((3.5, -1.5), text(10pt)[Line graph])
  set-origin((5, 0))
  let colors = (color.hsv(30deg, 90%, 70%), color.hsv(120deg, 90%, 70%), color.hsv(210deg, 90%, 70%), color.hsv(240deg, 90%, 70%), color.hsv(330deg, 90%, 70%), color.hsv(120deg, 90%, 70%), color.hsv(210deg, 90%, 70%), color.hsv(240deg, 90%, 70%))
  let texts = ("A", "B", "C", "D", "E", "F", "G", "H")
  for (loc, color, t) in locs_labels.zip(colors, texts) {
    circle(loc, radius: 0.3, name: t)
    content(loc, text(12pt, color)[#t])
  }
  for (a, b) in (("A", "B"), ("A", "C"), ("B", "C"), ("C", "D"), ("C", "E"), ("D", "E"), ("E", "G"), ("G", "H"), ("E", "H"), ("F", "G"), ("F", "B"), ("B", "G")) {
    line(a, b)
  }
  content((d, -3), text(12pt)[(b)])
  content((3.5, -1), text(12pt)[$arrow.double.r$])
  content((3.5, -1.5), text(10pt)[T. D.])
  set-origin((5, 0))
  for (loc, bag) in (((0, 0), "B1"), ((0, -2), "B2"), ((1, -1), "B3"), ((3, -1), "B4"), ((4, 0), "B5"), ((4, -2), "B6")) {
    circle(loc, radius: 0.55, name: bag)
    content((rel: (0, -0.75)), text(10pt, gray)[#bag])
  }
  let topleft = (-0.2, 0.2)
  let topright = (0.2, 0.2)
  let bottom = (0, -0.3)
  let top = (0, 0.3)
  let bottomleft = (-0.2, -0.2)
  let bottomright = (0.2, -0.2)
  let right = (0.3, 0)
  let left = (-0.3, 0)
  content((rel:topright, to: "B1"), text(10pt, colors.at(1))[B], name: "b1")
  content((rel:topleft, to: "B1"), text(10pt, colors.at(0))[A], name: "a1")
  content((rel:bottom, to: "B1"), text(10pt, colors.at(2))[C], name: "c1")

  content((rel:top, to: "B2"), text(10pt, colors.at(2))[C], name: "c2")
  content((rel:bottomleft, to: "B2"), text(10pt, colors.at(3))[D], name: "d1")
  content((rel:right, to: "B2"), text(10pt, colors.at(4))[E], name: "e1")

  content((rel:topright, to: "B3"), text(10pt, colors.at(1))[B], name: "b2")
  content((rel:left, to: "B3"), text(10pt, colors.at(2))[C], name: "c3")
  content((rel:bottomright, to: "B3"), text(10pt, colors.at(4))[E], name: "e2")

  content((rel:topleft, to: "B4"), text(10pt, colors.at(1))[B], name: "b3")
  content((rel:bottomleft, to: "B4"), text(10pt, colors.at(4))[E], name: "e3")
  content((rel:right, to: "B4"), text(10pt, colors.at(6))[G], name: "g1")

  content((rel:left, to: "B5"), text(10pt, colors.at(1))[B], name: "b4")
  content((rel:topright, to: "B5"), text(10pt, colors.at(5))[F], name: "f1")
  content((rel:bottom, to: "B5"), text(10pt, colors.at(6))[G], name: "g2")

  content((rel:left, to: "B6"), text(10pt, colors.at(4))[E], name: "e4")
  content((rel:top, to: "B6"), text(10pt, colors.at(6))[G], name: "g3")
  content((rel:bottomright, to: "B6"), text(10pt, colors.at(7))[H], name: "h1")

  line("b1", "b2", stroke: colors.at(1))
  line("b2", "b3", stroke: colors.at(1))
  line("b3", "b4", stroke: colors.at(1))
  line("c1", "c3", stroke: colors.at(2))
  line("c2", "c3", stroke: colors.at(2))
  line("e1", "e2", stroke: colors.at(4))
  line("e2", "e3", stroke: colors.at(4))
  line("e3", "e4", stroke: colors.at(4))
  line("g1", "g2", stroke: colors.at(6))
  line("g1", "g3", stroke: colors.at(6))
  content((2, -3), text(12pt)[(c)])
}),
caption: [(a) A tensor network. (b) A line graph for the tensor network. Labels are connected if and only if they appear in the same tensor. (c) A tree decomposition (T. D.) of the line graph.]
)

The tree decomposition in (c) consists of 6 bags, each containing at most 3 indices, indicating that the treewidth of the tensor network is 2. The tensors $T_1$, $T_2$, $T_3$ and $T_4$ are contained in bags $B_1$, $B_5$, $B_6$ and $B_2$ respectively. Following the tree structure, we perform the contraction from the leaves. First, we contract bags $B_1$ and $B_2$ into $B_3$, yielding an intermediate tensor $I_(1 4) = T_1 * T_4$ (where "$*$" denotes tensor contraction) with indices $B$ and $E$. Next, we contract bags $B_5$ and $B_6$ into $B_4$, producing another intermediate tensor $I_(2 3) = T_2 * T_3$ also with indices $B$ and $E$. Finally, contracting $B_3$ and $B_4$ yields the desired scalar result.

#figure(canvas({
  import draw: *
  set-origin((4, 0.35))
  let DY = 1.2
  let DX1 = 1.5
  let DX2 = 0.9
  let root = (0, DY)
  let left = (-DX1, 0)
  let right = (DX1, 0)
  let left_left = (-DX1 - DX2, -DY)
  let left_right = (-DX1 + DX2, -DY)
  let right_left = (DX1 - DX2, -DY)
  let right_right = (DX1 + DX2, -DY)

  for (l, t, lb) in ((root, [$$], "C"), (left, [$I_14$], "A"), (right, [$I_23$], "B"), (left_left, [$T_1$], "T_1"), (left_right, [$T_4$], "T_4"), (right_left, [$T_3$], "T_3"), (right_right, [$T_2$], "T_2")){
    tensor(l, lb, text(11pt, t))
  }

  for (a, b) in (("C", "A"), ("C", "B"), ("A", "T_1"), ("A", "T_4"), ("B", "T_3"), ("B", "T_2")){
    line(a, b)
  }
}), numbering: none)

Finding the optimal contraction order is almost equivalent to finding the minimal-width tree decomposition of the line graph.
The log time complexity for the bottleneck contraction corresponds to the largest bag size in the tree decomposition.
The log space complexity is equivalent to the largest separator (the set of vertices connecting two bags) size in the tree decomposition.

=== Heuristic methods for finding the optimal contraction order

`OMEinsum` provides multiple heuristic methods for finding the optimal contraction order. They are implemented in the dependency `OMEinsumContractionOrders`. To demonstrate the usage, we first generate a large enough random tensor network with the help of the `Graphs` package.

```julia
julia> using OMEinsum, Graphs

julia> function demo_network(n::Int)
           g = random_regular_graph(n, 3)
           code = EinCode([[e.src, e.dst] for e in edges(g)], Int[])
           sizes = uniformsize(code, 2)
           tensors = [randn([sizes[leg] for leg in ix]...) for ix in getixsv(code)]
           return code, tensors, sizes
       end
demo_network (generic function with 1 method)

julia> code, tensors, sizes = demo_network(100);

julia> contraction_complexity(code, sizes)
Time complexity: 2^100.0
Space complexity: 2^0.0
Read-write complexity: 2^9.231221180711184
```

We first generate a random 3-regular graph with 100 vertices. Then we associate each vertex with a binary variable and each edge with a tensor of size $2 times 2$. The time complexity without contraction order optimization is $2^100$, which is equivalent to brute-force. The order can be optimized with the `optimize_code` function.

```julia
julia> optcode = optimize_code(code, sizes, TreeSA());

julia> cc = contraction_complexity(optcode, sizes)
Time complexity: 2^17.241796993093228
Space complexity: 2^13.0
Read-write complexity: 2^16.360864226366807
```
The `optimize_code` function takes three inputs: the `EinCode` object, the tensor sizes, and the contraction order solver. It returns a `NestedEinsum` object of time complexity $~2^17.2$. It is much smaller than the number of vertices. It is a very reasonable number because the treewidth of a 3-regular graph is approximately upper bounded by $1\/6$ of the number of vertices@Fomin2006.

#figure(image("images/sycamore_53_20_0.svg", width: 60%),
caption: [The contraction order quality measured by the space complexity ($x$-axis) and time complexity ($y$-axis) for different methods with different hyper-parameters. For details, please check GitHub repository #link("https://github.com/TensorBFS/OMEinsumContractionOrdersBenchmark")[`OMEinsumContractionOrdersBenchmark`].]
)

Among the available solver backends, `TreeSA` and `HyperND` usually provide the best contraction order quality. However, they are slow. For overhead sensitive applications, one can use `GreedyMethod` or `Treewidth` method.

In the following, we introduce the local search method `TreeSA` in detail.

#let triangle(loc, radius) = {
  import draw: *
  let (x, y) = loc
  let r1 = (x, y)
  let r2 = (x + 0.5 * radius, y - radius)
  let r3 = (x - 0.5 * radius, y - radius)
  line(r1, r2, r3, close:true, fill:white, stroke:black)
}
#figure(canvas(length:0.6cm, {
  import draw: *
  // petersen graph
  let rootroot = (0, 0)
  let root = (-0.8, -1)
  let left = (-1.6, -2)
  let right = (0.0, -2)
  let leftleft = (-2.4, -3)
  let leftright = (-0.8, -3)
  let rightleft = (-0.8, -3)
  let rightright = (0.8, -3)
  
  line(rootroot, root, stroke: (dash: "dashed"))

  for (a, b) in ((root, left), (root, right), (left, leftleft), (left, leftright)){
    line(a, b)
  }

  for (l, i) in ((right, "C"), (leftleft, "A"), (leftright, "B")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }

  content((1.2, 0), text(16pt)[$arrow$])
  content((1.2, -3), text(16pt)[$arrow$])

  set-origin((5, 2))
  line(rootroot, root, stroke: (dash: "dashed"))
  for (a, b) in ((root, left), (root, right), (left, leftleft), (left, leftright)){
    line(a, b)
  }
  for (l, i) in ((leftleft, "C"), (leftright, "B"), (right, "A")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }

  set-origin((0, -4))
  line(rootroot, root, stroke: (dash: "dashed"))
  for (a, b) in ((root, left), (root, right), (left, leftleft), (left, leftright)){
    line(a, b)
  }
  for (l, i) in ((leftleft, "A"), (leftright, "C"), (right, "B")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }

  set-origin((4, 2))
  line(rootroot, root, stroke: (dash: "dashed"))
  for (a, b) in ((root, left), (root, right), (right, rightright), (right, rightleft)){
    line(a, b)
  }
  for (l, i) in ((left, "A"), (rightleft, "B"), (rightright, "C")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }

  content((2, 0), text(16pt)[$arrow$])
  content((2, -3), text(16pt)[$arrow$])

  set-origin((5, 2))
  line(rootroot, root, stroke: (dash: "dashed"))
  for (a, b) in ((root, left), (root, right), (right, rightright), (right, rightleft)){
    line(a, b)
  }
  for (l, i) in ((left, "C"), (rightleft, "B"), (rightright, "A")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }

  set-origin((0, -4))
  line(rootroot, root, stroke: (dash: "dashed"))
  for (a, b) in ((root, left), (root, right), (right, rightright), (right, rightleft)){
    line(a, b)
  }
  for (l, i) in ((left, "B"), (rightleft, "A"), (rightright, "C")){
    // manual-square(l, radius:0.4)
    triangle(l, 1.0)
    content((l.at(0), l.at(1) - 0.6), text(11pt, i))
  }
}),
caption: [The four basic local transformations on the contraction tree, which preserve the result of the contraction.]
) <fig:tree-transform>

The local search method@Kalachev2021 is a heuristic method based on the idea of simulated annealing.
The method starts from a random contraction order and then applies the following four possible transforms as shown in @fig:tree-transform, which correspond to the different ways to contract three sub-networks:
$
  (A * B) * C = (A * C) * B = (C * B) * A, \
  A * (B * C) = B * (A * C) = C * (B * A),
$
where $A, B, C$ are the sub-networks to be contracted.
Due to the commutative property of the tensor contraction, such transformations do not change the result of the contraction.
Even through these transformations are simple, all possible contraction orders can be reached from any initial contraction order.
The local search method starts from a random contraction tree.
In each step, the above rules are randomly applied to transform the tree and then the cost of the new tree is evaluated, which is defined as
$
  cal(L) = "tc" + w_s "sc" + w_("rw") "rwc",
$
where $w_s$ and $w_("rw")$ are the weights of the space complexity and read-write complexity compared to the time complexity, respectively.
Then the transformation is accepted with a probability given by the Metropolis criterion, which is
$
  p_("accept") = min(1, e^(-beta Delta cal(L))),
$
where $beta$ is the inverse temperature, and $Delta cal(L)$ is the difference of the cost of the new and old contraction trees.
During the process, the temperature is gradually decreased, and the process stop when the temperature is low enough.
Additionally, the `TreeSA` method supports the slicing technique.
When the space complexity is too large, one can loop over a subset of indices, and then contract the intermediate results in the end.
Such technique can reduce the space complexity, but slicing $n$ indices will increase the time complexity by $2^n$.

=== Slicing Technique

Slicing is a technique to reduce the space complexity of the tensor network by looping over a subset of indices.
This effectively reduces the size of the tensor network inside the loop, and the space complexity can potentially be reduced.
For example, in @fig:slicing, we slice the tensor network over the index $i$. The label $i$ is removed from the tensor network, at the cost of contraction multiple tensor networks.


#figure(canvas({
  import draw: *
  let points = ((0, 0), (0, 1), (1, 0), (1, 1), (0, -1), (-2, 1), (-1, 0), (-1, 1))
  let edges = (("0", "1"), ("0", "2"), ("0", "4"), ("1", "2"), ("1", "3"), ("2", "3"), ("1", "7"), ("1", "6"), ("7", "5"), ("2", "4"), ("4", "6"), ("5", "6"), ("6", "7"))
  for (k, loc) in points.enumerate() {
    circle(loc, radius: 0.2, name: str(k), fill: black)
  }
  for (k, (a, b)) in edges.enumerate() {
    line(a, b, name: "e"+str(k), stroke: (if k == 4 {(paint: red, thickness: 2pt)} else {black}))
  }
  content((rel: (0, 0.5), to: "e4.mid"), text(14pt)[$i$])
  
  set-origin((7.5, 0))
  line((-5.5, 0), (-4.5, 0), mark: (end: "straight"))
  content((-5, 0.4), text(14pt)[slicing])
  content((-3, 0), text(14pt)[$sum_i$])
  for (k, loc) in points.enumerate() {
    circle(loc, radius: 0.2, name: str(k), fill: black)
  }
  for (k, (a, b)) in edges.enumerate() {
    line(a, b, name: "e"+str(k), stroke: (if k == 4 {(dash: "dashed")} else {black}))
  }
  content((rel: (0, 0.5), to: "e4.mid"), text(14pt)[$i$])
}), caption: [The slicing technique. The tensor network is sliced over the index $i$.]) <fig:slicing>

Continuing from the previous example, we can use the `slice_code` function to reduce the space complexity.
```julia
julia> sliced_code = slice_code(optcode, sizes, TreeSASlicer(score=ScoreFunction(sc_target=cc.sc-3)));

julia> sliced_code.slicing
3-element Vector{Int64}:
 14
 76
 60

julia> contraction_complexity(sliced_code, sizes)
Time complexity: 2^17.800899899920303
Space complexity: 2^10.0
Read-write complexity: 2^17.199595668955244
```
The `slice_code` function takes three inputs: the `NestedEinsum` object, the tensor sizes, and the slicing strategy. Here, we use the `TreeSASlicer` with the `ScoreFunction` to reduce the space complexity by 3. The result type is `SlicedEinsum`, which contains a `slicing` field for storing the slice indices. After slicing, the space complexity is reduced by $3$, while the time complexity is only slightly increased. The usage of `SlicedEinsum` is the same as the `NestedEinsum` object.

```julia
julia> @assert sliced_code(tensors...) ≈ optcode(tensors...)
```

== Data Compression and Tensor Decomposition
Tensor decomposition provides a systematic approach to data compression by representing high-dimensional objects as networks of smaller, more manageable tensors. This section explores how various decomposition strategies achieve different compression-computation trade-offs.

*Singular Value Decomposition (SVD)*: Consider a complex matrix $A in CC^(m times n)$ with singular value decomposition:
$
A = U S V^dagger
$
where $U$ and $V$ are unitary matrices and $S$ contains non-negative singular values. The tensor network representation of this decomposition reveals its essential structure:
#align(center, text(10pt, canvas({
  import draw: *
  tensor((-5.5, 0), "A", [$A$])
  labeledge("A", (rel: (-1.2, 0)), [$i$])
  labeledge("A", (rel: (1.2, 0)), [$j$])

  content((-3.5, 0), [$=$])

  tensor((-1.0, 0), "A", [$U$])
  tensor((1.0, 0), "B", [$V^dagger$])
  tensor((0, 1), "L", [$s$])
  labeledge("A", (rel: (-1.2, 0)), [$i$])
  labeledge("B", (rel: (1.2, 0)), [$j$])
  labelnode((0, 0), [$k$], name: "k")
  line("k", "B")
  line("k", "A")
  line("k", "L")
})))

The compression efficiency depends on the dimensions involved. Let $d_i = \dim(i)$, $d_j = \dim(j)$, and $d_k = \dim(k)$ denote the sizes of the respective indices. 

*Compression condition*: Meaningful compression requires $d_k < min(d_i, d_j)$ —the internal bond dimension must be smaller than both external dimensions.

*Compression ratio*: The storage reduction achieved is $(d_i d_j)/(d_k (d_i + d_j))$, representing the ratio of original matrix elements to total decomposed elements.

=== CP Decomposition

#definition([CP Decomposition])[
  The _Canonical Polyadic (CP) decomposition_, also known as CANDECOMP/PARAFAC, represents a tensor as a sum of rank-1 components. For an $N$-mode tensor $cal(T) in bb(R)^(d_1 times d_2 times dots times d_N)$, the CP decomposition is:
  $
  cal(T)_(i_1, i_2, dots, i_N) = sum_(r=1)^R lambda_r u_1^(r)_(i_1) u_2^(r)_(i_2) dots u_N^(r)_(i_N)
  $
  where:
  - $R$ is the _CP rank_ (number of rank-1 components)
  - $lambda_r$ are optional scaling factors  
  - $u_k^(r) in bb(R)^(d_k)$ are factor vectors for the $k$-th mode and $r$-th component
  
  This decomposition is particularly effective for tensors with inherent low-rank structure.
]

#figure(text(10pt, canvas({
  import draw: *
  tensor((-5.5, 0), "T", [$T$])
  labeledge("T", (rel: (0, 1.2)), [$i$])
  labeledge("T", (rel: (-1.2, 0)), [$j$])
  labeledge("T", (rel: (0, -1.2)), [$k$])
  labeledge("T", (rel: (1.2, 0)), [$l$])

  content((-3.5, 0), [$=$])

  tensor((-1.0, 0), "A", [$U_1$])
  tensor((1.0, 0), "B", [$U_2$])
  tensor((0, -1.0), "C", [$U_3$])
  tensor((0, 1.0), "D", [$U_4$])
  tensor((1, 1), "L", [$Lambda$])
  labeledge("D", (rel: (0, 1.2)), [$i$])
  labeledge("A", (rel: (-1.2, 0)), [$j$])
  labeledge("C", (rel: (0, -1.2)), [$k$])
  labeledge("B", (rel: (1.2, 0)), [$l$])
  labelnode((0, 0), [$c$], name: "c")
  line("c", "D")
  line("c", "C")
  line("c", "B")
  line("c", "A")
  line("c", "L")
})), numbering: none)

*Compression analysis*: For an $N$-mode tensor with mode dimensions ${d_i}_(i=1)^N$ and CP rank $R$:
- Original storage: $product_(i=1)^N d_i$ elements  
- Decomposed storage: $R sum_(i=1)^N d_i + R$ elements (including scaling factors)
- Compression ratio: $(product_(i=1)^N d_i)/(R(sum_(i=1)^N d_i + 1))$

For our rank-4 example: $(d_i d_j d_k d_l)/(R(d_i + d_j + d_k + d_l + 1))$

*Key advantage*: Storage scales linearly with tensor order, avoiding the "curse of dimensionality."

=== Tucker Decomposition

#definition([Tucker Decomposition])[
  The _Tucker decomposition_ generalizes matrix SVD to higher-order tensors by decomposing each mode separately while retaining a dense core tensor. For an $N$-mode tensor $cal(T) in bb(R)^(d_1 times d_2 times dots times d_N)$, the Tucker decomposition is:
  $
  cal(T)_(i_1, i_2, dots, i_N) = sum_(j_1=1)^(r_1) sum_(j_2=1)^(r_2) dots sum_(j_N=1)^(r_N) cal(X)_(j_1, j_2, dots, j_N) product_(k=1)^N U_k^((i_k, j_k))
  $
  where:
  - $cal(X) in bb(R)^(r_1 times r_2 times dots times r_N)$ is the _core tensor_ encoding mode interactions
  - $U_k in bb(R)^(d_k times r_k)$ are mode-wise factor matrices (typically orthogonal)
  - $r_k$ are the mode ranks (dimensions of the core tensor)
  
  This decomposition provides more flexibility than CP decomposition at the cost of exponential core tensor growth with the number of modes.
]

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((-5.5, 0), "T", s[$T$])
  labeledge("T", (rel: (0, 1.2)), s[$i$])
  labeledge("T", (rel: (-1.2, 0)), s[$j$])
  labeledge("T", (rel: (0, -1.2)), s[$k$])
  labeledge("T", (rel: (1.2, 0)), s[$l$])

  content((-3.5, 0), [$=$])


  tensor((-1.5, 0), "A", s[$U_1$])
  tensor((1.5, 0), "B", s[$U_2$])
  tensor((0, -1.5), "C", s[$U_3$])
  tensor((0, 1.5), "D", s[$U_4$])
  tensor((0, 0), "X", s[$X$])
  labeledge("D", (rel: (0, 1.2)), s[$i$])
  labeledge("A", (rel: (-1.2, 0)), s[$j$])
  labeledge("C", (rel: (0, -1.2)), s[$k$])
  labeledge("B", (rel: (1.2, 0)), s[$l$])
  labeledge("X", "A", s[$b$])
  labeledge("X", "B", s[$d$])
  labeledge("X", "C", s[$c$])
  labeledge("X", "D", s[$a$])
}), numbering: none)

The data compression ratio for Tucker decomposition is $(product_(i=1)^N d_i) / (product_(i=1)^N r_i + sum_(i=1)^N d_i r_i)$, where $d_i$ is the dimension of the $i$-th mode, $N$ is the number of modes, and $r_i$ is the dimension of the $i$-th core tensor mode. For the rank-4 case shown above, this becomes $(d_i d_j d_k d_l) / (r_a r_b r_c r_d + d_i r_a + d_j r_b + d_k r_c + d_l r_d)$.

The Tucker decomposition exhibits distinct computational characteristics that determine its practical applicability. Unlike CP decomposition, which imposes uniform rank constraints across all modes, Tucker decomposition permits independent rank selection for each tensor mode, enabling targeted compression strategies that exploit mode-specific structure. This flexibility allows the decomposition to capture complex multilinear dependencies that would require prohibitively high CP ranks.

However, this representational power comes at a fundamental computational cost. The core tensor $X$ scales as $product_(i=1)^N r_i$, where $r_i$ denotes the rank of the $i$-th mode and $N$ is the tensor order. This exponential scaling in the number of modes—commonly termed the "curse of dimensionality"—severely constrains the method's applicability to high-order tensors. For tensors of order $N > 6$, the core tensor typically becomes the dominant storage component, negating compression benefits.

Consequently, Tucker decomposition finds optimal application in moderate-order scenarios ($N ≤ 4$) where the exponential core scaling remains computationally tractable while preserving the method's superior representational capabilities.


=== Tensor Train

#definition([Tensor Train (TT)])[
  _Tensor Train (TT)_ is a specific tensor network architecture that represents high-dimensional tensors as a sequential chain of lower-rank tensors. For an $N$-mode tensor $cal(T) in bb(R)^(d_1 times d_2 times dots times d_N)$, the TT decomposition is:
  $
  cal(T)_(i_1, i_2, dots, i_N) = sum_(alpha_1, dots, alpha_(N-1)) A_1^(i_1)_(alpha_1) A_2^(i_2)_(alpha_1, alpha_2) dots A_N^(i_N)_(alpha_(N-1))
  $
  where:
  - $A_1^(i_1) in bb(R)^(r_1)$ is the first tensor (vector)
  - $A_k^(i_k) in bb(R)^(r_(k-1) times r_k)$ are intermediate tensors for $k = 2, dots, N-1$
  - $A_N^(i_N) in bb(R)^(r_(N-1))$ is the last tensor (vector)
  - $r_k$ are the _bond dimensions_ (ranks of virtual indices)
  
  The storage requirement scales as $O(sum_(k=1)^N d_k r_(k-1) r_k)$ with $r_0 = r_N = 1$, providing efficient compression for high-dimensional tensors.
]
#align(center, text(10pt, canvas({
  import draw: *
  set-origin((-2, -2))
  content((-2.5, 0.5), [$psi(i,j,k,l,m) quad =$])

  tensor((0, 0), "A", [])
  tensor((1.5, 0), "B", [])
  tensor((3, 0), "C", [])
  tensor((4.5, 0), "D", [])
  tensor((6, 0), "E", [])
  labeledge("A", (rel: (0, 1.2)), [$i$])
  labeledge("B", (rel: (0, 1.2)), [$j$])
  labeledge("C", (rel: (0, 1.2)), [$k$])
  labeledge("D", (rel: (0, 1.2)), [$l$])
  labeledge("E", (rel: (0, 1.2)), [$m$])

  labeledge("A", "B", none)
  labeledge("B", "C", none)
  labeledge("C", "D", none)
  labeledge("D", "E", none)
})))

// #align(center, text(10pt, canvas({
//   import draw: *
//   tensor((-3.5, 0), "T", [$T$])
//   labeledge("T", (rel: (0, 1.2)), [$i$])
//   labeledge("T", (rel: (-1.2, 0)), [$j$])
//   labeledge("T", (rel: (0, -1.2)), [$k$])
//   labeledge("T", (rel: (1.2, 0)), [$l$])

//   content((-1.5, 0), [$=$])

//   tensor((0, 0), "A", [$U_1$])
//   tensor((1.5, 0), "B", [$U_2$])
//   tensor((3, 0), "C", [$U_3$])
//   tensor((4.5, 0), "D", [$A_4$])
//   labeledge("A", (rel: (0, 1.2)), [$i$])
//   labeledge("B", (rel: (0, 1.2)), [$j$])
//   labeledge("C", (rel: (0, 1.2)), [$k$])
//   labeledge("D", (rel: (0, 1.2)), [$l$])

//   labeledge("A", "B", [$a$])
//   labeledge("B", "C", [$b$])
//   labeledge("C", "D", [$c$])
// })))

This architecture represents a high-dimensional tensor using a compact one-dimensional chain structure. With bond dimension $chi$ (the size of virtual indices connecting adjacent tensors), the storage requirement scales as $O(d chi^2 L)$, where $d$ is the physical dimension and $L$ is the chain length. This yields a compression ratio of $O(d^L / (chi^2 L))$ compared to the full tensor.

The tensor train format offers several computational advantages:

*1. Efficient inner products.* Computing overlaps between two tensor trains requires only local contractions:
  #figure(canvas({
  import draw: *
  set-origin((-2, -2))
  content((-3.5, 0.75), [$sum_(i j k l m)phi^*(i,j,k,l,m)psi(i,j,k,l,m) quad =$])
  let n = 5
  for i in range(n) {
    tensor((1.5 * i, 0), "A"+str(i), [])
    tensor((1.5 * i, 1.5), "B"+str(i), [])
    line("A"+str(i), "B"+str(i))
  }
  for i in range(n - 1) {
    line("A"+str(i), "A"+str(i+1))
    line("B"+str(i), "B"+str(i+1))
  }
}), numbering: none)

*2. Polynomial-time compression.* Unlike many tensor decompositions, tensor trains admit efficient compression through iterative sweeping algorithms that alternately apply:
 #figure(canvas({
  import draw: *
  set-origin((-2, -2))
  content((-3.5, 0.5), [1. Contract two tensors])
  let n = 4
  for i in range(n) {
    tensor((1.5 * i, 0), "A"+str(i), [])
  }
  line("A0", (rel: (0, 1)))
  line("A1", (rel: (0, 1)))
  line("A2", (rel: (-0.5, 1)))
  line("A2", (rel: (0.5, 1)))
  line("A3", (rel: (0, 1)))
  circle("A2", radius: 0.7, stroke: (dash: "dashed"))
  for i in range(n - 1) {
    line("A"+str(i), "A"+str(i+1))
  }
  set-origin((0, -2.5))
  content((-3.5, 0.5), [2. Tensor factorization])
  let n = 5
  for i in range(n) {
    tensor((1.5 * i, 0), "A"+str(i), [])
  }
  line("A0", (rel: (0, 1)))
  line("A1", (rel: (0, 1)))
  line("A2", (rel: (0, 1)))
  line("A3", (rel: (0, 1)))
  line("A4", (rel: (0, 1)))
  for i in range(n - 1) {
    line("A"+str(i), "A"+str(i+1), name: "l" + str(i))
  }
  circle("l2", radius: (1.5, 0.7), stroke: (dash: "dashed"))
  content((rel: (0, 1), to: "l2"), [SVD])

}), numbering: none)
  The factorization is usually done by first reshaping the tensor into a matrix and then applying singular value decomposition. By eliminating small singular values, the bond dimension can be reduced.
  Easy to compress is a feature of all loopless tensor networks, including the tensor train. In the following example, we show a uniform state can be represented as a tensor train of rank 1.

```julia
julia> uniform_state(n) = fill(sqrt(1/2^n), 2^n);

julia> L, M, R = fill(sqrt(0.5), 2, 1), fill(sqrt(0.5), 1, 2, 1), fill(sqrt(0.5), 1, 2);

julia> @assert ein"ia,ajb,bkc,cld,dm->ijklm"(L, M, M, M, R) ≈ uniform_state(5)
```

#exampleblock([
=== Example: High-Dimensional Tensor Compression with Tensor Train

This example demonstrates practical tensor train decomposition for compressing exponentially large tensors into manageable representations. We'll compress a tensor with $2^20 approx 1$ million elements using polynomial storage.

*Data structure*: We define a Matrix Product State (MPS) to store the tensor train:
```julia
using OMEinsum, LinearAlgebra

# MPS represents a tensor train decomposition
struct MPS{T}
    tensors::Vector{Array{T, 3}}  # Each tensor has (left_bond, physical, right_bond)
end
```

*Decomposition algorithm*: The tensor train decomposition proceeds through iterative SVD sweeps:
```julia
# Compress tensor using iterative SVD-based tensor train decomposition
function tensor_train_decomposition(tensor::AbstractArray, max_rank::Int; atol=1e-6)
    dims = size(tensor)
    n = length(dims)
    tensors = Array{Float64, 3}[]
    
    # Initialize left bond dimension
    left_bond = 1
    current_tensor = reshape(tensor, dims[1], :)  # Matricize first mode
    
    # Sweep through all modes except the last
    for i in 1:(n-1)
        # SVD with rank truncation
        U, S, V, new_rank = truncated_svd(current_tensor, max_rank, atol)
        
        # Store current tensor with proper bond structure
        push!(tensors, reshape(U, (left_bond, dims[i], new_rank)))
        
        # Prepare remainder for next iteration
        remainder = Diagonal(S) * V'
        current_tensor = reshape(remainder, new_rank * dims[i+1], :)
        left_bond = new_rank
    end
    
    # Final tensor has right bond dimension 1
    push!(tensors, reshape(current_tensor, (left_bond, dims[n], 1)))
    return MPS(tensors)
end
```

*Algorithm insight*: Each iteration performs SVD to optimally separate the current mode from all remaining modes, then truncates small singular values to control bond dimensions. This greedy approach often achieves near-optimal compression for many practical tensors.

```julia
function truncated_svd(matrix::AbstractArray, max_rank::Int, atol)
    U, S, V = svd(matrix)
    
    # Determine truncation rank: respect both rank limit and error tolerance
    significant_values = S .> atol
    effective_rank = min(max_rank, sum(significant_values))
    
    # Return truncated factors
    return U[:, 1:effective_rank], S[1:effective_rank], V[:, 1:effective_rank], effective_rank
end
```

*Truncation strategy*: The algorithm balances two competing objectives by maintaining bond dimensions at computationally manageable levels while retaining singular values above the specified error threshold. This dual constraint ensures both computational tractability and approximation accuracy.

To recover the tensor, we construct the matrix product state, we construct the tensor network topology and 

```julia
# Function to contract the TT cores to reconstruct the tensor
function contract(mps::MPS)
    n = length(mps.tensors)
    code = EinCode([[2i-1, 2i, 2i+1] for i in 1:n], Int[2i for i in 1:n])
    size_dict = OMEinsum.get_size_dict(code.ixs, mps.tensors)
    optcode = optimize_code(code, size_dict, GreedyMethod())
    return optcode(mps.tensors...)
end
```

*Practical demonstration*: We compress a uniform tensor with $2^20 approx 1$ million elements:
```julia
# Create a uniform tensor (all entries equal to 1)
tensor = ones(Float64, fill(2, 20)...)  # Shape: (2,2,2,...,2) with 20 modes

# Perform tensor train decomposition
mps = tensor_train_decomposition(tensor, max_rank=5)
reconstructed = contract(mps)

# Analyze compression performance
relative_error = norm(tensor - reconstructed) / norm(tensor)
# Result: ~5e-12 (nearly perfect reconstruction)

original_storage = prod(size(tensor))  # 2^20 = 1,048,576 elements
compressed_storage = sum(prod(size(core)) for core in mps.tensors)
compression_ratio = original_storage / compressed_storage
# Result: ~26,214 (massive compression!)
```

*Compression analysis*: The uniform tensor has remarkable structure—its tensor train rank is exactly 1, enabling each core tensor to store only 2 elements. This demonstrates how tensor networks can exploit hidden low-rank structure for exponential compression gains.
])

== Automatic Differentiation

*Backpropagation* constitutes a fundamental machine learning technique for computing gradients of loss functions $cal(L)$ with respect to model parameters. Its foundation rests on the *backward rule*, which efficiently propagates adjoint information through computational graphs. The adjoint of a variable $a$ is defined as $overline(a) = frac(partial cal(L), partial a)$, representing the sensitivity of the loss to changes in that variable.

For a function $f: bb(R)^n arrow.r bb(R)^m$ with input $x$ and known adjoint of the output $overline(y)$, the backward rule computes the adjoint of the input as:
$ overline(x) = frac(partial f, partial x)^T overline(y) $
This process efficiently propagates gradient information backward through the network, enabling optimization of complex models.

For matrix multiplication $C = A B$, the backward rule yields:
$ overline(A) = overline(C) B^T, quad overline(B) = A^T overline(C) $

This rule exemplifies the remarkable efficiency of backpropagation. While the full Jacobian matrix would contain $O(n^4)$ elements, the backward computation requires only $O(n^3)$ matrix operations—the same complexity as the forward pass. This efficiency breakthrough enables practical optimization of complex models and underlies the success of modern deep learning.
Tensor network contraction generalizes matrix multiplication while preserving differentiation efficiency. We represent a tensor network as the triple $(Lambda, cal(T), sigma_Y)$:
$
  Y = "contract"(Lambda, cal(T), sigma_Y)
$
where $Lambda$ contains all tensor indices, $cal(T)$ holds the tensor collection, and $sigma_Y subset Lambda$ specifies output indices.

The backward rule for computing input tensor gradients follows naturally:
$
overline(X) = "contract"(Lambda, (cal(T) \\ {X}) union {overline(Y)}, sigma_X)
$
where $cal(T) \\ {X}$ represents the tensor set excluding $X$, and $sigma_X$ denotes $X$'s indices.

While naive implementation would require separate network contractions for each input (linear overhead), sophisticated binary contraction trees reduce this to constant overhead. Modern automatic differentiation achieves gradient computation at approximately twice the forward pass cost—remarkable efficiency considering the inherent complexity of multilinear operations.

#exampleblock([
*Example: Backward rule for tensor network contraction*

Consider the tensor network contraction: `Y = ein"aij,jk,ki->a"(A, B, C)`, where $A, B, C$ are tensors labeled by $(a, i, j), (j, k), (k, i)$ respectively.
Diagramatically, the forward contraction is given by:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let l = 0.9
  for (loc, label, name) in (((-2, 0.5), [$Y$], "Y"), ((1, 1), [$A$], "A"), ((0, 0), [$B$], "B"), ((2, 0), [$C$], "C")) {
    tensor(loc, name, s[#label])
  }
  line("A", "B")
  line("B", "C")
  line("A", "C")
  line("A", (rel: (-l, 0)))
  line("Y", (rel: (-l, 0)))
  content((-1, 0.5), s[$=$])
}))

The backward rule is given by:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let l = 0.9
  for (loc, label, name) in (((-2, 0.5), [$overline(A)$], "Abar"), ((0, 1), [$overline(Y)$], "Ybar"), ((0, 0), [$B$], "B"), ((2, 0), [$C$], "C")) {
    tensor(loc, name, s[#label])
  }
  circle((1, 1), radius: 0.3, name: "Ap", stroke: none)
  line("Ap", "B")
  line("B", "C")
  line("Ap", "C")
  line("Ap", "Ybar")
  line("Abar", (rel: (-l, 0)))
  content((-1, 0.5), s[$=$])

  set-origin((0, -2))
  for (loc, label, name) in (((-2, 0.5), [$overline(B)$], "Bbar"), ((0, 1), [$overline(Y)$], "Ybar"), ((1, 1), [$A$], "A"), ((2, 0), [$C$], "C")) {
    tensor(loc, name, s[#label])
  }
  circle((0, 0), radius: 0.3, name: "Bp", stroke: none)
  line("A", "Bp")
  line("Bp", "C")
  line("A", "C")
  line("A", "Ybar")
  line("Bbar", (rel: (-l, 0)))
  content((-1, 0.5), s[$=$])


  set-origin((0, -2))
  for (loc, label, name) in (((-2, 0.5), [$overline(C)$], "Cbar"), ((0, 1), [$overline(Y)$], "Ybar"), ((1, 1), [$A$], "A"), ((0, 0), [$B$], "B")) {
    tensor(loc, name, s[#label])
  }
  circle((2, 0), radius: 0.3, name: "Cp", stroke: none)
  line("A", "B")
  line("B", "Cp")
  line("A", "Cp")
  line("A", "Ybar")
  line("Cbar", (rel: (-l, 0)))
  content((-1, 0.5), s[$=$])

}), numbering: none)
*Quiz*: If the forward contraction specified with a binary contraction order: `Y = ein"(aij,jk),ki->a"(A, B, C)`, how are gradients computed in the backward propagation?
])

In `OMEinsum`, the backward rule of einsum has already been ported to `ChainRulesCore`, which can be directly used in `Zygote` and `Flux`.
It also implements a 

```julia
julia> gradients = cost_and_gradient(optcode, (tensors...,));
```

The returned `gradients` is a vector of arrays, each of which is an adjoint of an input tensor.

= Quantum Circuit Simulation

== Quantum States and Quantum Gates

#definition([Quantum State])[
  A _quantum state_ is a mathematical representation of a quantum system described by a vector in a complex Hilbert space. For an $n$-qubit system, the quantum state $|psi angle.r$ belongs to the Hilbert space $cal(H) = (bb(C)^2)^(times.circle n) tilde.equiv bb(C)^(2^n)$, where each qubit contributes a 2-dimensional complex vector space. The state can be written as:
  $
  |psi angle.r = sum_(i=0)^(2^n - 1) alpha_i |i angle.r
  $
  where $alpha_i in bb(C)$ are complex amplitudes satisfying the normalization condition $sum_(i=0)^(2^n - 1) |alpha_i|^2 = 1$, and $|i angle.r$ denotes the computational basis states.
]

#definition([Quantum Gate])[
  A _quantum gate_ is a unitary transformation that acts on quantum states, represented mathematically by a unitary matrix $U$ satisfying $U U^dagger = I$. For single-qubit gates, $U in bb(C)^(2 times 2)$, while $k$-qubit gates have $U in bb(C)^(2^k times 2^k)$. The gate transforms a quantum state according to:
  $
  |psi angle.r arrow.r.bar U |psi angle.r
  $
  In tensor network representation, quantum gates become tensors where:
  - Single-qubit gates are rank-2 tensors (matrices)
  - Multi-qubit gates are higher-rank tensors with indices corresponding to input and output qubits
]

Quantum circuits map naturally onto tensor networks through this correspondence, transforming quantum circuit simulation into tensor network contraction problems.

*Initial state representation*: A quantum system initialized to $|0 angle.r^(times.circle n)$ (the $n$-fold tensor product of computational zero states) decomposes as a product of independent single-qubit states:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let n = 2
  for j in range(n){
    tensor((0, -j), "init", s[$0$])
    line("init", (1, -j))
  }
  content((0, -2), s[$dots.v$])
  tensor((0, -3), "init", s[$0$])
  line("init", (1, -3))
}), numbering: none)

where each $|0 angle.r = mat(1; 0)$ state appears as a rank-1 tensor in the network.

*Gate representation*: Single-qubit gates correspond to rank-2 tensors (matrices) that transform individual qubits. For example, applying a Hadamard gate $H = 1/sqrt(2) mat(1, 1; 1, -1)$ to the first qubit creates the tensor network:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "init", s[$0$])
  tensor((1, 0.0), "H", s[$H$])
  line("init", "H")
  line("H", (2, 0))

  tensor((0, -1), "init", s[$0$])
  line("init", (1, -1))

  content((0, -2), s[$dots.v$])
  tensor((0, -3), "init", s[$0$])
  line("init", (1, -3))
}), numbering: none)

*Multi-qubit gates*: Two-qubit and multi-qubit gates create richer tensor network structures by introducing shared virtual indices between previously independent qubits. The CNOT gate, which generates entanglement between qubits, admits the tensor network decomposition:

#figure(canvas({
  import draw: *
  let radius = 0.3
  let dx = 1.5
  let dy = 0.8
  line((0, dy), (dx, dy), name: "a")
  line((0, -dy), (dx, -dy), name: "b")
  circle("a.mid", radius: 0.1, fill:black)
  circle("b.mid", radius: radius)
  line("a.mid", (rel: (0, -radius), to: "b.mid"))
  content((2.3, 0), "=")
  let W = 4
  let ddx = 0.8
  line((W - ddx, dy), (W + dx + ddx, dy), name: "c")
  tensor((W + dx/2, 0), "H1", [$H$])
  line("c.mid", "H1")
  line((W + dx/2, -dy), "H1")
  tensor((W, -dy), "H2", [$H$])
  tensor((W + dx, -dy), "H3", [$H$])
  line((W - ddx, -dy), "H2")
  line((W + ddx + dx, -dy), "H3")
  line("H2", "H3")
}), numbering: none)

This decomposition (up to normalization) reveals a fundamental insight: two-qubit gates create *entanglement* by establishing shared virtual bonds between previously independent qubits. These virtual indices carry the quantum correlations that classical systems cannot efficiently represent.

=== Useful Circuit Identities
The graphical nature of tensor networks renders quantum circuit identities visually apparent, often revealing why certain simplifications work at an intuitive level. These identities become powerful tools for circuit optimization and theoretical analysis.

*Identity 1: Hadamard basis transformation*
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "init", s[$0$])
  tensor((1, 0), "H", s[$H$])
  line("init", "H")
  line("H", (rel: (1, 0)))
  content((3, 0), "=")
  tensor((4, 0), "id", s[$"+"$])
  line("id", (rel: (1, 0)))
}), numbering: none)

The Hadamard gate transforms the computational basis state $|0 angle.r$ into the superposition state $|+ angle.r = (|0 angle.r + |1 angle.r)/sqrt(2)$. Graphically, this substitution can be made wherever the pattern appears.

*Identity 2: Basis rotation under conjugation*
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "H1", s[$H$])
  tensor((1, 0), "Z", s[$Z$])
  tensor((2, 0), "H2", s[$H$])
  line("H1", "Z")
  line("Z", "H2")
  line("H1", (rel: (-1, 0)))
  line("H2", (rel: (1, 0)))
  content((3.5, 0), "=")
  tensor((5, 0), "X", s[$X$])
  line("X", (rel: (-1, 0)), name: "a")
  line("X", (rel: (1, 0)), name: "b")
}), numbering: none)

The conjugation identity $H Z H = X$ reflects a deeper principle: the Hadamard gate rotates between the $Z$ and $X$ measurement bases. This basis transformation underlies many quantum algorithms, from quantum teleportation to variational quantum eigensolvers.

*Identity 3: Symmetric two-qubit gates*
#figure(canvas({
  import draw: *
  let radius = 0.3
  let dx = 1.5
  let dy = 0.8
  let s(it) = text(11pt, it)
  line((0, dy), (dx, dy), name: "a")
  line((0, -dy), (dx, -dy), name: "b")
  circle("a.mid", radius: 0.1, fill:black)
  circle("b.mid", radius: 0.1, fill:black)
  line("a.mid", "b.mid")
  content((2.3, 0), "=")
  let W = 3.5
  line((W, dy), (W + dx, dy), name: "c")
  line((W, -dy), (W + dx, -dy), name: "d")
  tensor((W + dx/2, 0), "H1", [$H$])
  line("c.mid", "H1")
  line("d.mid", "H1")
  content((rel: (0.2, -0.2), to: "c.mid"), s[$i$])
  content((rel: (0.2, 0.2), to: "d.mid"), s[$j$])
  content((3, 0), s[$sqrt(2)$])
}), numbering: none)
The controlled-Z gate (CZ) admits a remarkably simple tensor network representation as a single rank-4 tensor. This symmetric implementation reveals that CZ is its own inverse and demonstrates how entangling gates create shared virtual indices.

*Verification*: We can confirm this identity using OMEinsum:

```julia
julia> reshape(ein"ij->ijij"([1 1; 1 -1]), 4, 4)
4×4 Matrix{Int64}:
 1  0  0   0
 0  1  0   0
 0  0  1   0
 0  0  0  -1
```


=== Expectation Values
Computing quantum expectation values $angle.l psi | O | psi angle.r$ requires working with both the quantum state and its complex conjugate, leading to distinctive "sandwich" tensor network patterns. This structure naturally emerges from the Born rule for quantum measurements.

*Mathematical setup*: For a quantum state $|psi angle.r = U|0^n angle.r$ prepared by unitary circuit $U$ and observable $O$, the expectation value becomes:

#figure(canvas({
  import draw: *
  let dx = 0.6
  let dy = 1.0
  let s(it) = text(11pt, it)
  rect((-dx, -dy), (dx, dy), name: "U1")
  content((0, 0), s[$U$])
  let gap = 1.5
  let g = 0.3
  let y1 = dy - 1.5 * g
  let y2 = -dy + 1.5 * g
  rect((gap - g, y1 - g), (gap + g, y1 + g), name: "O")
  content((gap, y1), s[$O$])
  rect((2 * gap - dx, -dy), (2 * gap + dx, dy), name: "U2")
  line((dx, y1), "O")
  line((2 * gap - dx, y1), "O")
  line((dx, y2), (2 * gap - dx, y2))
  content((2*gap, 0), s[$U^dagger$])

  // input states
  tensor((-gap, y1), "init1", s[$0$])
  tensor((-gap, y2), "init2", s[$0$])

  tensor((3 * gap, y1), "fin1", s[$0$])
  tensor((3 * gap, y2), "fin2", s[$0$])
  line("init1", (-dx, y1))
  line("init2", (-dx, y2))
  line((2 * gap + dx, y1), "fin1")
  line((2 * gap + dx, y2), "fin2")
}), numbering: none)

*Tensor network structure*: The resulting "sandwich" pattern represents the quantum mechanical formula $angle.l 0^n | U^dagger O U | 0^n angle.r$. This structure has several important features:
- The observable $O$ sits between the forward evolution $U$ and backward evolution $U^dagger$
- Initial and final states are identical computational basis states
- The contraction computes a scalar expectation value

This pattern appears throughout quantum algorithms and forms the basis for variational quantum computing approaches.

#exampleblock([
*Example: GHZ state preparation circuit*

Consider a 3-qubit quantum circuit that prepares the GHZ state $|"GHZ" angle.r = 1/sqrt(2)(|000 angle.r + |111 angle.r)$. The quantum circuit generating this state is shown below:

#align(center, quantum-circuit(
  lstick($|0 angle.r$), $H$, ctrl(1), 1, [\ ],
  lstick($|0 angle.r$), 1, targ(), ctrl(1), [\ ],
  lstick($|0 angle.r$), 2, targ(), 1
))

The corresponding tensor network diagram is:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dy = 1.5
  tensor((0, 0), "a", s[$|0 angle.r$])
  tensor((0, -dy), "b", s[$|0 angle.r$])
  tensor((0, -2*dy), "c", s[$|0 angle.r$])
  tensor((1, 0), "H1", s[$H$])
  tensor((1, -dy), "H2", s[$H$])
  tensor((3, -dy), "H2b", s[$H$])
  tensor((3, -2*dy), "H3", s[$H$])
  tensor((5, -2*dy), "H3b", s[$H$])
  tensor((2, -dy/2), "Ha", s[$H$])
  tensor((4, -3*dy/2), "Hb", s[$H$])
  line("a", "H1")
  line("b", "H2")
  line("c", "H3")
  line("H2", "H2b", name: "l2")
  line("H3", "H3b", name: "l3")
  line("H1", (rel: (1, 0)), "Ha")
  line("Ha", "l2.mid")
  line((rel: (1, 0), to: "H1"), (6, 0))
  line("H2b", (rel: (1, 0)), "Hb")
  line("Hb", "l3.mid")
  line((rel: (1, 0), to: "H2b"), (6, -dy))
  line("H3b", (rel: (1, 0), to: "H3b"))
}), numbering: none)

which can be simplified to
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dy = 1.5
  tensor((3, -dy), "H2b", s[$H$])
  tensor((5, -2*dy), "H3b", s[$H$])
  tensor((2, -dy/2), "Ha", s[$H$])
  tensor((4, -3*dy/2), "Hb", s[$H$])
  line((2, 0), (6, 0))
  line((2, 0), "Ha")
  line("Ha", (rel: (0, -dy/2)), "H2b")
  line("H2b", (rel: (1, 0)), "Hb")
  line("Hb", (rel: (0, -dy/2)), "H3b")
  line((rel: (1, 0), to: "H2b"), (6, -dy))
  line("H3b", (rel: (1, 0), to: "H3b"))
  content((7, -dy/2), "=")
  set-origin((8, 0))
  line((0, 0), (1, 0))
  line((0, -dy), (1, -dy))
  line((0, -2*dy), (1, -2*dy))
  line((0, 0), (0, -2*dy))
}), numbering: none)

Question: How to compute $angle.l "GHZ"|O|"GHZ" angle.r$ and what is the complexity?
])

== Example: Hadamard test

#theorem([Hadamard Test])[
  The _Hadamard test_ is a quantum algorithm that estimates the expectation value of a unitary operator $U$ with respect to a quantum state $|psi angle.r$ using a single ancilla qubit. The algorithm measures the expectation value:
  $
  angle.l psi | U | psi angle.r = angle.l Z angle.r_"ancilla"
  $
  where the measurement is performed on the ancilla qubit in the computational basis after applying the Hadamard test circuit.
  
  Specifically, measuring the ancilla qubit in the $Z$-basis yields:
  - $angle.l Z angle.r_"ancilla" = "Re"(angle.l psi | U | psi angle.r)$ for the standard Hadamard test
  - $angle.l X angle.r_"ancilla" = "Im"(angle.l psi | U | psi angle.r)$ for the modified Hadamard test (with additional $S$ gate)
]

The Hadamard test circuit is shown below:

#align(center, quantum-circuit(
  lstick($|0 angle.r$), $H$, ctrl(1), $H$, 1, [\ ],
  lstick($|psi angle.r$), nwire([$n$]), gate($U$), 1
))

The expectation value of $Z$ on the first qubit is given by
$
angle.l Z angle.r = "Re"(angle.l psi | U | psi angle.r)
$

The corresponding tensor network representation is:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "init", s[$|0 angle.r$])
  tensor((0, -1), "psi", s[$|psi angle.r$])
  tensor((1, 0), "H1", s[$H$])
  tensor((3, 0), "H2", s[$H$])
  tensor((4, 0), "Z", s[$Z$])
  tensor((5, 0), "H3", s[$H$])
  tensor((7, 0), "H4", s[$H$])
  tensor((8, 0), "fin", s[$angle.l 0|$])
  tensor((8, -1), "psi2", s[$angle.l psi|$])
  tensor((2, -1), "U1", s[$U$])
  tensor((6, -1), "U2", s[$U$])
  line("init", "H1")
  line("H1", "H2", name: "a")
  line("H2", "Z")
  line("Z", "H3")
  line("H3", "H4", name: "b")
  line("H4", "fin")
  line("psi", "U1")
  line("U1", "a")
  line("U2", "b")
  line("U1", "U2")
  line("U2", "psi2")

  content((4, -2), [$arrow.b$])

  set-origin((0, -3))
  tensor((0, 0), "init", s[$|0 angle.r$])
  tensor((0, -1), "psi", s[$|psi angle.r$])
  tensor((1, 0), "H1", s[$H$])
  tensor((4, 0), "X", s[$X$])
  tensor((7, 0), "H4", s[$H$])
  tensor((8, 0), "fin", s[$angle.l 0|$])
  tensor((8, -1), "psi2", s[$angle.l psi|$])
  tensor((2, -1), "U1", s[$U$])
  tensor((6, -1), "U2", s[$U$])
  line("init", "H1")
  line("H1", "X")
  line("X", "H4")
  line("H4", "fin")
  line("psi", "U1")
  line("U1", (2, 0))
  line("U2", (6, 0))
  line("U1", "U2")
  line("U2", "psi2")

  content((4, -2), [$arrow.b$])

  set-origin((0, -3))
  tensor((0, 0), "init", s[$|0 angle.r$])
  tensor((0, -1), "psi", s[$|psi angle.r$])
  tensor((2, 0), "Z", s[$Z$])
  tensor((4, 0), "fin", s[$angle.l 0|$])
  tensor((4, -1), "psi2", s[$angle.l psi|$])
  tensor((2, -1), "U1", s[$U$])
  line("init", "Z")
  line("Z", "fin")
  line("psi", "U1")
  line("U1", "psi2")

  content((5, -0.5), [$=$])
  set-origin((6, 0))

  tensor((0, -0.5), "psi", s[$|psi angle.r$])
  tensor((2, -0.5), "psi2", s[$angle.l psi|$])
  tensor((1, -0.5), "U1", s[$U$])
  line("psi", "U1")
  line("U1", "psi2")

}), numbering: none)

== Example: Quantum teleportation

Teleportation transmits an unknown state $|psi angle.r$ from Alice to Bob using a shared Bell pair and two classical bits. The steps are: (1) prepare a Bell pair on qubits 2–3, (2) perform a Bell-basis measurement on qubits 1–2, (3) apply Pauli corrections $Z^(m_1) X^(m_2)$ on qubit 3 according to outcomes $(m_1, m_2)$.

=== Circuit

#align(center, quantum-circuit(min-row-height: 20pt,
  // Qubit 1 (Alice): |psi>, CNOT(1->2), H, M1
  lstick($|psi angle.r$), 2, ctrl(1), $H$, meter(label: [$M_1$]), [\ ],
  // Qubit 2 (Alice’s ancilla): H, CNOT(2->3), target from 1, M2
  lstick($|0 angle.r$), $H$, ctrl(1), targ(), 1, meter(label: [$M_2$]), [\ ],
  // Qubit 3 (Bob): target from 2, Pauli corrections Z^{m1}, X^{m2}
  lstick($|0 angle.r$), 1, targ(), 1, 1, gate($X^(m_2)$), gate($Z^(m_1)$), 1
))

=== Tensor-network diagram and simplification

The circuit maps to a tensor network where the Bell pair is a rank-2 tensor, gates are rank-4 tensors, and measurements are projectors. Up to Pauli frame corrections, the network reduces to an identity wire from Alice's input to Bob's output.

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dx = 2
  let dy = 1.5
  tensor((0, 0), "psi", s[$psi$])
  tensor((0, -dy), "id1", s[0])
  tensor((0, -2*dy), "id2", s[0])

  tensor((0.5*dx, -dy), "H1", s[$H$])
  tensor((dx, -1.5*dy), "H2", s[$H$])
  tensor((0.5*dx, -2*dy), "H3", s[$H$])

  tensor((1.5*dx, -1*dy), "H4", s[$H$])
  tensor((1.5*dx, -2*dy), "H5", s[$H$])

  tensor((2.5*dx, 0), "H6", s[$H$])
  tensor((2*dx, -0.5*dy), "H7", s[$H$])
  tensor((2.5*dx, -1*dy), "H8", s[$H$])

  tensor((3*dx, -1.5*dy), "H9", s[$H$])
  tensor((2.5*dx, -2*dy), "H10", s[$H$])
  tensor((3.5*dx, -2*dy), "H11", s[$H$])

  tensor((4*dx, -dy), "H12", s[$H$])

  let p1 = (2*dx, -dy)
  let p2 = (dx, -2*dy)
  let p3 = (3*dx, -2*dy)
  let q1 = (2*dx, 0)
  let q2 = (dx, -dy)
  let q3 = (3*dx, -dy)
  line("id1", "H1")
  line("id2", "H3")
  line(p2, "H2")
  line(q2, "H2")
  line(p2, "H3")
  line(p2, "H5")
  line("H1", "H4")
  line("H4", "H8")
  line("psi", "H6")
  line(p1, "H7")
  line(q1, "H7")
  line("H5", "H10")
  line("H10", "H11")
  line("H9", p3)
  line("H9", q3)
  line("H8", q3)
  line("H11", (rel: (2, 0)))
  let q4 = (4 * dx, 0)
  line("H6", q4, "H12")
  line("H12", (4 * dx, -2 * dy))
  line(q3, (rel: (1, 0)))
  line(q4, (rel: (1, 0)))
}), numbering: none)


#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dx = 2
  let dy = 1.5
  tensor((dx, 0), "psi", s[$psi$])

  tensor((dx, -1.5*dy), "H2", s[$H$])

  tensor((1.5*dx, -1*dy), "H4", s[$H$])
  tensor((1.5*dx, -2*dy), "H5", s[$H$])

  tensor((2.5*dx, 0), "H6", s[$H$])
  tensor((2*dx, -0.5*dy), "H7", s[$H$])
  tensor((2.5*dx, -1*dy), "H8", s[$H$])

  tensor((3*dx, -1.5*dy), "H9", s[$H$])
  tensor((2.5*dx, -2*dy), "H10", s[$H$])
  tensor((3.5*dx, -2*dy), "H11", s[$H$])

  tensor((4*dx, -dy), "H12", s[$H$])

  let p1 = (2*dx, -dy)
  let p2 = (dx, -2*dy)
  let p3 = (3*dx, -2*dy)
  let q1 = (2*dx, 0)
  let q2 = (dx, -dy)
  let q3 = (3*dx, -dy)
  line(p2, "H2")
  line(q2, "H2")
  line(p2, "H5")
  line((dx, -dy), "H4")
  line("H4", "H8")
  line("psi", "H6")
  line(p1, "H7")
  line(q1, "H7")
  line("H5", "H10")
  line("H10", "H11")
  line("H9", p3)
  line("H9", q3)
  line("H8", q3)
  line("H11", (rel: (2, 0)))
  let q4 = (4 * dx, 0)
  line("H6", q4, "H12")
  line("H12", (4 * dx, -2 * dy))
  line(q3, (rel: (1, 0)))
  line(q4, (rel: (1, 0)))
}), numbering: none)

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dx = 2
  let dy = 1.5
  tensor((dx, 0), "psi", s[$psi$])

  tensor((2.5*dx, 0), "H6", s[$H$])
  tensor((2*dx, -0.5*dy), "H7", s[$H$])
  tensor((2.5*dx, -1*dy), "H8", s[$H$])

  tensor((3*dx, -1.5*dy), "H9", s[$H$])
  tensor((3.5*dx, -2*dy), "H11", s[$H$])

  tensor((4*dx, -dy), "H12", s[$H$])

  let p1 = (2*dx, -dy)
  let p2 = (dx, -2*dy)
  let p3 = (3*dx, -2*dy)
  let q1 = (2*dx, 0)
  let q2 = (dx, -dy)
  let q3 = (3*dx, -dy)
  let L = (2 * dx, -2 * dy)
  line("psi", "H6")
  line("H8", L, "H7")
  line(q1, "H7")
  line("H9", L)
  line("H9", q3)
  line("H8", q3)
  line("H11", (rel: (2, 0)))
  let q4 = (4 * dx, 0)
  line("H6", q4, "H12")
  line("H12", (4 * dx, -2 * dy))
  line(p1, L, "H11")
  line(q3, (rel: (1, 0)))
  line(q4, (rel: (1, 0)))
}), numbering: none)

Here, we use the following identity:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "H1", s[$H$])
  tensor((0, -1), "H2", s[$H$])
  line("H1", (rel: (-1, 0)), (rel: (0, -1)), "H2", name: "a")
  line("H1", (rel: (1, 0)), (rel: (0, -1)), "H2", name: "b")
  line("a.mid", (rel: (-0.5, 0)))
  line("b.mid", (rel: (0.5, 0)))
  content((2, -0.5), s[$=$])
  tensor((3.5, -0.5), "id1", [id])
  tensor((4.5, -0.5), "id2", [id])
  line("id1", (rel: (-1, 0)))
  line("id2", (rel: (1, 0)))
}), numbering: none)

Then we have
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let dx = 2
  let dy = 1.5
  tensor((dx, 0), "psi", s[$psi$])

  let p1 = (2*dx, -dy)
  let p2 = (dx, -2*dy)
  let p3 = (3*dx, -2*dy)
  let q1 = (2*dx, 0)
  let q2 = (dx, -dy)
  let q3 = (4*dx, -dy)
  let L = (2 * dx, -2 * dy)
  line("psi", (rel: (2,0), to: "psi"), (rel: (2, -2 * dy)), (rel: (3, 0)))
  let q4 = (4 * dx, 0)
  tensor(q3, "id1", [id])
  tensor(q4, "id2", [id])
}), numbering: none)

#dev([
== ZX calculus

#definition([ZX Calculus])[
  The _ZX calculus_ is a complete graphical language for representing and reasoning about quantum circuits and processes. It consists of:
  - _Z-spiders_ (green nodes): representing rotations around the Z-axis and computational basis operations  
  - _X-spiders_ (red nodes): representing rotations around the X-axis and superposition operations
  - _Wires_: connecting spiders and representing quantum information flow
  - _Rewrite rules_: graphical transformations that preserve quantum mechanical equivalence
  
  The calculus is _complete_, meaning any equation that holds between quantum processes can be derived using the graphical rewrite rules. Unlike traditional tensor networks that focus on efficient computation, ZX calculus emphasizes formal reasoning and proof verification in quantum mechanics.
]

This graphical language represents quantum operations as diagrams governed by rewrite rules that preserve quantum mechanical equivalence, providing a powerful tool for quantum circuit optimization and verification.

The two spiders are defined as follows:
#let zspider(loc, phase: none, name: none) = {
  import draw: *
  let s(it) = text(11pt, it)
  circle(loc, radius: 0.3, fill: rgb("#2ecc71").lighten(20%), stroke: black, name: name)
  if phase != none { content(loc, s[#phase]) }
}
#let xspider(loc, phase: none, name: none) = {
  import draw: *
  let s(it) = text(11pt, it)
  circle(loc, radius: 0.3, fill: rgb("#e74c3c").lighten(20%), stroke: black, name: name)
  if phase != none { content(loc, s[#phase]) }
}
#let hbox(a, name: none, ang: 0deg) = {
  import draw: rect, group, content, rotate
  let s(it) = text(11pt, it)
  group(name: name, {
    rotate(ang, origin: a)
    rect((rel: (-0.25, -0.25), to: a), (rel: (0.25, 0.25), to: a), fill: rgb("#f1c40f").lighten(20%), stroke: black)
    content(a, s[$H$])
  })
}

#let hline(a, b, name: none) = {
  import draw: line, get-ctx
  import coordinate: resolve
  get-ctx(ctx => {
    let (ctx, pos1) = resolve(ctx, a)
    let (ctx, pos2) = resolve(ctx, b)
    let (x1, y1, z1) = pos1  // CeTZ uses 3D coordinates internally
    let (x2, y2, z2) = pos2
    let mid = ((x1 + x2)/2, (y1 + y2)/2)
    let ang = calc.atan2(y2 - y1, x2 - x1)
    line(a, b, name: "line")
    hbox(mid, name: name, ang: ang)
  })
}

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  
  // Green Z-spider
  zspider((0, 0), phase: [$alpha$], name: "Z")
  line("Z", (rel: (0, 1)))
  line("Z", (rel: (1, 0.5)))
  line("Z", (rel: (-1, 0.5)))
  content((-2.5, 0), s[Z-spider])
  content((2.7, 0), s[$=ket(0dots 0) + e^(i alpha)ket(1dots 1)$])

  // Red X-spider
  set-origin((0, -2))
  xspider((0, 0), phase: [$beta$], name: "X")
  line("X", (rel: (0, 1)))
  line("X", (rel: (1, 0.5)))
  line("X", (rel: (-1, 0.5)))
  content((-2.5, 0), s[X-spider])
  content((2.7, 0), s[$=ket("+"dots "+") + e^(i beta)ket(dash dots dash)$])
}), numbering: none)

For convenience, we also define the Hadamard box as follows:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  content((-2.5, 0), s[Hadamard box])
  // Hadamard box
  hbox((0, 0), name: "H")
  line((rel: (-0.7, 0), to: "H"), "H")
  line("H", (rel: (0.7, 0)))
  set-origin((1.5, 0))
  content((0.0, 0), s[$~$])

  set-origin((1.5, 0))
  zspider((0, 0), phase: [$pi/2$], name: "Z1")
  xspider((1, 0), phase: [$pi/2$], name: "X1")
  zspider((2, 0), phase: [$pi/2$], name: "Z2")
  line("Z1", "X1")
  line("X1", "Z2")
  line("Z1", (rel: (-0.8, 0)))
  line("Z2", (rel: (0.8, 0)))
}), numbering: none)
Here we use "$~$" to denote the equivalence of the two diagrams up to a constant.
Since ZX-calculus is color exchange symmetric, the color exchanged Hadamard box is also a valid rule.

We have the following simple observations:
- The 1st order Z-spider with phase $0$/$pi$ is the $ket("+")$/$ket(dash)$ state.
- The 1st order X-spider with phase $0$/$pi$ is the $ket(0)$/$ket(1)$ state.
- The 2nd order Z-spider with phase $0$/$pi$ is the identity/Pauli-Z gate.
- The 2nd order X-spider with phase $0$/$pi$ is the identity/Pauli-X gate.

=== Core rewrite rules

The ZX-calculus is governed by several key rewrite rules:

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
 
  // Spider fusion
  zspider((0.5, 0), phase: s[$alpha$], name: "Z1")
  zspider((-0.5, 0), phase: s[$beta$], name: "Z2")
  line("Z1", "Z2")
  line("Z1", (rel: (0.8, 0)))
  line("Z2", (rel: (-0.8, 0)))
  content((1.8, 0), s[$=$])
  zspider((3, 0), phase: text(6pt)[$alpha + beta$], name: "Z3")
  line("Z3", (rel: (0.8, 0)))
  line("Z3", (rel: (-0.8, 0)))
  content((1.5, -1), s[(f) fusion])
  
  // identity
  set-origin((5, 0))
  let O = (0, 0)
  zspider(O, phase: "0", name: "Z5")
  line("Z5", (rel: (0, 0.8)))
  line("Z5", (rel: (0.6, 0.4)))
  line("Z5", (rel: (0.6, -0.4)))
  content((1.2, 0), s[$=$])
  O = (1.8, 0)
  line(O, (rel: (0, 0.8)))
  line(O, (rel: (0.6, 0.4)))
  line(O, (rel: (0.6, -0.4)))
  content((1.3, -1), s[(i1) identity])

  set-origin((4, 0))
  content((1.5, -1), [(i2) cancellation])
  // Green Z-spider
  hbox((0, 0), name: "H1")
  hbox((1, 0), name: "H2")
  line("H1", "H2")
  line("H1", (rel: (-0.7, 0)))
  line("H2", (rel: (0.7, 0)))
  content((2, 0), s[$=$])
  line((2.5, 0), (3.5, 0))

  set-origin((-9, -3))
  content((1.5, -1), [(h) Hadamard])
  // Green Z-spider
  zspider((0, 0), phase: s[$alpha$], name: "Z")
  line("Z.north", (rel: (0, 0.5)))
  line("Z.east", (rel: (0.5, 0)))
  line("Z.west", (rel: (-0.5, 0)))

  set-origin((1.2, 0))
  content((0, 0), s[$=$])

  // Red X-spider
  set-origin((1.7, 0))
  xspider((0, 0), phase: [$alpha$], name: "X")
  hline("X.north", (rel: (0, 1)))
  hline("X.east", (rel: (1, 0)))
  hline("X.west", (rel: (-1, 0)))

  // pi commute
  set-origin((-3, -3))
  xspider((0, 0), phase: s[$pi$], name: "X")
  zspider((1, 0), phase: s[$alpha$], name: "Z")
  line("X", "Z")
  line("X", (rel: (-0.7, 0)))
  bezier("Z.north", (rel: (0.5, 0.2)), (rel: (0.2, 0.6), to: "Z"))
  bezier("Z.south", (rel: (0.5, -0.2)), (rel: (0.2, -0.6), to: "Z"))
  content((1.5, 0), s[$dots.v$])
  content((2.2, 0), s[$=$])
  content((2.2, -1.2), [($pi$) $pi$ commute])
  set-origin((3.5, 0))
  xspider((1, 0.7), phase: s[$pi$], name: "X1")
  xspider((1, -0.7), phase: s[$pi$], name: "X2")
  zspider((0, 0), phase: s[$-alpha$], name: "Z")
  line("X1", (rel: (0.7, 0)))
  line("X2", (rel: (0.7, 0)))
  line("Z", (rel: (-0.7, 0)))
  bezier("Z.north", "X1.west", (rel: (0.2, 0.6), to: "Z"))
  bezier("Z.south", "X2.west", (rel: (0.2, -0.6), to: "Z"))
  content((1, 0), s[$dots.v$])

  // copy
  set-origin((3, 3))
  xspider((0, 0), phase: s[$0$], name: "X")
  zspider((1, 0), phase: s[$alpha$], name: "Z")
  line("X", "Z")
  bezier("Z.north", (rel: (0.5, 0.2)), (rel: (0.2, 0.6), to: "Z"))
  bezier("Z.south", (rel: (0.5, -0.2)), (rel: (0.2, -0.6), to: "Z"))
  content((1.5, 0), s[$dots.v$])
  content((2.2, 0), s[$=$])
  content((2.2, -1.2), [(c) copy])
  set-origin((2.5, 0))
  xspider((1, 0.7), phase: s[$0$], name: "X1")
  xspider((1, -0.7), phase: s[$0$], name: "X2")
  line("X1", (rel: (0.7, 0)))
  line("X2", (rel: (0.7, 0)))
  content((1, 0), s[$dots.v$])

  // bialgebra
  set-origin((-2.2, -3))
  xspider((0, 0), phase: s[$0$], name: "X")
  zspider((1, 0), phase: s[$0$], name: "Z")
  line("X", "Z")
  bezier("X.north", (rel: (-0.3, 0.2)), (rel: (-0.2, 0.6), to: "X"))
  bezier("X.south", (rel: (-0.3, -0.2)), (rel: (-0.2, -0.6), to: "X"))
  bezier("Z.north", (rel: (0.3, 0.2)), (rel: (0.2, 0.6), to: "Z"))
  bezier("Z.south", (rel: (0.3, -0.2)), (rel: (0.2, -0.6), to: "Z"))
  content((2.2, 0), s[$=$])
  content((2.2, -1.2), [(b) bialgebra])
  set-origin((2.5, 0))
  xspider((2, 0.5), phase: s[$0$], name: "X1")
  xspider((2, -0.5), phase: s[$0$], name: "X2")
  zspider((1, 0.5), phase: s[$0$], name: "Z1")
  zspider((1, -0.5), phase: s[$0$], name: "Z2")
  line("X1", (rel: (0.7, 0)))
  line("X2", (rel: (0.7, 0)))
  line("Z1", (rel: (-0.7, 0)))
  line("Z2", (rel: (-0.7, 0)))
  line("X1", "Z1")
  line("X2", "Z2")
  line("X1", "Z2")
  line("X2", "Z1")
}), caption: [A convenient presentation for the ZX-calculus. These rules hold for all $alpha, beta in [0, 2pi)$, and due to (h) and (i2) all rules also hold with the colours interchanged. Remark: This rule set is incomplete for quantum mechanics@Witt2014.])

=== Quantum teleportation in ZX

The ZX-calculus representation of quantum teleportation is as follows:

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  circle((-1, 0), radius: 0.3, stroke: black, name: "psi")
  content((-1, 0), s[$psi$])
  xspider((-1, -1), phase: s[$0$], name: "x1")
  xspider((-1, -2), phase: s[$0$], name: "x2")
  zspider((2, 0), phase: s[$0$], name: "Z1")
  xspider((2, -1), phase: s[$0$], name: "X1")
  zspider((1, -1), phase: s[$0$], name: "Z2")
  xspider((1, -2), phase: s[$0$], name: "X2")
  xspider((4, 0), phase: text(7pt)[$m_1 pi$], name: "M1")
  xspider((4, -1), phase: text(7pt)[$m_2 pi$], name: "M2")
  xspider((3, -2), phase: text(7pt)[$m_2 pi$], name: "C1")
  zspider((4, -2), phase: text(7pt)[$m_1 pi$], name: "C2")
  line("psi", "Z1")
  hline("x1", "Z2")
  line("x2", "X2")
  line("X1", "Z2")
  hline("Z1", "M1")
  line("X1", "M2")
  line("X1", "Z1")
  line("X2", "Z2")
  line("X2", "C1")
  line("C2", "C1")
  line("C2", (rel: (1, 0)))
}), numbering: none)

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  circle((-1, 0), radius: 0.3, stroke: black, name: "psi")
  content((-1, 0), s[$psi$])
  zspider((2, 0), phase: s[$0$], name: "Z1")
  xspider((2, -1), phase: s[$0$], name: "X1")
  zspider((4, 0), phase: text(7pt)[$m_1 pi$], name: "M1")
  xspider((4, -1), phase: text(7pt)[$m_2 pi$], name: "M2")
  xspider((3, -2), phase: text(7pt)[$m_2 pi$], name: "C1")
  zspider((4, -2), phase: text(7pt)[$m_1 pi$], name: "C2")
  line("psi", "Z1")
  line("Z1", "M1")
  line("X1", "M2")
  line("X1", "Z1")
  line("C2", "C1")
  line("X1", "C1")
  line("C2", (rel: (1, 0)))
}), numbering: none)

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  circle((-1, 0), radius: 0.3, stroke: black, name: "psi")
  content((-1, 0), s[$psi$])
  circle((4, -2), radius: 0, name: "C2")
  line("psi", "C2")
  line("C2", (rel: (1, 0)))
}), numbering: none)
])

= Quantum channel simulation

Quantum channels represent the evolution of open quantum systems, capturing both unitary evolution and decoherence effects. In tensor network simulations, these are implemented through the Kraus operator formalism and density matrix evolution.

== Kraus operators

#definition([Kraus Operators])[
  _Kraus operators_ provide a mathematical representation of quantum channels describing the evolution of open quantum systems. A quantum channel $cal(E)$ acting on density matrices is characterized by a set of Kraus operators $\{K_i\}$ such that:
  $
  cal(E)(rho) = sum_i K_i rho K_i^dagger
  $
  where $rho$ is any density matrix. The Kraus operators must satisfy the _completeness relation_:
  $
  sum_i K_i^dagger K_i = I
  $
  This representation ensures the map is _completely positive_ (CP) and _trace-preserving_ (TP), meaning it preserves the positivity and normalization of density matrices, corresponding to valid quantum evolution.
]

This formalism captures both unitary evolution and decoherence effects, enabling the description of realistic quantum systems interacting with their environment.

#exampleblock([
This formalism allows us to describe various noise processes:

=== Amplitude damping
Models energy loss processes with Kraus operators:
$ K_0 = mat(1, 0; 0, sqrt(1-gamma)), quad K_1 = mat(0, sqrt(gamma); 0, 0) $

=== Phase damping  
Models pure dephasing with:
$ K_0 = sqrt(1-gamma/2) I, quad K_1 = sqrt(gamma/2) Z $

=== Depolarizing channel
The most commonly used noise model, with Kraus operators:
$ K_0 = sqrt(1-3p/4) I, quad K_1 = sqrt(p/4) X, quad K_2 = sqrt(p/4) Y, quad K_3 = sqrt(p/4) Z $
])

== Tensor network representation of channels

Consider applying a Kraus channel $cal(E)$ to a density matrix $rho$. The result can be diagramatically represented as
#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((0, 0), "rho", [$rho$])
  tensor((1, 0), "KR", [$cal(K)^*$])
  tensor((-1, 0), "KL", [$cal(K)$])
  line("rho", "KL")
  line("rho", "KR")
  line("KL", (rel: (-1, 0)))
  line("KR", (rel: (1, 0)))
  line("KL", (rel: (0, 1)), (rel: (0, 1), to: "KR"), "KR", name: "line")
  labelnode("line.mid", [$k$])
}), numbering: none)

Sometimes, we use the superoperator representation, which corresponds to the contracted Kraus channels
#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((0, 0.5), "rho", [$rho$])
  line("rho", (rel: (0.5, 0.5)))
  line("rho", (rel: (0.5, -0.5)))
  content((0, -0.9), s[density matrix])

  set-origin((4, 0))
 
  tensor((0, 0.5), "E", [$cal(E)$])
  line("E", (rel: (-0.5, 0.5)))
  line("E", (rel: (0.5, 0.5)))
  line("E", (rel: (-0.5, -0.5)))
  line("E", (rel: (0.5, -0.5)))
  line((-0.5, -0.5), (0.5, -0.5), mark: (end: "straight"))
  content((1, -0.9), s[quantum channel])
  content((1, 0.5), s[$=$])

  set-origin((2.5, 0.5))
  tensor((0, 0.7), "KR", [$cal(K)$])
  tensor((0, -0.7), "KL", [$cal(K)^*$])
  line("KL", (rel: (-0.7, 0)))
  line("KL", (rel: (0.7, 0)))
  line("KR", (rel: (-0.7, 0)))
  line("KR", (rel: (0.7, 0)))
  labeledge("KR", "KL", [$k$])

}))

For example, the superoperator representation of the depolarizing channel is
```julia
julia> using OMEinsum, Yao, SymEngine

julia> p = Basic(:p)  # define a symbolic variables
p

julia> K = cat(sqrt(1-3p/4) * Matrix{Basic}(I2), sqrt(p/4) * Matrix{Basic}(X), sqrt(p/4) * Matrix{Basic}(Y), sqrt(p/4) * Matrix{Basic}(Z); dims=3);

julia> superop_dep = reshape(ein"abk,cdk->acbd"(K, conj(K)), 4, 4)
4×4 Matrix{Basic}:
 1 + (-1/2)*p      0      0       (1/2)*p
            0  1 - p      0             0
            0      0  1 - p             0
      (1/2)*p      0      0  1 + (-1/2)*p
```

=== Pauli transfer matrix formulation

The PTM formalism provides a powerful framework for classical simulation of noisy quantum circuits. In this representation, the normalized Pauli basis $bb(P) = {I, X, Y, Z}/sqrt(2)$ forms an orthonormal basis for the operator space, where single-qubit quantum states become vectors $|rho angle.r.double_P$ with components:

$ (|rho angle.r.double_P)_i = tr(rho P_i), quad P_i in bb(P) $

Let us denote the superoperator (vectorized) representation of density matrix $rho$ as $|rho angle.r.double$. The Pauli basis representation corresponds to the following basis transformation:
$
|rho angle.r.double_P = U|rho angle.r.double
\
U = mat(
  1/sqrt(2), 0, 0, 1/sqrt(2);
  0, 1/sqrt(2), (-i)/sqrt(2), 0;
  0, 1/sqrt(2), i/sqrt(2), 0;
  1/sqrt(2), 0, 0, (-1)/sqrt(2)
) $

The four columns correspond to the vectorized and normalized Pauli matrices.
Then, we also apply this basis transformation to the quantum channel $cal(E)$:

$
cal(E)_P = U cal(E) U^dagger
$

Diagramatically, this transformation is
#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((0, 0.5), "rho", [$rho_P$])
  line("rho", (rel: (0.5, -0.5)))
  line("rho", (rel: (0.5, 0.5)))
  content((1, 0.5), s[$=$])

  set-origin((2.0, 0.5))
  tensor((0, 0), "rho", [$rho$])
  tensor((1.2, 0), "U", [$U$])
  bezier("rho.north-east", "U.north-west", (0.6, 1))
  bezier("rho.south-east", "U.south-west", (0.6, -1))
  line("U", (rel: (0.5, -0.5)))
  line("U", (rel: (0.5, 0.5)))

  set-origin((3.5, 0))
  tensor((0, 0.0), "E", [$cal(E)_P$])
  line("E", (rel: (-0.5, 0.5)))
  line("E", (rel: (0.5, 0.5)))
  line("E", (rel: (-0.5, -0.5)))
  line("E", (rel: (0.5, -0.5)))
  content((1, 0.0), s[$=$])

  set-origin((3.5, 0.0))
  tensor((0, 0), "E", [$cal(E)$])
  tensor((1.2, 0), "U", [$U$])
  tensor((-1.2, 0), "U2", [$U^dagger$])
  bezier("E.south-east", "U.south-west", (0.6, -1))
  bezier("E.north-east", "U.north-west", (0.6, 1))
  bezier("E.south-west", "U2.south-east", (-0.6, -1))
  bezier("E.north-west", "U2.north-east", (-0.6, 1))
  line("U", (rel: (0.5, -0.5)))
  line("U", (rel: (0.5, 0.5)))
  line("U2", (rel: (-0.5, -0.5)))
  line("U2", (rel: (-0.5, 0.5)))
}), numbering: none)

For the depolarizing channel, the Pauli basis representation can be obtained by:
```julia
julia> U = Basic[1 0 0 1; 0 1 -im 0; 0 1 im 0; 1 0 0 -1] / sqrt(Basic(2));

julia> pauli_dep = SymEngine.expand.(U * superop_dep * U')
4×4 Matrix{Basic}:
 1      0      0      0
 0  1 - p      0      0
 0      0  1 - p      0
 0      0      0  1 - p
```
It is a diagonal matrix $cal(D)_P = "diag"(1, 1-p, 1-p, 1-p)$, enabling efficient multi-qubit simulation via tensor decomposition:
$
  cal(D)_P = (1-p)I + p|0angle.r.double angle.l.double 0|
$
Or diagramatically,
#figure(canvas({
    import draw: *
    let s(it) = text(10pt, it)
    tensor((0, 0.0), "D", [$cal(D)_P$])
    line("D", (rel: (-0.5, 0.5)))
    line("D", (rel: (0.5, 0.5)))
    line("D", (rel: (-0.5, -0.5)))
    line("D", (rel: (0.5, -0.5)))
    content((1, 0.0), s[$=$])
    set-origin((2.5, 0))
    content((0, 0), [$1-p$])
    set-origin((1.5, 0))
    line((-0.5, 0.5), (0.5, 0.5))
    line((-0.5, -0.5), (0.5, -0.5))

    content((1, 0), s[$+$])
    content((1.5, 0), s[$p$])
    set-origin((0.5, 0))
    circle((2, -0.5), radius:0.2, name: "a")
    content((2, -0.5), s[$0$])
    line("a", (rel: (-0.5, 0)))
    circle((2, 0.5), radius:0.2, name: "b")
    content((2, 0.5), s[$0$])
    line("b", (rel: (-0.5, 0)))

    circle((2.5, -0.5), radius:0.2, name: "c")
    content((2.5, -0.5), s[$0$])
    line("c", (rel: (0.5, 0)))

    circle((2.5, 0.5), radius:0.2, name: "d")
    content((2.5, 0.5), s[$0$])
    line("d", (rel: (0.5, 0)))
}))

In the path-integral point of view, we either pick the first term or the second term in a single path. The first term has the power of damping the amplitude of states, while the second term has rank 1, and can be used to truncate the tensor network. As a consequence, quantum circuits with finite depolarizing noise can be simulated in polynomial time@Gao2018@Fontana2023.

  
= Quantum Error Correction
Quantum error correction (QEC) addresses a fundamental challenge in quantum computing: protecting fragile quantum information from inevitable errors caused by environmental decoherence, imperfect control systems, and gate imperfections@nielsen2010quantum@gottesman1997stabilizer@calderbank1996good.

*Core principle*: QEC operates by encoding logical quantum information into a larger physical Hilbert space with built-in redundancy. This encoding creates "error syndromes" that reveal error locations without destroying the logical information—a delicate balance unique to quantum mechanics.

*Stabilizer formalism*: Most practical QEC schemes are described using the elegant stabilizer formalism, which characterizes quantum codes through their symmetries rather than explicit state vectors.

== Stabilizers and Quantum Codes
The stabilizer formalism provides an algebraic framework for constructing and analyzing quantum error-correcting codes through group theory.

#definition([Pauli Group and Stabilizer Group])[The _$n$-qubit Pauli group_ is the group generated by tensor products of single-qubit Pauli matrices@gaitan2008quantum:
$
cal(P)_n = {plus.minus 1, plus.minus i} times {I, X, Y, Z}^(times.circle n)
$
Elements of this group are called _Pauli operators_ or _Pauli strings_.

A _stabilizer group_ $cal(S)$ is an Abelian subgroup of $cal(P)_n$ that contains only operators with eigenvalue $+1$ on all code states. The requirement of commutativity ensures that stabilizer measurements are compatible and do not disturb each other.
]

*Generator structure*: Any stabilizer group can be specified by a set of independent generators ${S_a}_(a=1,dots,m)$:
$
cal(S) = angle.l S_1, S_2, dots, S_m angle.r
$

*Code space definition*: The quantum code space consists of all states that are $+1$ eigenvectors of every stabilizer operator. This space contains the protected logical information.

*Error detection*: Measuring the stabilizer generators reveals whether errors have occurred:
- All generators yield $+1$: state remains in code space  
- Any generator yields $-1$: error detected, creating an "error syndrome"

*Key insight*: Stabilizer measurements preserve quantum information because they project onto subspaces (code space or error spaces) rather than classical bit values. The logical quantum state remains coherent within these subspaces.


#definition([Quantum Code])[
    An $[[n,k,d]]$ quantum code encodes $k$ logical qubits into $n$ physical qubits with minimum distance $d$. The parameters have precise meanings:
    - $n$: number of physical qubits required
    - $k$: number of logical qubits protected  
    - $d$: minimum weight of Pauli operators that can transform one codeword into a different codeword
    
    The distance $d$ determines error-correcting capability: the code can detect up to $d-1$ errors and correct up to $floor((d-1)/2)$ errors.
  ]

*Code specification*: An $[[n,k,d]]$ quantum code is typically specified by providing $n-k$ independent stabilizer generators, with the remaining degrees of freedom corresponding to the $k$ logical qubits.

#definition([CSS Code@calderbank1996good@steane1996error@steane1996multiple])[
    A quantum stabilizer code is called a _Calderbank-Shor-Steane (CSS) code_ if its stabilizer group can be generated entirely by Pauli operators containing only $X$ or only $Z$ (no $Y$ operators):
    
    $
    cal(S) = angle.l S_a angle.r_(a=1,dots,n-k), quad "where " S_a in {I, X}^(times.circle n) union {I, Z}^(times.circle n)
    $
    
    This structure enables classical error correction techniques to be applied separately to bit-flip ($X$) and phase-flip ($Z$) errors.
  ]
*Practical significance*: CSS codes represent a large and important class of quantum error-correcting codes that can be constructed using classical error correction principles. Many of the most practical quantum codes, including surface codes and color codes, belong to this family due to their relatively simple implementation requirements.

== Surface code
#let surface-code(loc, m, n, size:1, color1:yellow, color2:aqua, name: "surface", type-tag:true) = {
  import draw: *
  for i in range(m){
    for j in range(n){
      let x = loc.at(0) + i * size
      let y = loc.at(1) + j * size
      if (i != m - 1) and (j != n - 1) {
        // determine the color of the plaquette
        let (colora, colorb) = if (calc.rem(i + j, 2) == 0) {
          (color1, color2)
        } else {
          (color2, color1)
        }
        // four types of boundary plaquettes
        if type-tag == (calc.rem(i + j, 2) == 0) {
          if (i == 0) {
              bezier((x, y), (x, y + size), (x - size * 0.7, y + size/2), fill: colorb, stroke: black)
            }
            if (i == m - 2) {
              bezier((x + size, y), (x + size, y + size), (x + size * 1.7, y + size/2), fill: colorb, stroke: black)
            }
          } else {
            if (j == 0) {
              bezier((x, y), (x + size, y), (x + size/2, y - size * 0.7), fill: colorb, stroke: black)
            }
            if (j == n - 2) {
              bezier((x, y + size), (x + size, y + size), (x + size/2, y + size * 1.7), fill: colorb, stroke: black)
            }
          }
          rect((x, y), (x + size, y + size), fill: colora, stroke: black, name: name + "-square" + "-" + str(i) + "-" + str(j))
      }
      circle((x, y), radius: 0.08 * size, fill: black, stroke: none, name: name + "-" + str(i) + "-" + str(j))
    }
    }
  }
#let stabilizer-label(loc, size:1, color1:yellow, color2:aqua) = {
  import draw: *
  let x = loc.at(0)
  let y = loc.at(1)
  content((x, y), box(stroke: black, inset: 6pt, [$X$ stabilizers],fill: color2, radius: 4pt))
  content((x, y - 1.5*size), box(stroke: black, inset: 6pt, [$Z$ stabilizers],fill: color1, radius: 4pt))
}
The surface code@dennis2002topological@kitaev2003fault is a prominent example of a topological quantum error-correcting code, defined on a two-dimensional lattice of qubits arranged in a grid. Each plaquette (face) of the lattice is associated with a stabilizer operator, which acts on the qubits at the corners of the plaquette. There are two types of stabilizers: $X$-type (acting with Pauli $X$ operators) and $Z$-type (acting with Pauli $Z$ operators), typically arranged in a checkerboard pattern. Here is an example of $[[9,1,3]]$ surface code. The stabilizers are shown in the figure. The logical operator $X_1X_2X_3$ and $Z_3 Z_6 Z_9$ commute with all stablizers and do not belong to the stabilizer group. The length of them is exactly the distance of the code.
#figure(canvas({
  import draw: *
  let n = 3
  surface-code((0, 0),size:1.5, n, n,name: "surface1")
  for i in range(n) {
    for j in range(n) {
      content((rel: (0.3, 0.3), to: "surface1" + "-" + str(j) + "-" + str(2-i)), [#(i*n+j+1)])
    }
  }
  content((5.5, 1.4), box(stroke: black, inset: 6pt, [$X$ stabilizers: \ $S_1 = X_1X_2X_4X_5$ \ $S_2 = X_3X_6$ \ $S_3 = X_4X_7$ \ $S_4 = X_5X_6X_8X_9$],fill: aqua, radius: 4pt))
  content((9, 1.4), box(stroke: black, inset: 6pt, [$Z$ stabilizers: \ $S_5 = Z_1Z_2$ \ $S_6 = Z_2Z_3Z_5Z_6$ \ $S_7 = Z_4Z_5Z_7Z_8$ \ $S_8 = Z_8Z_9$],fill: yellow, radius: 4pt))

  line("surface1-2-0", "surface1-2-2", stroke: (thickness: 2pt, paint: red))
  line("surface1-0-2", "surface1-2-2", stroke: (thickness: 2pt, paint: green))

  line((11,2.5), (12,2.5), stroke: (thickness: 2pt, paint: green))
  content((14.3, 2.5), [Logical $X$: $l_x = X_1X_2X_3$])

  line((11.5,1.5), (11.5,0.5), stroke: (thickness: 2pt, paint: red))
  content((14.3, 1), [Logical $Z$: $l_z = Z_3Z_6Z_9$])
}))

Also we can have different sizes of the surface code.
#figure(canvas({
  import draw: *
  let n = 3
  surface-code((0, 0),size:1, 5, 5,name: "surface2")
  surface-code((5, 0),size:0.7, 7, 7,name: "surface3")
  surface-code((10, 0),size:0.6, 9, 9,name: "surface4")
  content((2, -0.75), [$d=5$])
  content((7.25, -0.75), [$d=5$])
  content((12.5, -0.75), [$d=9$])
}))

== Decoding problem
If some Pauli errors happened, some of the stabilizers will be anti-commute with the errors. When we measure them We usually call the measurement outcome of the all stabilizers as syndrome. The decoding problem is given the syndrome, find the probable error pattern that is consistent with the syndrome.

#definition([MLE Problem])[
    The most-likely error (MLE) problem is given the syndrome, find the most probable error pattern that is consistent with the syndrome. 
    $
    op("argmax",
     limits: #true)_(e) p(e) \ 
     "s.t." H(e) = s
    $
    where $H(e)$ is the syndrome of the error pattern $e$.
  ]

For a given error, applying any stabilizer to it leaves the syndrome unchanged. All such errors within the same degenerate class have an equivalent effect on the logical information. Thus, a better decoding approach than MLE is MLD (Maximum Likelihood Decoding), which directly determines the most probable logical effect of the error rather than the exact physical error.

#definition([MLD Problem])[
    The maximum likelihood decoding (MLD) problem is given the syndrome, find the most probable logical state by summing over all the error patterns that belong to the same degenerate class and are consistent with the syndrome. 
    $
    op("argmax",
     limits: #true)_(l) p(l) = op("argmax",
     limits: #true)_(l)sum_(L(e) = l \ H(e) = s) p(e)
    $
    where $H(e)$ is the syndrome of the error pattern $e$, $L(e)$ is the logical information of the error pattern $e$.
  ]

As shown, the MLD decoding problem involves summing over all error patterns within the same degenerate class that match the observed syndrome. This structure naturally lends itself to tensor network contraction methods. In the following section, we will introduce tensor network-based MLD decoder. Now we will give an example of the decoding problem.

#exampleblock([
*Example: Decoding problem*

Suppose there is an $X$ error on the qubit $2$.  The decoding process is to find the most probable error pattern that is consistent with the syndrome.

#figure(canvas({
  import draw: *
  let n = 3
  surface-code((0, 0),size:1.5, n, n,name: "surface1")
  for i in range(n) {
    for j in range(n) {
      content((rel: (0.3, 0.3), to: "surface1" + "-" + str(j) + "-" + str(2-i)), [#(i*n+j+1)])
    }
    }
  circle("surface1-1-2", radius: 0.3, fill: white, stroke: red,name:"q3")
  content("q3", text(red,11pt)[$X$])

  content((6, 1.4), box(stroke: black, inset: 6pt, [$X$ stabilizers: \ $X_1X_2X_4X_5$ \ $X_3X_6$ \ $X_4X_7$ \ $X_5X_6X_8X_9$],fill: aqua, radius: 4pt))
  content((10, 1.4), box(stroke: black, inset: 6pt, [$Z$ stabilizers: \ #text(fill: red)[$Z_1Z_2$] \ #text(fill: red)[$Z_2Z_3Z_5Z_6$] \ $Z_4Z_5Z_7Z_8$ \ $Z_8Z_9$],fill: yellow, radius: 4pt))
}))
Only stabilizer $Z_1Z_2$ and $Z_2Z_3Z_5Z_6$ is anti-commute with the error. So if we measure all the stabilizers, we will get six $+1$ and two $-1$. Base on this syndrome, decoders will try to find the most probable error pattern or logical state.
])
== Tensor network decoder
Here we directly give the tensor network representation@Piveteau2024@chubb2021general of the decoding problem. The dimension of the variables is 2.
#figure(canvas({
  import draw: *

  for j in range(9) {
    labelnode((j,0), [$x_#(j+1)$], name: "x-" + str(j+1))

    labelnode((j,2), [$z_#(j+1)$], name: "z-" + str(j+1))

    tensor((j,1), "rect-" + str(j+1), [$cal(D)$])
    line("x-" + str(j+1), "rect-" + str(j+1), stroke: black)

    line("z-" + str(j+1), "rect-" + str(j+1), stroke: black)
  }

  let checkx = ((1,2,4,5), (3,6), (4,7), (5,6,8,9))
  let checkz = ((1,2), (2,3,5,6), (4,5,7,8), (8,9))
  for k in range(4) {
    tensor((1.8*(k+1), 3), "xcheck-t-" + str(k+1), [$+$])
    labelnode((1.8*(k+1), 4), [$S_#(k+1)$], name: "xcheck-" + str(k+1))
    line("xcheck-t-" + str(k+1), "xcheck-" + str(k+1), stroke: black)
    for i in checkx.at(k) {
      line("xcheck-t-" + str(k+1), "z-" + str(i), stroke: black)
    }
  }

  for k in range(4) {
    tensor((1.8*(k+1), -1), "zcheck-t-" + str(k+1), [$+$])
    labelnode((1.8*(k+1), -2), [$S_#(k+5)$], name: "zcheck-" + str(k+1))
    line("zcheck-t-" + str(k+1), "zcheck-" + str(k+1), stroke: black)
    for i in checkz.at(k) {
      line("zcheck-t-" + str(k+1), "x-" + str(i), stroke: black)
    }
  }

  tensor((0,3), "xlogical-t-0", [$+$])
  labelnode((0,4), [$l_x$], name: "xlogical-0")
  line("xlogical-t-0", "xlogical-0", stroke: black)
  tensor((0,-1), "zlogical-t-0", [$+$])
  labelnode((0,-2), [$l_z$], name: "zlogical-0")
  line("zlogical-t-0", "zlogical-0", stroke: black)

  let logical_x = (1,2,3)
  let logical_z = (3,6,9)
  for k in range(3) {
    line("xlogical-t-0", "z-" + str(logical_x.at(k)), stroke: black)
    line("zlogical-t-0", "x-" + str(logical_z.at(k)), stroke: black)
  }
}))

In the middle of the figure, we have 9 tensors represent the depolarizing channel acts on the physical qubits.  
#figure(canvas({
  import draw: *

  tensor((0,0), "rect-label", [$cal(D)$])
  line("rect-label",(rel: (0, -1), to: "rect-label"), stroke: black)
  line("rect-label",(rel: (0, 1), to: "rect-label"), stroke: black)
  content((rel: (1.5, -0.2), to: "rect-label"), text(12pt)[$= mat(p_I, p_Z ;p_X, p_Y)$])
  content((rel: (6, 0.3), to: "rect-label"), text(12pt)[Depolarizing Channel:])
  content((rel: (10, -0.4), to: "rect-label"), text(12pt)[$ cal(D)(rho) = (1-p_X-p_Y-p_Z)rho + p_X X rho X + p_Y Y rho Y + p_Z Z rho Z$])
}))
The variables connected to the depolarizing channel represent Boolean variables indicating $X$ or $Z$ errors on the physical qubits. The $+$ tensors are the parity tensors.

#figure(canvas({
  import draw: *

  tensor((7, 0), "check-label", [$+$])

  line("check-label",(rel: (0, 1.2), to: "check-label"), stroke: black)
  content((rel: (0, 1.6), to: "check-label"), text(15pt)[$j_1$])

  line("check-label",(rel: (1.2, 0), to: "check-label"), stroke: black)
  content((rel: (1.6, 0), to: "check-label"), text(15pt)[$j_2$])

  line("check-label",(rel: (1, -1), to: "check-label"), stroke: black)
  content((rel: (1.4, -1.4), to: "check-label"), text(15pt)[$j_3$])

  line("check-label",(rel: (-1, -1), to: "check-label"), stroke: black)
  content((rel: (-1.4, -1.4), to: "check-label"), text(15pt)[$j_k$])

  content((rel: (0, -1.1), to: "check-label"), text(25pt)[$...$])


  content((rel: (6, 0), to: "check-label"), text(12pt)[$T(j_1, j_2, j_3, ..., j_k) = cases(1 "if" j_1 + j_2 + ... + j_k "is even",
  0 "if" j_1 + j_2 + ... + j_k "is odd",)
 $])
 content((rel: (6, -1), to: "check-label"),text(12pt)[$j_1, j_2, j_3, ..., j_k in {0, 1}$])
}))
The stabilizer variables are fixed to the measured syndrome values, while the logical variables represent the marginal probabilities computed via tensor network contraction. After contracting such a tensor network, we can get the marginal probability of the logical variables. 
#bibliography("refs.bib")
