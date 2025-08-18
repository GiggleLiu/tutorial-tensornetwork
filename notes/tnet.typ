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

#let definition = thmbox("definition", "Definition", inset: (x: 1.2em, top: 1em, bottom: 1em), base: none, stroke: black)
#let theorem = thmbox("theorem", "Theorem", base: none, stroke: black)
#let proof = thmproof("proof", "Proof")
#let ket(it) = [$|#it angle.r$]

// hide contents under development
#let hide-dev = false
#let dev(it) = if not hide-dev {it}

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
A _tensor network_ is a fundamental concept in quantum physics and quantum information theory that provides a powerful diagrammatic representation for multilinear algebra operations. This framework shares similarities with _einsum_ notation@Harris2020, _unweighted probability graphs_@Bishop2006, _sum-product networks_, and _junction trees_@Villescas2023 found in other computational domains.

Tensor networks have found widespread applications across diverse fields, including quantum circuit simulation@Markov2008, quantum error correction@Piveteau2024, neural network compression@Qing2024, and many-body quantum system dynamics@Haegeman2016. Their versatility stems from their ability to efficiently represent and manipulate high-dimensional mathematical objects through intuitive graphical representations.

== Definition
At its core, a _tensor network_ provides a diagrammatic representation of _multilinear algebra_. To understand this concept, let's first recall that linear algebra deals with linear functions satisfying two fundamental properties:
- Additivity: $f(x + y) = f(x) + f(y)$ for any vectors $x$ and $y$
- Homogeneity: $f(alpha x) = alpha f(x)$ for any scalar $alpha$

A function $f$ is called _multilinear_ if it maintains linearity with respect to each of its multiple arguments. For instance, the inner product of two vectors $x$ and $y$ is bilinear since it is linear in both $x$ and $y$. 

Consider the chain multiplication of matrices:
$
  O_(i n) = sum_(j,k,l,m) A_(i j) B_(j k) C_(k l) D_(l m) E_(m n)
$ <eq:tensor-contraction>
The output $O_(i n)$ depends linearly on each input tensor, making this a _multilinear map_ known as _tensor contraction_. Tensor networks extend this concept to arbitrary tensors with multiple indices, where we represent each tensor as a node and each index as a connecting edge or "leg." This graphical notation provides an intuitive way to visualize complex multilinear operations.

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
This diagrammatic representation offers significant advantages over algebraic notation by making the computational structure immediately visible. The connected indices represent summation variables, while unconnected indices correspond to the output tensor's dimensions. This visual clarity becomes particularly valuable when analyzing complex tensor contractions, as demonstrated in the following example.

#exampleblock([
*Example: Proving the trace permutation rule*

Consider three square matrices $A$, $B$, and $C$ of the same dimension. The trace permutation rule states that $tr(A B C) = tr(C A B) = tr(B C A)$. This identity can be elegantly demonstrated using tensor network diagrams.

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

In this diagram, the cyclic connection of indices creates a closed loop that represents the trace operation. Regardless of which matrix we designate as the "starting point," the topological structure remains invariant. This visual proof immediately reveals why the three expressions $tr(A B C)$, $tr(C A B)$, and $tr(B C A)$ are equivalent—they correspond to identical tensor network contractions. The diagrammatic approach thus provides a more intuitive understanding than algebraic manipulation alone.
])


== Einsum notation and computational complexity
In computational implementations, tensor network topologies are commonly specified using `einsum` notation—a compact string representation that encodes the contraction structure. In this notation,
- `->` separates the input and output tensors
- `,` separates the indices of different input tensors
- each char represents an index
For example, matrix multiplication $C = A B$ is represented as `ij,jk->ik`, where the two input matrices are represented by `ij` and `jk`, and the output matrix is represented by `ik`.

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

Contraction complexity can be analyzed from multiple complementary perspectives:

- *Time complexity* ($100^4$ operations): Represents the total number of floating-point operations (FLOPs) required for the contraction. For einsum operations, this equals the product of all unique index dimensions, since each unique index either participates in summation or appears in the output. As we'll see later, smart contraction ordering can dramatically reduce this complexity.

