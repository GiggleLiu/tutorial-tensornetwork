#import "@preview/cetz:0.4.0": canvas, draw, tree
#import "@preview/cetz-plot:0.1.2": *
#import "@preview/ctheorems:1.1.3": *
#import "@preview/ouset:0.2.0": ouset
#import "@preview/quill:0.7.1": *

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
_Tensor network_ is an important concept in quantum physics and quantum information, it is similar to  _einsum_@Harris2020, _unweighted probability graph_@Bishop2006, _sum product network_ and _junction tree_@Villescas2023 in other fields.
It has been widely used to simulate quantum circuits@Markov2008, decode quantum error correction codes (which reference?), compress neural networks@Qing2024, and simulate the dynamics of a quantum system@Haegeman2016.

== Definition
In short, _Tensor network_ is a diagrammatic representation of _multilinear algebra_. Consider multiplying a sequence a matrices:
$
  O_(i n) = sum_(j,k,l,m) A_(i j) B_(j k) C_(k l) D_(l m) E_(m n)
$ <eq:tensor-contraction>
The output $O_(i n)$ is linear to each input tensor, and we have multiple input tensors. So, this operation defines a _multilinear map_, which is called _tensor contraction_. In tensor network, we further generalizes it to tensors with multiple indices. We represent a tensor as a node, and an index as a leg. For example, vectors, matrices and higher order tensors can be represented as:

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

The diagramatic representation of @eq:tensor-contraction is:
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
This diagrammatic representation is more intuitive than the algebraic representation, which can be better seen from the following example.

#exampleblock([
*Example: Proving trace permutation rule*

Let $A, B$ and $C$ be three square matrices with the same size. The trace permutation rule $tr(A B C) = tr(C A B) = tr(B C A)$ can be proved by the following tensor network diagram.

#figure(canvas({
  import draw: *
  tensor((1, 1), "A", "A")
  tensor((3, 1), "B", "B")
  tensor((5, 1), "C", "C")
  labeledge("A", "B", "j")
  labeledge("B", "C", "k")
  bezier("A.north", "C.north", (1, 3), (5, 3), name:"line")
  content("line.mid", "i", align: center, fill:white, frame:"rect", padding:0.1, stroke: none)
}))
From the diagram, we can see the representation of $tr(A B C)$, $tr(C A B)$ and $tr(B C A)$ are identical, indicating the same operation. The diagrammatic representation is less redundant than the algebraic representation.
])


== Einsum notation and computational complexity
In the program, a tensor network topology can be specified with `einsum` notation, which uses a string to denote the tensor network topology. For example, the matrix multiplication can be represented as `ij,jk->ik`. The intputs and outputs are separated by `->`, and the indices of different input tensors are separated by commas.
In the following, we use the `OMEinsum` package to demonstrate how to specify a tensor network topology, optimize the contraction order, and perform the contraction. A tensor network topology can be specified with the `ein` string literal, or the more flexible `EinCode` constructor.

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

Contraction complexity can be measured from different perspectives:
- The _time complexity_ is $100^4$, which represents the number of floating-point operations (FLOPs) required to contract the tensor network. For an einsum contraction, this is determined by multiplying the sizes of all unique indices involved, since a unique index either appears under the summation sign or in the output tensor. Later we will see the time complexity can be reduced by specifying the contraction order.
- The _space complexity_ is $100^2$, which measures the memory required to store the largest intermediate tensor during contraction.
- The _read-write complexity_ is $4 times 100^2$, which quantifies the total memory bandwidth usage by counting the number of floating-point numbers read from and written to memory during the entire contraction process. This is proportional to the total size of all intermediate tensors.

The `EinCode` object is callable, which can be used to perform the contraction.

```julia
julia> code(randn(2, 2), randn(2, 2), randn(2, 2))  # not recommended
2×2 Matrix{Float64}:
 -0.974692  3.06151
 -0.674225  1.40281
```
However, this is not recommended, since the unordered contraction is not optimized in `OMEinsum`. A better way to to specify an order for it:

```julia
julia> nested_code = ein"(ab,bc),cd->ad"
ac, cd -> ad
├─ ab, bc -> ac
│  ├─ ab
│  └─ bc
└─ cd
```
The return type is a `NestedEinsum` object, which performs a two step contraction. The first step is to contract the first two input tensors, and the second step is to contract the result with the third tensor. The time complexity is significantly reduced.

