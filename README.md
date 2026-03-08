
![header](Documents/header.png)

---

> [!TIP] 
> 🦅
> This package is part of the [Eegle.jl](https://github.com/Marco-Congedo/Eegle.jl) ecosystem for EEG data analysis and classification.

---

# Leadfields

This packege allow access to a leadfield computed by the [OpenMEEG](https://openmeeg.github.io/) software in [julia](https://julialang.org/) for
1210 voxels.

The leadfield can be used for computing vector-type EEG inverse solutions using [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl) and for advanced use of the [Gedai](https://github.com/Marco-Congedo/Gedai) denoising algorithm.

The specifications of the leadfield can be found in the "fsavLEADFIELD_4_GEDAI.pdf" file in the "leadfields" directory of this repository.

![separator](Documents/separator.png)

## 🧭 Index

- 📦 [Installation](#-installation)
- 🔣 [Problem Statement, Notation and Nomenclature](#-problem-statement-notation-and-nomenclature)
- 🔌 [API](#-api)
- 💡 [Examples](#-examples)
- ✍️ [About the Author](#️-about-the-author)
- 🌱 [Contribute](#-contribute)

![separator](Documents/separator.png)

## 📦 Installation

*julia* version 1.10+ is required.

Execute the following command in julia's REPL:

```julia
using Pkg
Pkg.add("https://github.com/Marco-Congedo/Leadfields.jl")
```

To test the package:
```julia
Pkg.test("Leadfields")
```

[▲ index](#-index)

![separator](Documents/separator.png)

## 🔣 Problem Statement, Notation and Nomenclature

See [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl) first.

This package allows to access:
- The leadfield matrix 𝐊 ∈ ℝⁿ×³ᵖ, where n is the number of electrodes and p is the number of voxels.
- The electrode labels
- the electrode locations in 3D cartesian coordinates
- the voxel locations in 3D cartesian coordinates.

The voxel locations is always fixed. The leadfield can be computed for any collection of electrodes and with any reference.

> [!WARNING] 
> Each label in the sought collection of electrodes match one of the strings listed in the [sensors343.txt](https://github.com/Marco-Congedo/Gedai/tree/master/Documents/sensors343.txt) file.


[▲ index](#-index)

![separator](Documents/separator.png)

## 🔌 API

The package exports only one function, but a very general one:

```julia
function leadfield(labels=nothing; reference=0.0)
```

**argument**

- `labels: a vector of electrode labels (optional)

**keyword argument**
- `reference`: a reference electrode label (optional) or a correction factor for computing the common average reference (CAR).

**Return** 

the 4-tuple comprising:
- a) the leadfield matrix: n(electrodes) x [1210(voxels) x 3(orientations)] 
- b) electrode labels: a n-vector of strings
- c) electrode locations: a n-vector of 3-vectors holding each the location in 3D cartesian coordinates
- d) voxel locations: a 1210-vector of 3-vectors holding each the location in 3D cartesian coordinates.

In the output tuple, d) the (voxel locations) is always the same.

By default (`labels`=nothing and `reference =0.0`) Ne = 343, i.e., this function computes the leadfield matrix in the common average reference (rank-deficient, with rank n-1) at all available electrodes and returns the associated electrode labels and locations.

If `labels` is a vector of strings, n = length(labels) and (a, b, c) contains only the elements corresponding to the provided labels.

Furthermore,

1) If `reference` is equal to an electrode label (a string), the leadfield matrix is re-referenced to that electrode.
- case 1.1: `labels` is not provided:
    n = 343-1, since the elements of (a, b, c) corresponding to that electrode are removed.
- case 1.2: `labels` is provided:
    - 1.2.a: `reference` is in labels:
        n = length(labels)-1, since the elements of (a, b, c) corresponding to that electrode are removed.
    - 1.2.b: `reference` is not in labels:
        n = length(labels)

2) If `reference` is a real value (default 0.0)
the leadfield matrix is re-referenced to the (common average reference + `reference`), thus if `reference` = 0.0, it is referenced to the (rank-deficient) common average reference, and if `reference` = 1.0, it referenced to the full-rank pseudo common average reference.
See the [Eegle.car!](https://marco-congedo.github.io/Eegle.jl/stable/Processing/#Eegle.Processing.car!) function for explanations.

[▲ index](#-index)

![separator](Documents/separator.png)

## 💡 Examples

> [!WARNING] 
> If the leadfield is needed to compute an inverse solution in by package [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl), `labels` will hold the electrode labels for your data and `reference` must be 0.0 (default).


** Example for computing inverse solutions **

```julia
using Leadfields
labels = ["FP1", "FP2", "C3", "C4"]
K, ename, eloc, gridloc = leadfield(labels)
```

- `K` is a 4×3630 leadfield matrix referenced to the (rank-deficient) CAR, i.e., the usual CAR.
- `ename` is equal to `labels`
- `eloc` is a vector holding 4 vectors with the 3D electrode cartesian coordinates
- `gridloc` is a vector holding 1210 vectors with the 3D voxels cartesian coordinates

** Example for use with GEDAI denoising **

We will compute the leadfield matrix for the

# left Mastoid
file = selectDB(:MI)[16].files[1]
o = readNY(file)
K, ename, eloc, gridloc = leadfield(o.sensors; reference = "M1")
K, ename, eloc, gridloc = leadfield(reference = "M1")

# example number of electrodes, data samples, voxels
n, s, p = 20, 200, 2000

# example random leadfield in common average reference
K = ℌ(n)*randn(n, 3p)

# example random EEG data
X=randn(s, n)

# random weights for weighted minimum norm solutions
weights=abs.(randn(3p))

# - - -

# sample covariance matrix of the random EEG data
C=Symmetric((1/s)*(X'*X))

Tmn1 = minNorm(K, 1)    # unweighted model-driven min norm with α=1
Tmn2 = minNorm(K, 10)   # unweighted model-driven min norm with α=10
Tmn3 = minNorm(K, 1; W=weights) # weighted model-driven min norm with α=1
Tmn4 = minNorm(K, 1, C) # data-driven min norm with α=1

TsLor1 = sLORETA(K, 1)     # model-driven sLORETA with α=1
TsLor2 = sLORETA(K, 10)    # model-driven sLORETA with α=10
TsLor3 = sLORETA(K, 1, C)  # data-driven sLORETA with α=1

TeLor1 = eLORETA(K, 1)     # model-driven eLORETA with α=1
TeLor2 = eLORETA(K, 10)    # model-driven eLORETA with α=10
TeLor3 = eLORETA(K, 1, C)  # data-driven eLORETA with α=1

# test the transfer matrix you creat
psfLocError(K, TeLor1) == 0 ? println("OK") : println("Error")
```

[▲ index](#-index)

![separator](Documents/separator.png)

## ✍️ About the Author

[Marco Congedo](https://github.com/Marco-Congedo) and [Tomas Ros](https://github.com/neurotuning-personal)

[▲ index](#-index)

![separator](Documents/separator.png)

## 🌱 Contribute

Please contact the author if you are interested in contributing.

[▲ index](#-index)