- *Space complexity* ($100^2$ elements): Measures the peak memory requirement for storing the largest intermediate tensor generated during contraction. This determines the minimum memory needed to execute the computation.

- *Read-write complexity* ($4 times 100^2$ operations): Quantifies total memory bandwidth usage by counting all floating-point numbers transferred between memory and processor throughout the contraction. This metric captures the cumulative cost of accessing all intermediate tensors and often determines real-world performance on bandwidth-limited systems.

While `EinCode` objects are callable and can directly perform contractions:

```julia
julia> code(randn(2, 2), randn(2, 2), randn(2, 2))  # not recommended
2×2 Matrix{Float64}:
 -0.974692  3.06151
 -0.674225  1.40281
```

This approach is *strongly discouraged* because `OMEinsum` uses an unoptimized contraction order that may be exponentially inefficient. A better approach explicitly specifies the contraction order using parentheses:

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
*Example A: Star contraction*

The star contraction of three matrices $A, B, C in bb(R)^(n times n)$ is defined as:
$
O_(i j k) = sum_a A_(i a) B_(a j) C_(a k)
$

This operation creates a 3-way tensor by connecting all matrices through a shared summation index:

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

*Example B: Kronecker product*

The Kronecker product of two matrices $A, B in bb(R)^(n times n)$ is defined as:
$
C_(i j k l) = A_(i j) B_(k l)
$

Unlike the star contraction, this operation has no shared indices:

#figure(canvas({
  import draw: *
  tensor((1, 1), "A", "A")
  tensor((3, 1), "B", "B")
  labeledge("A", (rel: (0, -1.5)), "j")
  labeledge("A", (rel: (0, 1.5)), "i")
  labeledge("B", (rel: (0, -1.5)), "l")
  labeledge("B", (rel: (0, 1.5)), "k")
}), numbering: none)

The einsum notation is `ij,kl->ijkl` with time complexity $O(n^4)$. The absence of connections reflects the direct product structure.
])

=== Tensor network contraction is \#P-complete
Contracting a tensor is hard, which is in \#P-complete (harder than the famous NP-complete). Showing a problem is hard can be done through reduction.
If we can reduce problem $cal(A)$ to problem $cal(B)$, which means by solving problem $cal(B)$ (in time polynomial to input size), we can solve problem $cal(A)$ with the answer to $cal(B)$.
Then $cal(B)$ is not easier than $cal(A)$ from computational complexity perspective.

The computational complexity of general tensor network contraction can be established by reduction from a known \#P-complete problem: counting satisfying assignments of 2-SAT formulas.

#definition([2-SAT formula], [
    A 2-SAT formula is a Boolean formula in conjunctive normal form (CNF) where each clause contains at most two literals.
    For those who are not familiar with boolean logic, a clause is a disjunction (logical or: $or$) of literals, and a literal is a boolean variable or its negation ($not$).
    A boolean formula can always be represented as a conjunction (logical and: $and$) of clauses, which is called the conjunctive normal form.

*Example:*
$
  (x_1 or x_2) and (x_2 or x_3) and (x_3 or x_4) and (x_4 or x_5) and (x_5 or x_1) and (x_3 or not x_5)
$ <eq:2sat>

- A satisfying assignment is: $x_1 = 1, x_2 = 0, x_3 = 1, x_4 = 0, x_5 = 1$.
- A non-satisfying assignment is: $x_1 = 1, x_2 = 0, x_3 = 0, x_4 = 0, x_5 = 1$, since it violates $x_2 or x_3$, $x_3 or x_4$ and $x_3 or not x_5$.

The counting of 2-SAT formula asks how many satisfying assignments are there.
])

While determining satisfiability (finding any solution) for 2-SAT formulas is polynomial-time solvable, counting the *number* of satisfying assignments is \#P-complete—a complexity class considered even more challenging than NP-complete problems.

The reduction proceeds by encoding the 2-SAT counting problem as a tensor network:

*Step 1: Clause encoding.* The boolean variables $x_1, x_2, ..., x_n$ directly maps to (hyper)edges in tensor network, now we need to decide the tensors relating these variables. Each clause becomes a rank-2 tensor encoding its truth table. For the clause $(x_3 or not x_5)$, we construct tensor $T_(+-)$:
$
  T_(+-) = mat(1, 0; 1, 1)
$
where rows correspond to $x_3 in {0, 1}$ and columns to $x_5 in {0, 1}$. The entry $(T_(+-))_(0,1) = 0$ indicates that $x_3 = 0, x_5 = 1$ makes the clause false. Similar tensors $T_(++)$, $T_(--)$, and $T_(-+)$ encode other clause types.

*Step 2: Network construction.* The counting problem reduces to the tensor contraction:
$
  "count" = sum_(x_1, x_2, dots, x_n) product_("clauses") T_("clause")
$
where the summation spans all Boolean assignments and the product combines all clause tensors. This contraction precisely counts satisfying assignments.
Note tensor network contraction corresponds to sum of product of elements from each tensor, whenever a tensor contributes a zero multiplication factor, the net contribution of this assignment is 0. On the other hand, since we have a 0-1 element only, if all the tensors contribute a 1 multiplication factor (means this constraint is satisfied), the net contribution of this assignment is 1. Hence the contraction corresponds to the counting of true assignments.

For the 2-SAT formula in @eq:2sat, the corresponding tensor network is:
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


Since counting satisfying assignments for 2-SAT is \#P-complete, and we have demonstrated a polynomial-time reduction from this problem to tensor network contraction, it follows that general tensor network contraction is also \#P-complete. This establishes tensor network optimization as fundamentally intractable, motivating the development of approximation algorithms and heuristic methods discussed in subsequent sections.

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

The left ordering is dramatically superior: it achieves $O(n^3)$ time and $O(n^2)$ space complexity by first contracting compatible matrices. The right ordering creates a $O(n^4)$ intermediate tensor through an inefficient Kronecker product, illustrating how ordering choice can determine computational feasibility.

Finding the globally optimal contraction order constitutes an NP-complete optimization problem@Markov2008. Fortunately, near-optimal solutions often suffice for practical applications and can be obtained efficiently through sophisticated heuristic methods. Modern optimization algorithms have achieved remarkable scalability, successfully handling tensor networks with over $10^4$ tensors@Gray2021,@Roa2024.

The optimal contraction order has a deep mathematical connection to the _tree decomposition_@Markov2008 of the tensor network's line graph.
#definition([Tree decomposition and treewidth], [A _tree decomposition_ of a (hyper)graph $G=(V,E)$ is a tree $T=(B,F)$ where each node $B_i in B$ contains a subset of vertices in $V$ (called a "bag"), satisfying:

1. Every vertex $v in V$ appears in at least one bag.
2. For each (hyper)edge $e in E$, there exists a bag containing all vertices in $e$.
3. For each vertex $v in V$, the bags containing $v$ form a connected subtree of $T$.

The _width_ of a tree decomposition is the size of its largest bag minus one. The _treewidth_ of a graph is the minimum width among all possible tree decompositions.
])


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
Let us define a complex matrix $A in CC^(m times n)$, and let its singular value decomposition be
$
A = U S V^dagger
$
where $U$ and $V$ are unitary matrices and $S$ is a diagonal matrix with non-negative real numbers on the diagonal. Let $s$ be the diagonal part of $S$, the diagramatic representation of SVD decomposition is
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

Let us denote $d_i = dim(i)$, $d_j = dim(j)$, $d_k = dim(k)$, $d_s = dim(s)$. For data compression, we reqire $d_k < min(d_i, d_j)$, the compression ratio can be computed as: $(d_i d_j)/(d_k (d_i + d_j))$.

=== CP-decomposition

For example, the CP-decomposition of a rank-4 tensor $T$ can be represented as
$
T_(i j k l) = sum_(c) U_1^(i c) U_2^(j c) U_3^(k c) U_4^(l c) Lambda_(c)
$