```julia
julia> contraction_complexity(nested_code, label_sizes)
Time complexity: 2^20.931568569324174
Space complexity: 2^13.287712379549449
Read-write complexity: 2^15.872674880270605
```

The performance gain is more than this. In OMEinsum, binary contractions can be accelerated by BLAS library.

```julia
julia> using BenchmarkTools

julia> @btime code(randn(100, 100), randn(100, 100), randn(100, 100)); # naive
  86.418 ms (36 allocations: 385.48 KiB)

julia> @btime nested_code(randn(100, 100), randn(100, 100), randn(100, 100));
  133.167 μs (157 allocations: 486.06 KiB)
```

// #raw(read("examples/basic/basic.jl"), lang: "julia", block: true)

#exampleblock([
*Example A: Star contraction*

The star contraction of three matrices $A, B, C in bb(R)^(n times n)$ is defined as
$
O_(i j k) = sum_a A_(i a) B_(a j) C_(a k)
$
Its diagrammatic representation is:

#figure(canvas({
  import draw: *
  let s(it) = text(10pt, it)
  tensor((-1.0, 0), "A", s[$A$])
  tensor((1.0, 0), "B", s[$A$])
  tensor((0, 1.0), "C", s[$B$])
  labeledge("A", (rel: (-1.2, 0)), s[$i$])
  labeledge("B", (rel: (1.2, 0)), s[$j$])
  labeledge("C", (rel: (0, 1.2)), s[$k$])
  labelnode((0, 0), s[$a$], name: "a")
  line("a", "A")
  line("a", "B")
  line("a", "C")
}))

The einsum notation for the star contraction is `ai,aj,ak->ijk`. Its time complexity is $O(n^4)$ in big O notation.

*Example B: Kronecker product*

The kronecker product of two matrices $A, B in bb(R)^(n times n)$ is defined as
$
C_(i j k l) = A_(i j) B_(k l)
$
Its diagrammatic representation is:

#figure(canvas({
  import draw: *
  tensor((1, 1), "A", "A")
  tensor((3, 1), "B", "B")
  labeledge("A", (rel: (0, -1.5)), "j")
  labeledge("A", (rel: (0, 1.5)), "i")
  labeledge("B", (rel: (0, -1.5)), "l")
  labeledge("B", (rel: (0, 1.5)), "k")
}))

The einsum notation for the kronecker product is `ij,kl->ijkl`. Its time complexity is $O(n^4)$.
])

== Contraction order optimization and slicing

The time complexity to contract a tensor network is determined by the chosen contraction order, which is represented as a binary tree.
The leaves of the tree are the input tensors, and the root is the output tensor.
For example, the contraction `ein"ab,bc,cd->ad"` can be represented as the following two binary trees:

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
}))

The left one is superior to the right one. The right one computes a kronecker product first and creates a large intermediate tensor of size $O(n^4)$, while the left one has a time complexity $O(n^3)$ and space complexity $O(n^2)$.

Finding the optimal contraction order—the one with minimal complexity—is an NP-complete problem@Markov2008.
However, in practice, a close-to-optimal contraction order is usually sufficient and can be found efficiently using heuristic optimization methods.
Over the past decade, researchers have developed various optimization techniques, including both exact and heuristic approaches.
Some of these heuristic methods have proven highly scalable, capable of handling networks containing more than $10^4$ tensors@Gray2021,@Roa2024.

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
}))

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
\rev{The optimal choice of weights depends on the specific device and tensor contraction algorithm. One can freely tune the weights to achieve a best performance for their specific problem.}
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

== Data Compression
Let us define a complex matrix $A in CC^(m times n)$, and let its singular value decomposition be
$
A = U S V^dagger
$
where $U$ and $V$ are unitary matrices and $S$ is a diagonal matrix with non-negative real numbers on the diagonal.

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

=== Tucker decomposition

The Tucker decomposition of a rank-4 tensor $T$ can be represented as
$
T_(i j k l) = sum_(a,b,c,d) U_1^(i a) U_2^(j b) U_3^(k c) U_4^(l d) X_(a b c d)
$
where $U_1, U_2, U_3, U_4$ are unitary matrices and $X$ is a rank-4 tensor.

