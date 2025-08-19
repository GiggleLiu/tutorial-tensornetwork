# Circuit Simulation and Quantum Error Correction with Tensor Networks

[![Julia](https://img.shields.io/badge/Julia-1.10+-9558B2?style=flat&logo=julia&logoColor=white)](https://julialang.org/)
![Static Badge](https://img.shields.io/badge/Status-Work_in_Progress-blue.svg)

A comprehensive tutorial on quantum circuit simulation and quantum error correction using tensor networks.

## 📖 Overview

This tutorial explores the intersection of tensor networks and quantum computing, covering:

- **Tensor Networks and its Contraction Order Optimization**: Fundamentals of tensor operations and Einstein summation notation
- **Quantum Circuit Simulation**: Efficient simulation of quantum circuits using tensor contraction
- **Quantum Error Correction**: Tensor network approaches to quantum error correction codes

## 📋 Prerequisites

- **Julia**: Version 1.10 or higher ([Installation Guide](https://scfp.jinguo-group.science/chap1-julia/julia-setup.html))
- **Basic Knowledge**: 
  - Linear algebra fundamentals
  - Basic quantum computing concepts (qubits, gates, circuits)
  - Familiarity with Julia programming (recommended)

## 🚀 Quick Start

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

For **shallow circuit simulation**:
```bash
case=simulation make pluto
```

For **quantum error correction**:
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