#align(center, text(10pt, canvas({
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
})))

The data compression ratio for CP-decomposition is $(product_(i=1)^N d_i) / (R sum_(i=1)^N d_i)$, where $d_i$ is the dimension of the $i$-th mode, $N$ is the number of modes, and $R$ is the rank (dimension of the shared index $c$). For the rank-4 case shown above, this becomes $(d_i d_j d_k d_l) / (R(d_i + d_j + d_k + d_l + 1))$.

=== Tucker decomposition

The Tucker decomposition of a rank-4 tensor $T$ can be represented as
$
T_(i j k l) = sum_(a,b,c,d) U_1^(i a) U_2^(j b) U_3^(k c) U_4^(l d) X_(a b c d)
$
where $U_1, U_2, U_3, U_4$ are unitary matrices and $X$ is a rank-4 tensor.

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

Tucker decomposition is more flexible than CP decomposition as it allows different compression ratios for different modes, but it suffers from the curse of dimensionality as the core tensor $X$ grows exponentially with the number of modes.


=== Tensor Train

Tensor Train (TT) is a specific tensor network architecture that represents high-dimensional tensors as a chain of lower-rank tensors, providing an efficient compressed representation:
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
=== Example: Compress a high dimensional tensor with tensor train
In this example, we show how to compress a high dimensional tensor with tensor train. We start from defining the data structure.
```julia
using OMEinsum, LinearAlgebra

struct MPS{T}
    tensors::Vector{Array{T, 3}}
end
```

The main algorithm is implemented as follows:
```julia
# Function to compress a tensor using Tensor Train (TT) decomposition
function tensor_train_decomposition(tensor::AbstractArray, largest_rank::Int; atol=1e-6)
    dims = size(tensor)
    n = length(dims)
    tensors = Array{Float64, 3}[]
    rpre = 1  # virtual bond dimension size
    current_tensor = reshape(tensor, dims[1], :)
    for i in 1:(n-1)
        # Perform SVD
        U_truncated, S_truncated, V_truncated, r = truncated_svd(current_tensor, largest_rank, atol)
        push!(tensors, reshape(U_truncated, (rpre, dims[i], r)))
        
        # Prepare the tensor for the next iteration
        current_tensor = reshape(S_truncated * V_truncated', r * dims[i+1], :)
        rpre = r
    end
    push!(tensors, reshape(current_tensor, (rpre, dims[n], 1)))
    return MPS(tensors)
end
```

We basically iteratively call the truncated singular value decomposition (SVD) to reduce the virtual bond dimension.

```julia
function truncated_svd(current_tensor::AbstractArray, largest_rank::Int, atol)
    U, S, V = svd(current_tensor)
    r = min(largest_rank, sum(S .> atol))  # error estimation
    S_truncated = Diagonal(S[1:r])
    U_truncated = U[:, 1:r]
    V_truncated = V[:, 1:r]
    return U_truncated, S_truncated, V_truncated, r
end
```

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

As an example, we compress a uniform tensor of size 2^20.
```julia
tensor = ones(Float64, fill(2, 20)...);
mps = tensor_train_decomposition(tensor, 5)
reconstructed_tensor = contract(mps);

relative_error = norm(tensor - reconstructed_tensor) / norm(tensor)
# output: 5.114071183432393e-12

original_size = prod(size(tensor))
compressed_size = sum([prod(size(core)) for core in mps.tensors])
compression_ratio = original_size / compressed_size
# output: 26214.4
```

The virtual bond dimension has size $chi = 1$, which means each tensor has only $chi^2 d = 2$ elements.
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


#dev(
[
== Complex numbers, a tensor network perspective

A complex number is composed of two real numbers, hence we can use a real tensor with one more dimension to represent complex tensors. For example, to represent a matrix, we can use a rank 3 tensor:
#figure(canvas({
    import draw: *
    let s(it) = text(11pt, it)
    tensor((0, 0), "A", s[])
    line("A", (rel: (-1, 0)))
    line("A", (rel: (1, 0)))
    line("A", (rel: (0, -1)), stroke: green)
}), numbering: none)
where we use the green color to denote the extra dimension of size 2.

