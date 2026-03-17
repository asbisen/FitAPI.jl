using Test
using FitAPI

@testset "Type stability" begin
    io = IOBuffer(mk_m2_fit_bytes())
    result = @inferred parsefit(io)
    @test result isa FitAPI.FitCoreResult

    analysis = @inferred readfit(IOBuffer(mk_m2_fit_bytes()))
    @test analysis isa FitAPI.FitAnalysisResult

    record = only(messages(analysis; name=:record))
    @test fieldvalue(record, :distance) == 50.0
    @test fieldraw(record, :distance) == UInt32(5000)
end
