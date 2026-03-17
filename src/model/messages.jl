const RawFieldScalar = Union{Missing,UInt8,UInt16,UInt32,Int8,Int16,Int32,Int64,Float32,Float64,Bool}
const RawFieldVector = Union{Vector{UInt8},Vector{UInt16},Vector{UInt32},Vector{Int16},Vector{Int32},Vector{Float32},Vector{Float64}}
const RawFieldValue = Union{RawFieldScalar,RawFieldVector,String}
const FieldValue = RawFieldValue

const DecodedScalar = Union{Missing,UInt8,UInt16,UInt32,Int8,Int16,Int32,Int64,Float32,Float64,Bool,Symbol,DateTime}
const DecodedVector = Union{Vector{UInt8},Vector{UInt16},Vector{UInt32},Vector{Int16},Vector{Int32},Vector{Float32},Vector{Float64},Vector{Symbol},Vector{DateTime}}
const DecodedValue = Union{DecodedScalar,DecodedVector,String}

struct DecodedField
    field_num::UInt8
    developer_data_index::Union{Nothing,UInt8}
    name::Symbol
    type_name::Symbol
    units::String
    raw_value::RawFieldValue
    value::DecodedValue
    source::Symbol
end

struct DecodedMessage
    global_message_number::UInt16
    name::Symbol
    fields::Vector{DecodedField}
end

struct FitAnalysisResult
    header::FitHeader
    by_name::Dict{Symbol,Vector{DecodedMessage}}
end