In this representation, complex conjugate is a linear operator. It is equivalent to apply Pauli-Z on the extra dimension:
#figure(canvas({
    import draw: *
    let s(it) = text(11pt, it)
    content((-1.7, 0), s[$A^* = $])
    tensor((0, 0), "A", s[A])
    tensor((0, -1), "Z", s[Z])
    line("A", (rel: (-1, 0)))
    line("A", (rel: (1, 0)))
    line("A", "Z", stroke: green)
    line("Z", (rel: (0, -0.7)), stroke: green)
}), numbering: none)

Similarly, the operation of adding a phase factor $e^(i phi)$ can be represented as a rotation operation applied on the extra dimension:
#figure(canvas({
    import draw: *
    let s(it) = text(11pt, it)
    content((-1.9, 0), s[$e^(i phi)A = $])
    tensor((0, 0), "A", s[A])
    tensor((0, -1), "Z", s[$R_phi$])
    line("A", (rel: (-1, 0)))
    line("A", (rel: (1, 0)))
    line("A", "Z", stroke: green)
    line("Z", (rel: (0, -0.7)), stroke: green)
    content((4, -0.5), s[$R_phi = mat(cos phi, -sin phi; sin phi, cos phi)$])
}), numbering: none)

Let us define a permutation symmetric tensor $cal(C)$ as:
$
cal(C) = vec(mat(1, 0; 0, -1), mat(0, -1; -1, 0))
$

Given a matrix multiplication $C = A B$, let us stack the real part of $A$ as a 3D tensor $T_A$, and $B$ as a 3D tensor $T_B$. We can redefine the matrix multiplication as tensor contraction:
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((-3, 0), "C", s[$T_C$])
  line("C", (rel: (-1, 0)))
  line("C", (rel: (1, 0)))
  line("C", (rel: (0, -1)), stroke: green)
  content((-1.5, 0), s[$=$])
  tensor((0, 0), "A", s[$T_A$])
  tensor((2, 0), "B", s[$T_B$])
  tensor((1, -1), "c", s[$cal(C)$])
  tensor((1, -2), "d", s[$Z$])
  line("A", "B")
  line("A", (rel: (-1, 0)))
  line("B", (rel: (1, 0)))
  line("A", (rel: (0, -1)), "c", stroke: green)
  line("B", (rel: (0, -1)), "c", stroke: green)
  line("c", "d", stroke: green)
  line("d", (rel: (0, -0.7)), stroke: green)
}), numbering: none)
where the green color indicates the extra dimension of size 2 for representing the complex numbers.
We use this formalism to drtive the complex valued backward rule.
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  content((-2, -1), s[$overline(T)_B = $])
  tensor((1, -3), "C", s[$overline(T)_C$])
  tensor((0, 0), "A", s[$T_A$])
  tensor((2, 0), "B", s[$T_B$])
  tensor((1, -1), "c", s[$cal(C)$])
  tensor((1, -2), "d", s[$Z$])
  line("A", "B")
  line("A", (rel: (0, -1)), "c", stroke: green)
  line("B", (rel: (0, -1)), "c", stroke: green)
  line("c", "d", stroke: green)
  line("d", "C", stroke: green)

  line("C", (rel: (-2, 0)), (rel: (0, 3)), "A")
  line("C", (rel: (2, 0)), (rel: (0, 3)), "B")
  
  hobby((1, 0.5), (2, -1), (4, 0), stroke: (dash: "dashed"))
  content((3, 0.5), s[remove])
}), numbering: none)

It corresponds to first take conjugate of $overline(T)_C$, the compute the tensor contraction, and followed by a conjugate, i.e. $overline(T)_B = (T_A * overline(T)_C^*)^*$.


