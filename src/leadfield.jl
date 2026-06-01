# The complete description of how to generate headmodel files and other files generated 
# using the Brainstorm software is in file "Documents\Brainstorm_Directions.pdf".
# Brainstorm generates .mat files, which are found:
# - in the "HeadModels" folder (e.g., "headmodel_2503.mat")
# - in the "Sensors" Folder (only "channel_ASA_10-05_343.mat")
# - in the "Meshes" Folder (e.g., "tess_cortex_pial_low_2503.mat")
# For the "headmodel_1210.mat" only, a summary of the content is provided in file "headmodel_1210.pdf".
# This headmodel has been generated differently from the others and the .mat file has a different dictionary.
# It is used only by Gedai.jl as it has a low spatial resolution (voxel of 1cm³)


# Read into the leadfield_1210.mat file the leadfield for EEG inverse solutions EXCLUSIVELY USED for Gedai.jl.
# Return four arguments:
# 1) leadfield matrix: 343 electrodes x 1210 (voxels) x3(orientations) (3630) 
# 2) electrode labels: 343-vector of strings
# 3) electrode locations: 343-vector of 3-vectors
# 4) voxel locations: 1210-vector of 3-vectors
function leadfield_1210_()

    file = leadfield_1210_path

    # read main dictionary
    d = matread(file)["leadfield4GEDAI"]

    # electrode subdictionary
    e = d["electrodes"]
    eloc_ = reshape(float.(e["Loc"]), 343)
    eloc = [reshape(v, 3) for v in eloc_] # 343-vector of 3-vectors (electrode 3D locations)
    ename = reshape(string.(e["Name"]), length(eloc)) # 343-vector of electrodes labels


    gridloc_ = d["GridLoc"]
    gridloc = [gridloc_[i, :] for i in 1:size(gridloc_, 1)] # 1210-vector of 3-vectors
    # of voxel 3D positions

    # d["GridOptions"]["Resolution"] # voxel grid resolution

    K = d["Gain"] # leadfield matrix 343 electrodes x 1210 (voxels) x3(orientations) (3630) 

    return K, ename, eloc, gridloc

end


# Read into the leadfield_XXX.mat file the leadfield for EEG inverse solutions.
# These files are produced by BrainStorm
# following the procedure described in the document "Documents\BrainStorm_Directions"
# It takes as arguments `voxels`, an integer identifying the head model file to be used.
# Each head model is constructed for the given integer number of voxels.
# Return the 4-tuple comprising:
#1) leadfield matrix K: 343 electrodes x (`voxels` x 3 orientations) 
#2) electrode labels: 343-vector of strings
#3) electrode locations: 343-vector of 3-vectors (x, y, z)
#4) voxel locations: `voxels`-vector of 3-vectors (x, y, z)
#
# Supported `voxels` integer: 
# - 2503 (default)
# - 5002
function leadfield_(voxels::Int = 2503)

    if voxels===2503
        headmodel_path = leadfield_2503_path
    elseif voxels===5002
        headmodel_path = leadfield_5002_path
    end

    hm   = matread(headmodel_path) # "headmodel_XXX.mat"
    sensor = matread(sensors_path) # "channel_ASA_10-05_343.mat" 

    # print(keys(sensor)) #["Comment", "TransfEeg", "HeadPoints", "MegRefCoef", "Projector", "TransfEegLabels", "IntraElectrodes", "TransfMeg", "History", "SCS", "Channel", "TransfMegLabels", "Clusters"]
    # println(keys(hm)) #["Comment", "Param", "HeadModelType", "MEGMethod", "SurfaceFile", "GridAtlas", "SEEGMethod", "History", "GridOptions", "EEGMethod", "ECOGMethod", "Gain", "NIRSMethod", "GridOrient", "GridLoc", "FemMeshFile"]
    
    # test if the keys in files exist

    haskey(sensor, "Channel")|| throw(ArgumentError("Channel keys not found in sensorsfile"))
    haskey(hm, "Gain")|| throw(ArgumentError("Gain keys not found in headmodelfile"))
    haskey(hm, "GridLoc")|| throw(ArgumentError("Gridloc keys not found in headmodelfile"))

    e = sensor["Channel"]
    ne = size(sensor["Channel"]["Name"], 2) # number of electrodes

    eloc_ = reshape(float.(e["Loc"]), ne) # electrode coordinates
    eloc = [reshape(v, 3) for v in eloc_] # ne-vector of 3-vectors (electrode 3D locations)
    ename = reshape(string.(e["Name"]),length(eloc)) # ne-Vector of electrode name as strings

    K = Float64.(hm["Gain"])      # ne × nvx3  Leadfield Matrix    
    # npzwrite("K.npz", Dict("K" => K)) # if you want to get K

    gridloc = [Vector(r) for r in eachrow(Float64.(hm["GridLoc"]))] # nv-vector of 3-vectors of voxel coordinates

    return K, ename, eloc, gridloc
end



