Objectives:

- Can use tensor network to represent quantum states, quantum circuits and quantum channels.
- Can use tensor network to represent quantum error correction codes.
- Can use OMEinsum to contract a tensor network.

= Part 1

== Definition (5min)

- Definition: multi-linear algebra
  - Linear: $f(alpha x + beta y) = alpha f(x) + beta f(y)$
  - Multilinear: $f$ is linear in multiple arguments
  - e.g.1 product: $f(x, y, z) = x y z$
  - e.g.2 trace multiplication of a sequence of matrices: $f(A, B, C) = tr(A B C)$
  - e.g.3 kronecker product: $f(X, Y, Z) = X times.circle Y times.circle Z$
  - e.g.4 Not multilinear: $f(x + y + z) = x + y + z$

== Why tensor network? (4min)
- Lei Wang: "Linear algebra for 21st century"
  - Machine learning (arXiv:2305.06058)
  - Quantum physics (arXiv:1306.2164)
  - Combinatorial optimization (arXiv:2008.06888)
  - Probabilistic modeling (arXiv:2405.14060)
  - Quantum computation

== Diagramatic langauge (10min)

- variables, or index, or leg
- vector, matrix and tensor
- contraction, matrix multiplication as an example
  - nested loops
  - open indices
  - contraction complexity (naively)
- Examples
  - e.g.1 trace
  - e.g.2 summation
  - e.g.3 multiplying a seqence of matrices
  - e.g.4 kronecker product
  - e.g.5 trace permutation
  - e.g.6 proving trace permutation
  - e.g.7 SVD and data compression
  - e.g.8 Tucker decomposition and CP decomposition
  - e.g.9 matrix product state (MPS, tensor train), GHZ state
  - e.g.10 tree tensor network (TTN)
  - e.g.11 projected entangled pair of states (PEPS), maybe the toric code state?

== Quantum circuit and tensor networks (10min)
- Quantum states: zero state, GHZ state.
- Gates: Hadamard gate, CZ gate and CNOT gate, etc.
- Example 1: Bell state preparation, extend to GHZ state.
- Example 2: Quantum teleportation

= Part 2
== Noisy simulation (10min)
- Density matrix
- Quantum channel
  - Kraus representation and Superoperator
  - e.g.1 Depolarizing channel
  - e.g.2 Thermal relaxation channel
- Efficient simulation of quantum channels (arXiv:1810.03176)

== Quantum error correction (10min)
- QEC basics
- Surface code and Tanner graph
- Probability graph
- QEC with tensor network (Ref needed)

== Einsum notation (2min)

- definition
- the above example

== Tensor network contraction (10min)
- complexity, big-O notation
- contracting a tensor network is \#P-hard
- examples
  - contract an MPS
  - contract a TTN
  - contract a PEPS on square lattice
- Treewidth (5min)
  - definition
  - the treewidth of low dimensional topology (arXiv:quant-ph/0511069)
  - the tree SA algorithm (arXiv:2108.05665).
- Slicing and compression
  - data compression (arXiv:1403.2048)
  - slicing

== Optinal
- Autodiff (3min)
- Complex numbers, a tensor network perspective(3min)

= Part 3
== Hands on 1: OMEinsum
== Hands on 2: YaoToEinsum
== Hands on 3: TensorQEC