#align(center, text(10pt, canvas({
  import draw: *
  tensor((-5.5, 0), "T", [$T$])
  labeledge("T", (rel: (0, 1.2)), [$i$])
  labeledge("T", (rel: (-1.2, 0)), [$j$])
  labeledge("T", (rel: (0, -1.2)), [$k$])
  labeledge("T", (rel: (1.2, 0)), [$l$])

  content((-3.5, 0), [$=$])


  tensor((-1.5, 0), "A", [$U_1$])
  tensor((1.5, 0), "B", [$U_2$])
  tensor((0, -1.5), "C", [$U_3$])
  tensor((0, 1.5), "D", [$U_4$])
  tensor((0, 0), "X", [$X$])
  labeledge("D", (rel: (0, 1.2)), [$i$])
  labeledge("A", (rel: (-1.2, 0)), [$j$])
  labeledge("C", (rel: (0, -1.2)), [$k$])
  labeledge("B", (rel: (1.2, 0)), [$l$])
  labeledge("X", "A", [$b$])
  labeledge("X", "B", [$d$])
  labeledge("X", "C", [$c$])
  labeledge("X", "D", [$a$])
})))


== Tensor train decomposition

A tensor train is a tensor network with the following data structure.
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

It represents a high dimensional tensor with a compact 1-dimensional tensor network. Researchers like this 1D representation due to the following nice properties:
1. The inner product is easy to compute.
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
}))

2. Has polynomial time compression algorithm, which could be achieved through iterative application of the following two processes on different bonds:
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

}))
  The factorization is usually done by first reshaping the tensor into a matrix and then applying singular value decomposition. By eliminating small singular values, the bond dimension can be reduced.
  Easy to compress is a feature of all loopless tensor networks, including the tensor train. In the following example, we show a uniform state can be represented as a tensor train of rank 1.

```julia
julia> uniform_state(n) = fill(sqrt(1/2^n), 2^n);

julia> L, M, R = fill(sqrt(0.5), 2, 1), fill(sqrt(0.5), 1, 2, 1), fill(sqrt(0.5), 1, 2);

julia> @assert ein"ia,ajb,bkc,cld,dm->ijklm"(L, M, M, M, R) ≈ uniform_state(5)
```

#raw(read("../examples/basic/mps.jl"), lang: "julia", block: true)


== Automatic Differentiation

_Back propagation_ is one of the fundamental techniques in machine learning for computing gradients of a loss function $cal(L)$ with respect to model parameters. The core concept is the _backward rule_, which propagates adjoints through the computational graph. The adjoint of a variable $a$ is defined as $overline(a) = frac(partial cal(L), partial a)$, representing how the loss changes with respect to that variable.

For a function $f: bb(R)^n arrow.r bb(R)^m$ with input $x$ and known adjoint of the output $overline(y)$, the backward rule computes the adjoint of the input as:
$ overline(x) = frac(partial f, partial x)^T overline(y) $
This process efficiently propagates gradient information backward through the network, enabling optimization of complex models.

For matrix multiplication $C = A B$, the backward rule is given by:
$ overline(A) = overline(C) B^T, quad overline(B) = A^T overline(C) $
This rule plays a crucial role in machine learning optimization. The backward computation is remarkably efficient—it requires only matrix multiplications with time complexity $O(n^3)$, despite the fact that the full Jacobian matrix would have $O(n^4)$ elements. This computational efficiency is fundamental to the scalability of gradient-based optimization in many applications.
Tensor network contraction generalizes matrix multiplication and inherits this computational efficiency. We can formally represent a tensor network as a triple $(Lambda, cal(T), sigma_Y)$, where:
$
  Y = "contract"(Lambda, cal(T), sigma_Y)
$
Here, $Lambda$ denotes the set of all tensor indices, $cal(T)$ represents the collection of tensors, and $sigma_Y subset Lambda$ specifies the indices of the output tensor.

Given the output adjoint $overline(Y)$, the backward rule for computing the adjoint of an input tensor $X$ is:
$
overline(X) = "contract"(Lambda, (cal(T) \\ {X}) union {overline(Y)}, sigma_X)
$
where $cal(T) \\ {X}$ denotes the tensor set with input tensor $X$ removed, and $sigma_X$ represents the indices of tensor $X$.

A naive implementation of this backward rule would incur computational overhead linear in the number of input tensors, as it requires contracting the network separately for each tensor's gradient. However, this inefficiency is avoided in practice through the use of binary contraction trees. With proper optimization, the overhead reduces to a constant factor, making gradient computation approximately twice as expensive as the forward pass—a remarkable efficiency considering that each binary contraction has two inputs and each backward computation maintains the same complexity as the forward pass.

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

}))
*Quiz*: If the forward contraction specified with a binary contraction order: `Y = ein"(aij,jk),ki->a"(A, B, C)`, how are gradients computed in the backward propagation?
])

