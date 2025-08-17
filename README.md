# Circuit Simulation and Quantum Error Correction with Tensor Networks

[![Julia](https://img.shields.io/badge/Julia-1.10+-9558B2?style=flat&logo=julia&logoColor=white)](https://julialang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A comprehensive tutorial on quantum circuit simulation and quantum error correction using tensor networks, demonstrating efficient approaches for simulating quantum circuits through tensor contraction algorithms.

## 📖 Overview

This tutorial explores the intersection of tensor networks and quantum computing, covering:

- **Tensor Networks**: Fundamentals of tensor operations and Einstein summation notation
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

This will automatically:
- Install the main project dependencies ([OMEinsum.jl](https://github.com/under-Peter/OMEinsum.jl), IJulia.jl)
- Set up all example subdirectories with their specific dependencies
- Install [Yao.jl](https://github.com/QuantumBFS/Yao.jl) for quantum computing and [TensorQEC.jl](https://github.com/nzy1997/TensorQEC.jl) for error correction

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

The comprehensive lecture notes are available in Typst format. To compile:

```bash
# Install Typst (if not already installed)
# Visit: https://typst.app/

# Compile the notes
typst compile notes/tnet.typ notes/tnet.pdf
```

**Alternative**: Preview with VSCode using the [Typst extension](https://github.com/CodingThrust/Templates/tree/main/typst).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

For questions or discussions about this tutorial, please open an issue in this repository.

---

*Happy tensor networking! 🎯🔬*