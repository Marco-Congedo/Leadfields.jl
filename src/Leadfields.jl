module Leadfields

using MAT
using GeometryBasics
using FileIO
using Statistics
using PrecompileSignatures: @precompile_signatures

# Colors (same as Gedai.jl)
const font1color = "\x1b[38;5;111m" # metal blue
const font2color = "\x1b[38;5;87m" # cyan
const font3color = "\x1b[38;5;71m" # EEGPlot green
const fontgrey = "\x1b[38;5;249m"
const fontwhite = "\x1b[37m"

# Brainstorm-generated head models supported
const leadfield_1210_path = joinpath(abspath(@__DIR__, ".."), "HeadModels", "headmodel_1210.mat")
const leadfield_2503_path = joinpath(abspath(@__DIR__, ".."), "HeadModels", "headmodel_2503.mat")
const leadfield_5002_path = joinpath(abspath(@__DIR__, ".."), "HeadModels", "headmodel_5002.mat")
# Brainstorm-generated electrodes supported
const sensors_path = joinpath(abspath(@__DIR__, ".."), "Sensors", "channel_ASA_10-05_343.mat")
# Brainstorm-generated Meshes supported
const cortex_mesh_path_2503 = joinpath(abspath(@__DIR__, ".."), "Meshes", "tess_cortex_pial_low_2503.mat")
const cortex_mesh_path_5002 = joinpath(abspath(@__DIR__, ".."), "Meshes", "tess_cortex_pial_low_5002.mat")
# Supported cortex .stl files
const cortex_stl_path_2503 = joinpath(abspath(@__DIR__, ".."), "Meshes", "cortex_2503.stl")
const cortex_stl_path_5002 = joinpath(abspath(@__DIR__, ".."), "Meshes", "cortex_5002.stl")


export  leadfield,
        gen_cortex_stl,
        # Those below are exported but not documented in the README: only for advanced use
        #leadfield_1210_,
        leadfield_,
        load_cortex_stl

include("leadfield.jl")
include("stl.jl")

@precompile_signatures(Leadfields)

end