```julia
using OMEinsum

n = 10
m = randn(ComplexF64, n, n)
n = randn(ComplexF64, n, n)
s = cat(real(m), imag(m), dims=3)
t = cat(real(n), imag(n), dims=3)
c = zeros(2, 2, 2)
c[:, :, 1] = [1 0; 0 -1]
c[:, :, 2] = [0 -1; -1 0]
z = [1 0; 0 -1]

res1 = m * n; res1 = cat(real(res1), imag(res1), dims=3)
res2 = ein"ija,jkb,abc,cd->ikd"(s, t, c, z)
@assert res1 ≈ res2
```

The norm square of a vector is even more straight forward, it is just sum of the norm of the real and imaginary parts. Diagramatically, it can be represented as:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "A", s[$T_w$])
  tensor((2, 0), "B", s[$T_v$])
  line("A", "B")
  line("A", (rel: (-1, 0)), (rel: (0, -1)), (rel: (1, -1), to: "B"), (rel: (0, 1)), "B", stroke: green)
}), numbering: none)

=== Some properties of $cal(C)$ operator
- permutation invariance
 #figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "c", s[$cal(C)$])
  bezier("c.south", (rel: (0.9, 0), to: "c"), (rel: (-0.4, -0.7)), (rel: (0.7, 0), to: "c"), stroke: green)
  bezier("c.east", (rel: (0, -0.9), to: "c"), (rel: (0.7, 0.4)), (rel: (0, -0.7), to: "c"), stroke: green)
  line("c", (rel: (-0.7, 0)), stroke: green)

  content((1.5, 0), s[$=$])

  set-origin((2.5, 0))
  tensor((0, 0), "c", s[$cal(C)$])
  line("c", (rel: (0, -0.7)), stroke: green)
  line("c", (rel: (0.7, 0)), stroke: green)
  line("c", (rel: (-0.7, 0)), stroke: green)
}), numbering: none)

- conjugate invariance
 #figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "c", s[$cal(C)$])
  tensor((0, -1), "d1", s[$Z$])
  tensor((1, 0), "d2", s[$Z$])
  tensor((-1, 0), "d3", s[$Z$])
  line("c", "d1", stroke: green)
  line("c", "d2", stroke: green)
  line("c", "d3", stroke: green)
  line("d1", (rel: (0, -0.7)), stroke: green)
  line("d2", (rel: (0.7, 0)), stroke: green)
  line("d3", (rel: (-0.7, 0)), stroke: green)

  content((2, 0), s[$=$])

  set-origin((3, 0))
  tensor((0, 0), "c", s[$cal(C)$])
  line("c", (rel: (0, -0.7)), stroke: green)
  line("c", (rel: (0.7, 0)), stroke: green)
  line("c", (rel: (-0.7, 0)), stroke: green)
}), numbering: none)
- cascade rule
 #figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "c1", s[$cal(C)$])
  tensor((1, -1), "c2", s[$cal(C)$])
  tensor((0, -1), "z", s[$Z$])
  line("c1", (rel: (-0.7, 0)), (rel: (0, 0.7)), stroke: green)
  line("c1", (rel: (0, 0.7)), stroke: green)
  line("c1", "z", stroke: green)
  line("c2", "z", stroke: green)
  line("c2", (rel: (0, 1.7)), stroke: green)
  line("c2", (rel: (0, -0.7)), stroke: green)

  content((2, 0), s[$=$])

  set-origin((3, 0))
  tensor((0, -1), "c1", s[$cal(C)$])
  tensor((1, 0), "c2", s[$cal(C)$])
  tensor((1, -1), "z", s[$Z$])
  line("c2", (rel: (0.7, 0)), (rel: (0, 0.7)), stroke: green)
  line("c1", (rel: (0, 1.7)), stroke: green)
  line("c2", "z", stroke: green)
  line("c1", "z", stroke: green)
  line("c2", (rel: (0, 0.7)), stroke: green)
  line("c1", (rel: (0, -0.7)), stroke: green)


}), numbering: none)

])
= Quantum Circuit Simulation

== Quantum states and quantum gates
Quantum circuits provide a natural framework for tensor network representations, where quantum states become vectors and quantum gates become tensors.

