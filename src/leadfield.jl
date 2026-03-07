# The complete description of the file "fsavLEADFIELD_4_GEDAI.mat"
# is in file "fsavLEADFIELD.pdf"


# Read into a .mat `file` a leadfield for EEG inverse solutions.
# Return four arguments:
# 1) leadfield matrix: 343 electrodes x 1210 (voxels) x3(orientations) (3630) 
# 2) electrode labels: 343-vector of strings
# 3) electrode locations: 343-vector of 3-vectors
# 4) voxel locations: 1210-vector of 3-vectors
function head_model_()

    file = leadfield_path

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

# Compute the computational elements of an head model for EEG inverse solutions
# from the provided file "fsavLEADFIELD_4_GEDAI.mat".
# It takes as arguments:
# 1) labels: vector of electrode labels (optional)
# 2) reference: reference electrode label (optional)
# Return the 4-tuple comprising:
# a) leadfield matrix: Ne(electrodes) x [1210(voxels) x 3(orientations)] 
# b) electrode labels: a Ne-vector of strings
# c) electrode locations: a Ne-vector of 3-vectors holding each the location in 3D cartesian coordinates
# d) voxel locations: a 1210-vector of 3-vectors holding each the location in 3D cartesian coordinates.

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
# 2) If `reference` is a real value (default 0.0)
#   the leadfield matrix is re-referenced to the (common average reference + `reference`),
#   thus if `reference` = 0.0, it is referenced to the (rank-deficient) common average reference,
#   and if `reference` = 1.0, it referenced to the full-rank pseudo common average reference.
#   See the Eegle.car! function for explanations.
function head_model(labels::Union{Vector{String}, Nothing}=nothing; 
                    reference::Union{String, Real}=0.0)

    K, ename, eloc, gridloc = head_model_()
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
# K, ename, eloc, gridloc = head_model()
# K, ename, eloc, gridloc = head_model(["FP1", "FP2", "F3", "F4", "C3", "C4", "P3", "P4", "O1", "O2"])
