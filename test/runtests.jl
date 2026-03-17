using Test
using FitAPI

function _def_msg(local_num::UInt8, global_mesg_num::UInt16, defs::Vector{NTuple{3,UInt8}})
    bytes = UInt8[0x40 | local_num, 0x00, 0x00, UInt8(global_mesg_num & 0xFF), UInt8((global_mesg_num >> 8) & 0xFF), UInt8(length(defs))]
    for (num, size, base) in defs
        push!(bytes, num, size, base)
    end
    return bytes
end

function _data_msg(local_num::UInt8, payload::Vector{UInt8})
    return vcat(UInt8[local_num], payload)
end

function mk_m2_fit_bytes()
    data = UInt8[]

    # Record (global 20): timestamp, heart_rate, distance
    append!(data, _def_msg(0x00, 0x0014, [(0xFD, 0x04, 0x86), (0x03, 0x01, 0x02), (0x05, 0x04, 0x86)]))
    append!(data, _data_msg(0x00, UInt8[0xE8, 0x03, 0x00, 0x00, 0x96, 0x88, 0x13, 0x00, 0x00]))

    # Lap (global 19): timestamp, total_distance
    append!(data, _def_msg(0x01, 0x0013, [(0xFD, 0x04, 0x86), (0x09, 0x04, 0x86)]))
    append!(data, _data_msg(0x01, UInt8[0xF2, 0x03, 0x00, 0x00, 0x10, 0x27, 0x00, 0x00]))

    # Session (global 18): timestamp, sport, total_cycles, total_calories
    append!(data, _def_msg(0x02, 0x0012, [(0xFD, 0x04, 0x86), (0x05, 0x01, 0x00), (0x0A, 0x04, 0x86), (0x0B, 0x02, 0x84)]))
    append!(data, _data_msg(0x02, UInt8[0xFC, 0x03, 0x00, 0x00, 0x01, 0xF0, 0x00, 0x00, 0x00, 0x58, 0x02]))

    # Event (global 21): timestamp, event, event_type, data
    append!(data, _def_msg(0x03, 0x0015, [(0xFD, 0x04, 0x86), (0x00, 0x01, 0x00), (0x01, 0x01, 0x00), (0x03, 0x04, 0x86)]))
    append!(data, _data_msg(0x03, UInt8[0x06, 0x04, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]))

    # Unknown (global 250): field 90
    append!(data, _def_msg(0x04, 0x00FA, [(0x5A, 0x01, 0x02)]))
    append!(data, _data_msg(0x04, UInt8[0x11]))

    data_size = length(data)
    header = UInt8[
        0x0C,                   # header size (12)
        0x20,                   # protocol version
        0x01, 0x00,             # profile version
        UInt8(data_size & 0xFF),
        UInt8((data_size >> 8) & 0xFF),
        UInt8((data_size >> 16) & 0xFF),
        UInt8((data_size >> 24) & 0xFF),
        0x2E, 0x46, 0x49, 0x54, # .FIT
    ]

    return vcat(header, data)
end

@testset "FitAPI M2 Typed Coverage" begin
    opts = ParserOptions()
    @test opts.enable_logging == false

    dopts = DecodeOptions()
    @test dopts.decode_enums == true

    bytes = mk_m2_fit_bytes()
    core = parsefit(IOBuffer(bytes))

    @test length(core.records) == 10
    @test length(messages(core, FitAPI.DefinitionMessage)) == 5
    @test length(messages(core, FitAPI.DataMessage)) == 5

    parsed = collect(eachmessage(IOBuffer(bytes)))
    @test length(parsed) == 10

    tmp = tempname() * ".fit"
    write(tmp, bytes)
    core_path = parsefit(tmp)
    @test length(core_path.records) == 10

    analysis = readfit(IOBuffer(bytes))
    analysis_from_core = readfit(core)
    @test length(messages(analysis; name=:record)) == 1
    @test length(messages(analysis; name=:lap)) == 1
    @test length(messages(analysis; name=:session)) == 1
    @test length(messages(analysis; name=:event)) == 1
    @test length(messages(analysis; name=:unknown)) == 1
    @test length(messages(analysis_from_core; name=:record)) == 1
    @test length(messages(analysis; name="record")) == 1
    @test length(messages(analysis, FitAPI.DecodedMessage)) == 5

    rec = only(messages(analysis; name=:record))
    @test rec isa FitAPI.DecodedMessage
    @test fieldvalue(rec, :timestamp) == FitAPI.fit_seconds_to_datetime(UInt32(1000))
    @test fieldvalue(rec, :heart_rate) == UInt8(150)
    @test fieldvalue(rec, :distance) == 50.0
    @test fieldraw(rec, :distance) == UInt32(5000)
    @test findfield(rec, :distance) isa FitAPI.DecodedField

    lap = only(messages(analysis; name=:lap))
    @test fieldvalue(lap, :total_distance) == 100.0

    sess = only(messages(analysis; name=:session))
    @test fieldvalue(sess, :sport) == :running
    @test fieldvalue(sess, :total_strides) == UInt32(240)
    @test fieldvalue(sess, :total_calories) == UInt16(600)

    ev = only(messages(analysis; name=:event))
    @test fieldvalue(ev, :event) == :timer
    @test fieldvalue(ev, :event_type) == :stop
    @test findfield(ev, :timer_trigger) isa FitAPI.DecodedField

    unk = only(messages(analysis; name=:unknown))
    @test unk.global_message_number == UInt16(250)
    @test length(unk.fields) == 1
    @test unk.name == :unknown_msg_250

    table_rows = to_table(analysis; message=:record, extras_policy=:wide)
    @test length(table_rows) == 1
    @test table_rows[1].message_name == :record
    @test table_rows[1].heart_rate == UInt8(150)

    long_rows = to_table(analysis; message=:record, extras_policy=:long)
    @test !isempty(long_rows)
    @test hasproperty(long_rows[1], :field_name)

    unknown_rows = to_table(analysis; message=:unknown, extras_policy=:long)
    @test !isempty(unknown_rows)
    @test hasproperty(unknown_rows[1], :field_name)

    rm(tmp; force=true)
end

include("inference/test_type_stability.jl")
include("unit/test_hardening.jl")
include("integration/test_real_files.jl")

if get(ENV, "FITAPI_PERF_GUARDRAILS", "0") == "1"
    include("perf/test_perf_guardrails.jl")
end
