using Test
using FitAPI

function _sdk_fit(name::AbstractString)
    return normpath(joinpath(@__DIR__, "..", "..", "data", "sdk", name))
end

function _avg_parse_ms(path::AbstractString; rounds::Int)
    opts = ParserOptions(validate_crc=false)

    # Warm up JIT and parser path before timing.
    parsefit(path; options=opts)

    total_ns = Int128(0)
    for _ in 1:rounds
        t0 = time_ns()
        parsefit(path; options=opts)
        total_ns += (time_ns() - t0)
    end

    return Float64(total_ns) / rounds / 1_000_000.0
end

function _alloc_parse_bytes(path::AbstractString)
    opts = ParserOptions(validate_crc=false)
    parsefit(path; options=opts)
    return @allocated parsefit(path; options=opts)
end

function _alloc_readfit_bytes(path::AbstractString)
    opts = ParserOptions(validate_crc=false)
    readfit(path; options=opts)
    return @allocated readfit(path; options=opts)
end

@testset "Performance guardrails" begin
    activity_path = _sdk_fit("Activity.fit")
    multisport_path = _sdk_fit("activity_multisport.fit")

    @test isfile(activity_path)
    @test isfile(multisport_path)

    activity_ms = _avg_parse_ms(activity_path; rounds=5)
    multisport_ms = _avg_parse_ms(multisport_path; rounds=10)

    parse_activity_bytes = _alloc_parse_bytes(activity_path)
    readfit_activity_bytes = _alloc_readfit_bytes(activity_path)

    @info "Perf baseline check" activity_ms multisport_ms parse_activity_bytes readfit_activity_bytes

    # Guardrails derived from M4 baseline snapshot in prompts/implementation_blueprint.md.
    @test activity_ms <= 4.0
    @test multisport_ms <= 0.15
    @test parse_activity_bytes <= 5_000_000
    @test readfit_activity_bytes <= 20_000_000
end