A quantum system initialized to $|0 angle.r^(times.circle n)$ (the $n$-fold tensor product of $|0 angle.r$ states) decomposes as a direct product of $n$ individual qubits:

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

where each $|0 angle.r = mat(1; 0)$ state is represented as a rank-1 tensor. Single-qubit gates correspond to rank-2 tensors (matrices) that transform individual qubits. For instance, applying a Hadamard gate $H$ to the first qubit creates the following tensor network:

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

Multi-qubit gates create more complex tensor network structures. The CNOT gate, fundamental to quantum computation, can be decomposed into a tensor network representation:

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

This decomposition (ignoring normalization factors) illustrates how two-qubit gates introduce entanglement through shared virtual indices connecting different physical qubits.

=== Useful circuit identities

Tensor network representations make certain quantum circuit identities immediately apparent through graphical manipulation. Several fundamental rules simplify complex circuits:

*Identity 1: Hadamard on computational basis state*
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

This transforms $|0 angle.r$ into the $|+ angle.r = (|0 angle.r + |1 angle.r)/sqrt(2)$ state.

*Identity 2: Hadamard conjugation of Pauli gates*
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

The Hadamard gate transforms Pauli-Z into Pauli-X: $H Z H = X$. This basis transformation is fundamental to many quantum algorithms.

*Identity 3: Controlled-Z*
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
A controlled-Z gate (CZ) can be implemented using a single tensor connecting both qubits, demonstrating how entangling operations create shared virtual bonds in the tensor network. If you do not believe it, we can easily verify this equality with OMEinsum:

```julia
julia> reshape(ein"ij->ijij"([1 1; 1 -1]), 4, 4)
4×4 Matrix{Int64}:
 1  0  0   0
 0  1  0   0
 0  0  1   0
 0  0  0  -1
```


=== Expectation values

Computing expectation values of observables in quantum circuits translates to a specific tensor network contraction pattern. For a quantum state $|psi angle.r = U|0^n angle.r$ and observable $O$, the expectation value $angle.l psi|O|psi angle.r$ has the tensor network representation:

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

This "sandwich" structure represents the quantum expectation value formula $angle.l 0^n|U^dagger O U|0^n angle.r$, where the observable $O$ is inserted between the forward circuit $U$ and its conjugate $U^dagger$.

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

The Hadamard test is a quantum algorithm used to estimate the expectation value of a unitary operator $U$ with respect to a quantum state $|psi angle.r$. It provides a way to measure $angle.l psi | U | psi angle.r$ using an ancilla qubit.

*Hadamard test circuit*

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

The ZX-calculus@Duncan2019 is a graphical language for reasoning about quantum circuits and processes. It represents quantum operations as diagrams composed of nodes (spiders) and wires, governed by rewrite rules that preserve quantum mechanical equivalence. Unlike traditional tensor networks, ZX-calculus provides a complete graphical language—any equation that holds between quantum processes can be derived using ZX rules.

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

A quantum channel $cal(E)$ can be represented using Kraus operators ${K_i}$ such that for any density matrix $rho$:

$ cal(E)(rho) = sum_i K_i rho K_i^dagger $

where the Kraus operators satisfy the completeness relation:

$ sum_i K_i^dagger K_i = I $

Kraus operators are a *completely positive (CP) and trace preserving (TP) map* on the density matrix space, which is a linear map that preserves the positivity and the probability of the density matrix.

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
Quantum error correction(QEC) is a process of protecting quantum information from errors@nielsen2010quantum@gottesman1997stabilizer@calderbank1996good. The errors can be caused by the environment, the control system, or the quantum gates. The quantum error correction is a process of encoding the quantum information into a larger Hilbert space such that the quantum information can be recovered from the errors. Usually, a quantum error correction scheme is described by a stabilizer group.

