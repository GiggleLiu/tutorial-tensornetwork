= Flow

== Definition

- Definition: multi-linear algebra
  - Linear: $f(alpha x + beta y) = alpha f(x) + beta f(y)$
  - Multilinear: having multiple linear arguments
  - e.g.1 product: $f(x, y, z) = x y z$
  - e.g.2 trace multiplication of a sequence of matrices: $f(A, B, C) = tr(A B C)$
  - e.g.3 kronecker product: $f(X, Y, Z) = X times.circle Y times.circle Z$
  - e.g.4 Not multilinear: $f(x + y + z) = x + y + z$

== Why tensor network?
- Lei Wang: "Linear algebra for 21st century"
  - Machine learning
    - Compressing Neural Network by Tensor Network with Exponentially Fewer Variational Parameters, arXiv:2305.06058 (Yong Qing et al.)
  - Quantum computation
    - Simulating Quantum Computation by Contracting Tensor Networks, SIAM Journal on Computing, 2008 (Markov and Shi)
  - Quantum physics
    - The Density-Matrix Renormalization Group in the Age of Matrix Product States, (Schollwock, 2011)
  - Combinatorial optimization
    - Fast counting with tensor networks, Physical Review Letters, 2018 (Kourtis et al.)
    - Tropical Tensor Network for Ground States of Spin Glasses, Physical Review Letters, 2021 (Liu et al.)
  - Probabilistic modeling
    - Probabilistic Inference in the Era of Tensor Networks and Differential Programming, Physical Review Research, 2024 (Roa et al.)

== Diagramatic langauge

- variables, or index, or leg
- vector, matrix and tensor
- contraction
- e.g.1 trace
- e.g.2 summation
- e.g.3 multiplying a seqence of matrices
- e.g.4 kronecker product
- e.g.5 trace permutation
- e.g.6 star contraction
- e.g.7 proving trace permutation
- e.g.8 SVD and data compression
- e.g.9 Tucker decomposition and CP decomposition
- e.g.10 matrix product state (MPS, tensor train)
- e.g.11 tree tensor network (TTN)
- e.g.12 projected entangled pair of states (PEPS)

== Einsum notation

- definition
- the above example

== Tensor network contraction
- complexity, big-O notation
- contracting a tensor network is \#P-hard
- examples
  - contract an MPS
  - contract a TTN
  - contract a PEPS on square lattice

== Quantum circuit and tensor network contraction

== Treewidth
- definition
- the treewidth of low dimensional topology
- the tree SA algorithm.

== Hands on