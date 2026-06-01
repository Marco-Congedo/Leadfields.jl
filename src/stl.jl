# Generate and save a STL file for plotting the cortex in 3D given the default brainstorm surface .mat file
# for the given number of `voxels` and `savepath`, the full path of the file to save the .stl file 
# The generated .stl file is to be used in makie.jl for plotting the cortex in 2D or 3D.
function gen_cortex_stl(savepath::String; voxels::Int = 2503)
    if voxels===2503
        surf = matread(cortex_mesh_path_2503) # "tess_cortex_pial_low_2503.mat"
    elseif voxels===5002
        surf = matread(cortex_mesh_path_5002) # "tess_cortex_pial_low_5002.mat"
    end
    
    # println(keys(surf)) # ["VertNormals", "Comment", "Vertices", "Faces", "VertConn", "Curvature", "History", "Reg", "SulciMap", "Color", "tess2mri_interp", "iAtlas", "Atlas"]
    haskey(surf, "Vertices")|| throw(ArgumentError("Vertices keys not found in surfacefile"))
    haskey(surf, "Faces")|| throw(ArgumentError("Faces keys not found in surfacefile"))

    scale_factor = 1000f0   # adjust the size of the stl model
    vertices_raw = Float32.(surf["Vertices"])
    faces_mat    = Int.(surf["Faces"])        
    centroid = mean(vertices_raw, dims=1) 
    vertices_centered = vertices_raw .- centroid  # model centered in (0,0,0)
    vertices_scaled = vertices_centered .* scale_factor
    pts = [Point3f(vertices_scaled[i,1], vertices_scaled[i,2], vertices_scaled[i,3]) for i in 1:size(vertices_scaled,1)]
    tris = [TriangleFace{Int}(faces_mat[i,1], faces_mat[i,2], faces_mat[i,3]) for i in 1:size(faces_mat,1)]
    cortex_mesh = GeometryBasics.Mesh(pts, tris) # creation of the mesh
    #filename=joinpath(@__DIR__, "cortex.stl") 
    save(savepath, cortex_mesh) # creation of the stl file
    println(font2color, ".stl file saved.", fontwhite)
end

# Load the cortex form a STL file and return it.
# If `filepath` is not provided or it is an empty string (default), the default Meshes/cortex_2503.stl file is loaded,
# otherwise the provided .stl file is used.
# The cortex.stl default has been produced by the above `gen_cortex_stl` function 
# using the "Meshes\tess_cortex_pial_low_XXXX.mat file".
function load_cortex_stl(filepath::String="")
    isempty(filepath) || isfile(filepath) || throw(ArgumentError("The provided `filepath` argument is not a valid file path"))
    cortex = isempty(filepath) ? load(cortex_stl_path_2503) : load(filepath)
    return cortex
end

# example usage
# gen_cortex_stl(joinpath(@__DIR__, "my_cortex.stl"))
# load_cortex_stl() # load the default "cortex.stl" file
# load_cortex_stl(joinpath(@__DIR__, "my_cortex.stl")) # load the created "my_cortex.stl" file
