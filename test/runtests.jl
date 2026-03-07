using Test

include("leadfield.jl")

@testset "head_model function tests" begin
    file = "fsavLEADFIELD_4_GEDAI.mat"

    # Base head_model_ behavior to compare against
    K_, ename_, eloc_, gridloc_ = head_model_(file)
    ename_lower_ = lowercase.(ename_)

    @testset "1. No labels, reference = 0.0 (default)" begin
        K1, ename1, eloc1, gridloc1 = head_model(file)

        # Check output sizes and identities
        @test size(K1) == size(K_)
        @test ename1 == ename_
        @test eloc1 == eloc_
        @test gridloc1 == gridloc_

        # K1 should be CAR referenced
        avg_ = sum(K_, dims=1) ./ size(K_, 1)
        @test K1 ≈ (K_ .- avg_)
    end

    @testset "2. labels provided, reference = 0.0" begin
        labels2 = ["FP1", "FP2", "C3", "C4"]
        K2, ename2, eloc2, gridloc2 = head_model(file, labels2)

        @test length(ename2) == 4
        @test lowercase.(ename2) == lowercase.(labels2)
        @test gridloc2 == gridloc_

        # testing CAR on just the selected labels
        labels_idx2 = [findfirst(==(lowercase(l)), ename_lower_) for l in labels2]
        K2_unref = K_[labels_idx2, :]
        avg2 = sum(K2_unref, dims=1) ./ size(K2_unref, 1)
        @test K2 ≈ (K2_unref .- avg2)
    end

    @testset "3. No labels, string reference" begin
        # Assume "Cz" exists in the mat file
        ref_label3 = "Cz"
        K3, ename3, eloc3, gridloc3 = head_model(file, reference=ref_label3)

        cz_idx = findfirst(==(lowercase(ref_label3)), ename_lower_)

        @test length(ename3) == length(ename_) - 1
        @test !(ref_label3 in ename3)
        @test !(lowercase(ref_label3) in lowercase.(ename3))

        # Manually compute expected K
        K3_expected = K_ .- K_[cz_idx:cz_idx, :]
        keep_mask3 = trues(length(ename_))
        keep_mask3[cz_idx] = false
        K3_expected = K3_expected[keep_mask3, :]

        @test K3 ≈ K3_expected
    end

    @testset "4. labels provided, string reference IN labels" begin
        labels4 = ["Fz", "Cz", "Pz"]
        ref_label4 = "Cz"
        K4, ename4, eloc4, gridloc4 = head_model(file, labels4, reference=ref_label4)

        @test length(ename4) == 2
        @test !(ref_label4 in ename4)

        labels_idx4 = [findfirst(==(lowercase(l)), ename_lower_) for l in labels4]
        K4_unref = K_[labels_idx4, :]
        cz_idx4 = findfirst(==(lowercase(ref_label4)), lowercase.(labels4))

        # Expected K
        K4_expected = K4_unref .- K4_unref[cz_idx4:cz_idx4, :]
        keep_mask4 = trues(length(labels4))
        keep_mask4[cz_idx4] = false
        K4_expected = K4_expected[keep_mask4, :]

        @test K4 ≈ K4_expected
    end

    @testset "5. labels provided, string reference NOT in labels" begin
        labels5 = ["FP1", "FP2"]
        ref_label5 = "Cz"

        K5, ename5, eloc5, gridloc5 = head_model(file, labels5, reference=ref_label5)

        @test length(ename5) == 2
        @test lowercase.(ename5) == lowercase.(labels5)

        labels_and_ref5 = [labels5; ref_label5]
        labels_idx5 = [findfirst(==(lowercase(l)), ename_lower_) for l in labels_and_ref5]
        K5_unref = K_[labels_idx5, :]
        ref_idx5 = length(labels_and_ref5)

        # Expected K
        K5_expected = K5_unref .- K5_unref[ref_idx5:ref_idx5, :]
        keep_mask5 = trues(length(labels_and_ref5))
        keep_mask5[ref_idx5] = false
        K5_expected = K5_expected[keep_mask5, :]

        @test K5 ≈ K5_expected
    end

    @testset "6. Invalid label or reference" begin
        @test_throws ErrorException head_model(file, ["InvalidLabel123"])
        @test_throws ErrorException head_model(file, reference="InvalidRef123")
    end
end;
