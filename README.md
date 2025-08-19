# Circuit Simulation and Quantum Error Correction with Tensor Networks

[![Julia](https://img.shields.io/badge/Julia-1.10+-9558B2?style=flat&logo=julia&logoColor=white)](https://julialang.org/)
[![Lecture note](https://img.shields.io/badge/Lecture_Note-Work_in_Progress-blue.svg)](notes/lecturenote.pdf)

This tutorial explores the intersection of tensor networks and quantum computing. It is originally designed for a quantum AI summer school.

## 📖 Overview

- **Lecture note** ([PDF](notes/lecturenote.pdf)) on tensor networks and relevant topics such as tensor network contraction order optimization, data compression, autodiff, quantum circuit simulation, quantum channel simulation, quantum error correction.
- **Pluto notebooks** for shallow circuit simulation ([PDF](examples/simulation/simulation.pdf)) and quantum error correction ([PDF](examples/qec/qec.pdf)). To play with these notebooks, please check the following instructions.

## 🚀 Run Pluto notebooks

### 0. Prerequisites

- A proper terminal, with `make` command available.
- **Julia**: Version 1.10 or higher ([Installation Guide](https://scfp.jinguo-group.science/chap1-julia/julia-setup.html))

### 1. Clone and Setup

```bash
git clone https://github.com/GiggleLiu/tutorial-tensornetwork.git
cd tutorial-tensornetwork
```

### 2. Install Dependencies

```bash
make init  # or `make update`
```

This will automatically install the project dependencies, including
- [OMEinsum.jl](https://github.com/under-Peter/OMEinsum.jl) for tensor network contraction
- [Yao.jl](https://github.com/QuantumBFS/Yao.jl) for quantum computing
- [TensorQEC.jl](https://github.com/nzy1997/TensorQEC.jl) for error correction
- [Pluto.jl](https://github.com/fonsp/Pluto.jl) for interactive notebooks

### 3. Launch Pluto Notebooks

For **shallow circuit simulation** ([PDF preview](examples/simulation/simulation.pdf)):
```bash
case=simulation make pluto
```

For **quantum error correction** ([PDF preview](examples/qec/qec.pdf)):
```bash
case=qec make pluto
```

## 📖 Lecture Notes

The comprehensive lecture notes are available in [PDF](notes/lecturenote.pdf) format. To compile from source code, please install [Typst](https://typst.app/) first, and then run:

```bash
# Compile the notes
make pdf
```

## 📧 Contact

For questions or discussions about this tutorial, please open an issue in this repository.

---

*Happy tensor networking! 🎯🔬*