# Compute the computational elements of an head model for EEG inverse solutions and GEDAI
# from a stored headmodel .mat file produced by Brainstorm software
# It takes as arguments:
# 1) labels: vector of electrode labels (optional)
# 2) reference: reference electrode label (optional)
# It takes as optional keyword argument:
# 1) `voxels`, an integer identifying a model by its number of voxels. By default is 2503,
#   which uses the 2503-voxel model. It can be also 1210 or 5002.
# Return the 4-tuple comprising:
# a) leadfield matrix: Ne(electrodes) x [`voxels` x 3(orientations)] 
# b) electrode labels: a Ne-vector of strings
# c) electrode locations: a Ne-vector of 3-vectors holding each the location in 3D cartesian coordinates
# d) voxel locations: a `voxels`-vector of 3-vectors holding each the location in 3D cartesian coordinates.

# In the output tuple, d) (voxel locations) is always the same.
# By default (`labels`=nothing and `reference =0.0`) Ne = 343, i.e., this function computes 
# the leadfield matrix in the common average reference (rank-deficient, with rank Ne-1) at all available electrodes 
# and returns the associated electrode labels and locations.

# If `labels` is a vector of strings, Ne = length(labels) and (a, b, c) contains only the elements
# corresponding to the provided labels.

# Furthermore,
# 1) If `reference` is equal to an electrode label (a string), 
# the leadfield matrix is re-referenced to that electrode.
# case 1.1: `labels` is not provided:
#    Ne = 343-1, since the elements of (a, b, c) corresponding to that electrode are removed.
# case 1.2: `labels` is provided:
#	1.2.a: `reference` is in labels:
#       Ne = length(labels)-1, since the elements of (a, b, c) corresponding to that electrode are removed.
#	1.2.b: `reference` is not in labels:
#       Ne = length(labels)
# 2) If `reference` is a real value different from the default (0.0)
#   the leadfield matrix is re-referenced to the (common average reference + `reference`),
#   thus if `reference` = 0.0, it is referenced to the (rank-deficient) common average reference,
#   and if `reference` = 1.0, it referenced to the full-rank pseudo common average reference.
#   See the Eegle.car! function for explanations.
function leadfield(labels::Union{Vector{String}, Nothing}=nothing; 
                    reference::Union{String, Real}=0.0,
                    voxels::Int = 2503)

    K = nothing
    ename = nothing
    eloc = nothing
    gridloc = nothing

    voxels in (1210, 2503, 5002) || throw(ArgumentError("The `voxels` keyword argument can be 1210, 2503 or 5002"))

    if voxels===1210
        K, ename, eloc, gridloc = leadfield_1210_() # special call only for this model
    else
        K, ename, eloc, gridloc = leadfield_(voxels) # any other model
    end

    ename_lower = lowercase.(ename)

    if labels !== nothing
        labels_lower = lowercase.(labels)
        for (i, l) in enumerate(labels_lower)
            if !(l in ename_lower)
                error("Label $l ($(labels[i])) not found in ename.")
            end
        end
    end

    if reference isa String
        ref_lower = lowercase(reference)
        if labels === nothing
            # 1a) labels is not provided
            if !(ref_lower in ename_lower)
                error("Error: Reference electrode $reference not found in ename.")
            end

            i = findfirst(==(ref_lower), ename_lower)

            K = K .- K[i:i, :]

            keep_mask = trues(length(ename))
            keep_mask[i] = false
            K = K[keep_mask, :]
            ename = ename[keep_mask]
            eloc = eloc[keep_mask]
        else
            # 1b) labels is provided
            if ref_lower in labels_lower
                # 1b1: reference is in labels
                mask = [findfirst(==(l), ename_lower) for l in labels_lower]
                K = K[mask, :]
                ename = ename[mask]
                eloc = eloc[mask]

                i = findfirst(==(ref_lower), lowercase.(ename))

                K = K .- K[i:i, :]

                keep_mask = trues(length(ename))
                keep_mask[i] = false
                K = K[keep_mask, :]
                ename = ename[keep_mask]
                eloc = eloc[keep_mask]
            else
                # 1b2: reference is NOT in labels
                if !(ref_lower in ename_lower)
                    error("Reference electrode not found.")
                end

                labels_and_ref_lower = [labels_lower; ref_lower]
                mask = [findfirst(==(l), ename_lower) for l in labels_and_ref_lower]

                K = K[mask, :]
                ename = ename[mask]
                eloc = eloc[mask]

                i = length(ename)

                K = K .- K[i:i, :]

                keep_mask = trues(length(ename))
                keep_mask[i] = false
                K = K[keep_mask, :]
                ename = ename[keep_mask]
                eloc = eloc[keep_mask]
            end
        end
    elseif reference isa Real
        if labels !== nothing
            mask = [findfirst(==(l), ename_lower) for l in labels_lower]
            K = K[mask, :]
            ename = ename[mask]
            eloc = eloc[mask]
        end

        begin
            avg = sum(K, dims=1) ./ (size(K, 1) + reference)
            K = K .-= avg
        end
    end

    return K, ename, eloc, gridloc
end


# Example usage
# K, ename, eloc, gridloc = leadfield() # use the 2503-voxel model (default)
# K, ename, eloc, gridloc = leadfield(; headmodel=5002) # use the 5002-voxel model

# use the 2503-voxel model and  get the head model for a given set of electrodes (average-reference)
# K, ename, eloc, gridloc = leadfield(["FP1", "FP2", "F3", "F4", "C3", "C4", "P3", "P4", "O1", "O2"])


