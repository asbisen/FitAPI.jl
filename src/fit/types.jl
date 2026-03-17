struct FitHeader
    header_size::UInt8
    protocol_version::UInt8
    profile_version::UInt16
    data_size::UInt32
    data_type::NTuple{4,UInt8}
    header_crc::Union{Nothing,UInt16}
end

struct FieldDefinition
    field_def_num::UInt8
    size::UInt8
    base_type::UInt8
end

struct MessageDefinition
    local_mesg_num::UInt8
    has_developer_data::Bool
    reserved::UInt8
    architecture::UInt8
    global_message_number::UInt16
    fields::Vector{FieldDefinition}
end

struct DeveloperFieldDefinition
    field_def_num::UInt8
    size::UInt8
    developer_data_index::UInt8
end

mutable struct DefinitionSlot
    is_set::Bool
    local_mesg_num::UInt8
    architecture::UInt8
    global_message_number::UInt16
    fields::Vector{FieldDefinition}
    developer_fields::Vector{DeveloperFieldDefinition}
end

mutable struct DecodeState
    definitions_local::Vector{DefinitionSlot}
    last_timestamp::UInt32
end

function init_decode_state(::ParserOptions)
    slots = [DefinitionSlot(false, UInt8(i - 1), 0x00, 0x0000, FieldDefinition[], DeveloperFieldDefinition[]) for i in 1:16]
    return DecodeState(slots, 0x00000000)
end

struct DefinitionMessage
    definition::MessageDefinition
    developer_fields::Vector{DeveloperFieldDefinition}
end

struct DataMessage
    local_mesg_num::UInt8
    global_message_number::UInt16
    field_values::Vector{Any}
    developer_values::Vector{Vector{UInt8}}
    field_definitions::Vector{FieldDefinition}
    developer_field_definitions::Vector{DeveloperFieldDefinition}
end

const ParsedRecord = Union{DefinitionMessage,DataMessage}

struct FitCoreResult{H,R}
    header::H
    records::R
end

struct FitAnalysisResult
    header
    by_name::Dict{Symbol,Any}
end
