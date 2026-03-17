using Test
using FitAPI

const SDK_DIR = normpath(joinpath(@__DIR__, "..", "..", "data", "sdk"))

function _sdk_fit_files()
    if !isdir(SDK_DIR)
        return String[]
    end
    files = filter(f -> endswith(lowercase(f), ".fit"), readdir(SDK_DIR; join=true))
    return sort(files)
end

@testset "SDK FIT fixtures" begin
    files = _sdk_fit_files()
    @test !isempty(files)

    @testset "Parser smoke tests" begin
        for f in files
            @testset "parse $(basename(f))" begin
                core = parsefit(f)
                @test core isa FitAPI.FitCoreResult
                @test core.header.data_type == (0x2e, 0x46, 0x49, 0x54)
                @test core.header.data_size > 0
                @test !isempty(core.records)
            end
        end
    end

    @testset "Semantic expectations" begin
        activity_file = joinpath(SDK_DIR, "Activity.fit")
        settings_file = joinpath(SDK_DIR, "Settings.fit")

        if isfile(activity_file)
            activity = readfit(activity_file)
            @test activity isa FitAPI.FitAnalysisResult
            @test length(messages(activity; name=:record)) > 0
            @test length(messages(activity; name=:lap)) > 0
            @test length(messages(activity; name=:session)) > 0
            @test length(messages(activity; name=:event)) > 0

            rows = to_table(activity; message=:record, extras_policy=:wide)
            @test !isempty(rows)
        end

        if isfile(settings_file)
            settings = readfit(settings_file)
            @test settings isa FitAPI.FitAnalysisResult
            @test length(messages(settings; name=:record)) == 0
            @test length(messages(settings; name=:lap)) == 0
            @test length(messages(settings; name=:session)) == 0
            @test length(messages(settings; name=:event)) == 0
            @test haskey(settings.by_name, :file_id)
            @test isempty(messages(settings; name=:unknown))
        end
    end

    for f in files
        @testset "analysis buckets $(basename(f))" begin
            analysis = readfit(f)
            @test analysis isa FitAPI.FitAnalysisResult
            @test !isempty(analysis.by_name)
            @test all(k -> k isa Symbol, keys(analysis.by_name))
            @test all(v -> v isa Vector{FitAPI.DecodedMessage}, values(analysis.by_name))
        end
    end
end