In `OMEinsum`, the backward rule of einsum has already been ported to `ChainRulesCore`, which can be directly used in `Zygote` and `Flux`.
It also implements a 

```julia
julia> gradients = cost_and_gradient(optcode, (tensors...,));
```

The returned `gradients` is a vector of arrays, each of which is an adjoint of an input tensor.

= Quantum Circuit Simulation
- initial state, product state
- single-qubit gate, two-qubit gate, diagonal gate and CNOT gates.
- expectation values

Quantum circuits provide a natural setting for tensor network representations, where quantum gates are represented as tensors and quantum states as vectors. This mapping allows us to efficiently simulate quantum circuits using tensor network contraction algorithms.

== Basic quantum circuit simulation

In quantum computing, a quantum state initialized to $|0 angle.r^(times.circle n)$ can be represented as a direct product of $n$ vectors:
#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  let n = 2
  for j in range(n){
    tensor((0, -j), "init", s[$|0 angle.r$])
    line("init", (1, -j))
  }
  content((0, -2), s[$dots.v$])
  tensor((0, -3), "init", s[$|0 angle.r$])
  line("init", (1, -3))
}))
where $|0 angle.r = mat(1; 0)$. A single-qubit gate $U$ can be represented as a rank-2 tensor. For example, if we want to apply a Hadamard gate $H$ to the first qubit, we can represent it as:

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "init", s[$|0 angle.r$])
  tensor((1, 0.0), "H", s[$H$])
  line("init", "H")
  line("H", (2, 0))

  tensor((0, -1), "init", s[$|0 angle.r$])
  line("init", (1, -1))

  content((0, -2), s[$dots.v$])
  tensor((0, -3), "init", s[$|0 angle.r$])
  line("init", (1, -3))
}))

It can be generalized to multiple qubits. Some quantum gates have more detailed structures, such as the CNOT gate:
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
}))
where we ignored the extra constant factor $sqrt(2)$ on the right side.

=== Useful rules

#figure(canvas({
  import draw: *
  let s(it) = text(11pt, it)
  tensor((0, 0), "init", s[$|0 angle.r$])
  tensor((1, 0), "H", s[$H$])
  line("init", "H")
  line("H", (rel: (1, 0)))
  content((3, 0), "=")
  tensor((4, 0), "id", s[$"id"$])
  line("id", (rel: (1, 0)))
}))

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
}))

#figure(canvas({
  import draw: *
  let radius = 0.3
  let dx = 1.5
  let dy = 0.8
  line((0, dy), (dx, dy), name: "a")
  line((0, -dy), (dx, -dy), name: "b")
  circle("a.mid", radius: 0.1, fill:black)
  circle("b.mid", radius: 0.1, fill:black)
  line("a.mid", "b.mid")
  content((2.3, 0), "=")
  let W = 3
  line((W, dy), (W + dx, dy), name: "c")
  line((W, -dy), (W + dx, -dy), name: "d")
  tensor((W + dx/2, 0), "H1", [$H$])
  line("c.mid", "H1")
  line("d.mid", "H1")
}))


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
}))

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
}))

Question: How to compute $angle.l "GHZ"|O|"GHZ" angle.r$ and what is the complexity?
])

== Practice: Hadamard test

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

}))

=== Expectation values

*Yao implementation*:

#raw(read("../examples/basic/hadamardtest.jl"), lang: "julia", block: true)

This implementation demonstrates how the Hadamard test can be used to estimate expectation values of unitary operators, which is fundamental for variational quantum algorithms and quantum machine learning.

=== Implementation example

Here's a Julia implementation using `Yao` for the quantum circuit simulation:

This example demonstrates how to prepare a GHZ state using both quill for quantum circuit visualization and Yao for quantum circuit simulation. The resulting state exhibits perfect three-qubit entanglement, with equal probabilities for |000⟩ and |111⟩ states and zero probability for all other computational basis states.


== Quantum channel simulation

== Pauli basis and depolarizing error

= Quantum Error Correction

== Probabilistic modeling
=== Hidden Markov model

A Hidden Markov Model (HMM)@Bishop2006 is a simple probabilistic graphical model that describes a Markov process with unobserved (hidden) states. The model consists of:

