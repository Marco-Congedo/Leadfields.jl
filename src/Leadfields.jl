module Leadfields

using MAT
using PrecompileSignatures: @precompile_signatures

# Colors (same as Gedai.jl)
const font1color = "\x1b[38;5;111m" # metal blue
const font2color = "\x1b[38;5;87m" # cyan
const font3color = "\x1b[38;5;71m" # EEGPlot green
const fontgrey = "\x1b[38;5;249m"
const fontwhite = "\x1b[37m"

# for the moment being, only one leadfield file is supported
const leadfield_path = joinpath(abspath(@__DIR__, ".."), "leadfields", "fsavLEADFIELD_4_GEDAI.mat")

export head_model

include("leadfield.jl")

@precompile_signatures(Leadfields)

end