== Stablizers and Quantum Codes
In this section, we will introduce the concept of stabilizers and quantum codes.
#definition([Pauli Group and Stabilizer Group], [A _stabilizer group_ $cal(S)$ is an Abelian subgroup of the $n$-qubit Pauli group. The $n$-qubit pauli group is the group generated by the $n$-qubit Pauli matrices@gaitan2008quantum
$
cal(P)_n = (plus.minus i){I, X, Y, Z}^(times.circle n)
$ 
We usually call the elements of the Pauli group pauli operators or pauli strings.
])

The stabilizer group is abelian means that it is commutative and the measurement outcome of any two stabilizers will not affect each other. We can specify a stabilizer group by giving a set of independent stabilizer generators ${S_a}_(a=1,...,m)$
$
cal(S) = angle.l S_1, S_2,...,S_m angle.r.
$
The code space is the $+1$ eigenspace of all the stabilizers. We can detect whether a state is in the code space by only measuring the generators of the stabilizer group. If any of the generators gives $-1$, then the state is not in the code space. And we call such an outcome a symdrome. It is worth mentioned that this measurement will not cause the quantum computing collapse, since we only measure the stabilizers and the final state is in a subspace of the original Hilbert space, which is the code space or an error space. The entanglements in the code space are not destroyed.


#definition(
  [Quantum Code],[
    An $[[n,k,d]]$ quantum code is a quantum error correction scheme that encodes a $k$-qubit subspace of an $n$-qubit Hilbert space with minimum distance $d$. The minimum distance is the minimum pauli operators that need to be apllied on one code word to get to another code word.
  ])

Usually, we can specify an $[[n,k,d]]$ quantum code by giving a set of $n-k$ independent stabilizer generators.

#definition(
  [CSS Code@calderbank1996good@steane1996error@steane1996multiple],[
    We call a quantum stabilizer code a Calderbank-Shor-Steane (CSS) code if the stabilizer group can be generated by pauli matrices that only contain $X$ or $Z$ operators, i.e.,
    
    $
    cal(S) = angle.l S_a angle.r_(a=1,...,n-k), "where" S_a in {I, X}^(times.circle n) union {I, Z}^(times.circle n)
    $
  ]
)
In short, a CSS code is a type of quantum code that can be constructed using only $X$ and $Z$ operators. Moreover, most quantum codes encountered in practice belong to the CSS family.

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

#definition(
  [MLE Problem],[
    The most-likely error(MLE) problem is given the syndrome, find the most probable error pattern that is consistent with the syndrome. 
    $
    op("argmax",
     limits: #true)_(e) p(e) \ 
     "s.t." H(e) = s
    $
    where $H(e)$ is the syndrome of the error pattern $e$.
  ])

For a given error, applying any stabilizer to it leaves the syndrome unchanged. All such errors within the same degenerate class have an equivalent effect on the logical information. Thus, a better decoding approach than MLE is MLD (Maximum Likelihood Decoding), which directly determines the most probable logical effect of the error rather than the exact physical error.

#definition(
  [MLD Problem],[
    The maximum likelihood decoding(MLD) problem is given the syndrome, find the most probable logical state by summing over all the error patterns that belong to the same degenerate class and are consistent with the syndrome. 
    $
    op("argmax",
     limits: #true)_(l) p(l) = op("argmax",
     limits: #true)_(l)sum_(L(e) = l \ H(e) = s) p(e)
    $
    where $H(e)$ is the syndrome of the error pattern $e$, $L(e)$ is the logical information of the error pattern $e$.
  ])

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

  content((rel: (2.1, 0.2), to: "check-label"), text(25pt)[$:$])

  content((rel: (6, 0), to: "check-label"), text(12pt)[$T(j_1, j_2, j_3, ..., j_k) = cases(1 "if" j_1 + j_2 + ... + j_k "is even",
  0 "if" j_1 + j_2 + ... + j_k "is odd",)
 $])
 content((rel: (6, -1), to: "check-label"),text(12pt)[$j_1, j_2, j_3, ..., j_k in {0, 1}$])
}))
The stabilizer variables are fixed to the measured syndrome values, while the logical variables represent the marginal probabilities computed via tensor network contraction. After contracting such a tensor network, we can get the marginal probability of the logical variables. 
#bibliography("refs.bib")