- A sequence of hidden states $z_t$ following a Markov chain with transition probability $P(z_(t+1)|z_t)$
- A sequence of observations $x_t$ that depend only on the current hidden state through emission probability $P(x_t|z_t)$

The joint probability of a sequence of $T+1$ hidden states and $T$ observations can be written as:

$
P(bold(z), bold(x)) = P(z_0) product_(t=1)^T P(z_(t)|z_(t-1))P(x_t|z_t).
$
Note that the conditional probability $P(z_(t)|z_(t-1))$ can be represented as a tensor with two indices. The joint probability $P(bold(z), bold(x))$ can be represented as a tensor network diagram:

#let hmm(n) = {
  import draw: *
  let s(it) = text(11pt, it)
  
  // Draw transition matrices
  let dx = 2.0
  tensor((0, 0), "A0", []) 
  for i in range(1, n){
    tensor((dx*i, 0), "A" + str(i), []) 
  }
  for i in range(n - 1){
   labeledge("A" + str(i), "A" + str(i+1), s[$z_#(i+1)$], name: "z" + str(i))
  }
  labeledge("A" + str(n - 1), (rel: (1.6, 0), to:"A" + str(n - 1)), s[$z_#(n)$], name: "z" + str(n - 1))

  for i in range(n){
    tensor((rel: (0, -1), to: "z" + str(i)), "B" + str(i), [])
    line("z" + str(i), "B" + str(i))
    labeledge("B" + str(i), (rel: (0, -1.2)), s[$x_#(i+1)$])
  }
}

#figure(canvas({
  import draw: *
  hmm(5)
}),
caption: [The tensor network representation of a Hidden Markov Model (HMM) with observed variables $x_1, x_2, dots, x_T$ and hidden states $z_0, z_1, dots, z_T$. The circles are conditional probabilities $P(z_t|z_(t-1))$ and $P(x_t|z_t)$.]
)

=== Likelihood
The likelihood of the observed sequence:
$
P(bold(x)|theta) = sum_(bold(z)) P(bold(x), bold(z)|theta)
$

#figure(canvas({
  import draw: *
  hmm(5)
  let s(it) = text(11pt, it)
  for i in range(5){
    tensor((rel: (0, -1.6), to: "B" + str(i)), "p" + str(i), s[$x_#(i+1)$])
  }
  tensor((rel: (2, 0), to: "A4"), "e", [id])
}))
where nodes with $x_t$ are observed variables, which are represented as projection tensors.

=== Decoding
This is the _decoding problem_ of HMM: Given a sequence of observations $bold(x) = (x_1, x_2, ..., x_T)$, how to find the most likely sequence of hidden states $bold(z)$? The equivalent mathematical formulation is:
$
  arg max_(bold(z)) P(z_0) product_(t=1)^T P(z_(t)|z_(t-1))P(overshell(x)_t|z_t),
$ <eq:decoding>
where $overshell(x)_t$ denotes an observed variable $x_t$ with a fixed value. It is equivalent to contracting the following tensor network:
$
  cases(Lambda = {z_0, z_1, dots, z_T},
  cal(T) = {P(z_0), P(z_1|z_0), dots, P(z_T|z_(T-1)), P(overshell(x)_1|z_1), P(overshell(x)_2|z_2), dots, P(overshell(x)_T|z_T)},
  V_0 = emptyset
  )
$ <eq:decoding-tensor>
Since $overshell(x)_1, overshell(x)_2, dots, overshell(x)_T$ are fixed and not involved in the contraction, $P(overshell(x)_t|z_t)$ is a vector indexed by $z_t$ rather than a matrix.
To solve @eq:decoding, we first convert @eq:decoding-tensor into a tropical tensor network $(Lambda, {log(t) | t in cal(T)}, V_0)$, where $log(t)$ is obtained by taking the logarithm of each element in $t$. Then the contraction of this tropical tensor network is equivalent to
$
  arg max_(bold(z)) sum_(bold(z)) log P(z_0) + sum_(t=1)^T log P(z_t|z_(t-1)) + sum_(t=1)^T log P(overshell(x)_t|z_t),
$
which solves the decoding problem.
Since this tensor network has a chain structure, its contraction is computationally efficient.
This algorithm is equivalent to the Viterbi algorithm.

== Tanner graph
=== Surface code

== Practice: Circuit level decoding

#bibliography("refs.bib")
