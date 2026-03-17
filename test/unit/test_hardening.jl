using Test
using FitAPI

function _mk_bad_signature_bytes()
    data = UInt8[0x00]
    header = UInt8[
        0x0C,
        0x20,
        0x01, 0x00,
        0x01, 0x00, 0x00, 0x00,
        0x2E, 0x42, 0x41, 0x44,
    ]
    return vcat(header, data)
end

function _mk_data_before_definition_bytes()
    data = UInt8[
        0x00,                   # data header for local mesg 0, but no definition before it
        0xE8, 0x03, 0x00, 0x00,
    ]
    header = UInt8[
        0x0C,
        0x20,
        0x01, 0x00,
        UInt8(length(data)), 0x00, 0x00, 0x00,
        0x2E, 0x46, 0x49, 0x54,
    ]
    return vcat(header, data)
end

@testset "Hardening regressions" begin
    @test_throws FitAPI.FitFormatError parsefit(IOBuffer(_mk_bad_signature_bytes()))
    @test_throws FitAPI.FitFormatError parsefit(IOBuffer(_mk_data_before_definition_bytes()))

    # Truncated bytes should surface as structured format errors (not raw EOFError).
    @test_throws FitAPI.FitFormatError parsefit(IOBuffer(UInt8[0x0C, 0x20]))

    # CRC mismatch path validation
    tmp = tempname() * ".fit"
    data = UInt8[
        0x40, 0x00, 0x00, 0x14, 0x00, 0x01, 0xFD, 0x04, 0x86,
        0x00, 0xE8, 0x03, 0x00, 0x00,
    ]
    header = UInt8[
        0x0C, 0x20, 0x01, 0x00,
        UInt8(length(data)), 0x00, 0x00, 0x00,
        0x2E, 0x46, 0x49, 0x54,
    ]
    payload = vcat(header, data)
    # Deliberately wrong CRC bytes
    write(tmp, vcat(payload, UInt8[0x00, 0x00]))
    @test_throws FitAPI.FitChecksumError parsefit(tmp)
    rm(tmp; force=true)
end
