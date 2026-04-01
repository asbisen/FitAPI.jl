@inline function _invalid_sentinel(base_type::UInt8)
    if base_type == 0x00 || base_type == 0x02 || base_type == 0x0D
        return UInt8(0xFF)
    elseif base_type == 0x01
        return Int8(0x7F)
    elseif base_type == 0x83
        return Int16(0x7FFF)
    elseif base_type == 0x84
        return UInt16(0xFFFF)
    elseif base_type == 0x85
        return Int32(0x7FFFFFFF)
    elseif base_type == 0x86
        return UInt32(0xFFFFFFFF)
    end
    return nothing
end

@inline function _apply_invalid(v, base_type::UInt8, decode::DecodeOptions)
    decode.process_invalids || return v
    inv = _invalid_sentinel(base_type)
    inv === nothing && return v
    return v == inv ? missing : v
end

function _base_type_name(base_type::UInt8)
    if base_type == 0x00
        return :enum
    elseif base_type == 0x01
        return :sint8
    elseif base_type == 0x02
        return :uint8
    elseif base_type == 0x07
        return :string
    elseif base_type == 0x0A
        return :byte
    elseif base_type == 0x0D
        return :uint8z
    elseif base_type == 0x83
        return :sint16
    elseif base_type == 0x84
        return :uint16
    elseif base_type == 0x85
        return :sint32
    elseif base_type == 0x86
        return :uint32
    elseif base_type == 0x8B
        return :uint16z
    elseif base_type == 0x8C
        return :uint32z
    end
    return :unknown_base_type
end

@inline function _field_positions(msg::DataMessage)
    positions = zeros(Int, 256)
    for i in eachindex(msg.field_definitions)
        positions[Int(msg.field_definitions[i].field_def_num) + 1] = i
    end
    return positions
end

function _raw_condition_value(msg::DataMessage, positions::Vector{Int}, field_num::UInt8)
    idx = positions[Int(field_num) + 1]
    idx == 0 && return nothing
    return msg.field_values[idx]
end

function _subfield_matches(msg::DataMessage, positions::Vector{Int}, subfield::ProfileSubFieldDef)
    for group in subfield.conditions
        raw_value = _raw_condition_value(msg, positions, group.field_num)
        raw_value isa Integer || return false
        if !(Int64(raw_value) in group.raw_values)
            return false
        end
    end
    return true
end

function _resolve_subfield(msg::DataMessage, positions::Vector{Int}, field::ProfileFieldDef)
    for subfield in field.sub_fields
        _subfield_matches(msg, positions, subfield) && return subfield
    end
    return nothing
end

@inline _decode_enum(value, enum_map::Dict{Int64,Symbol}, decode::DecodeOptions) = decode.decode_enums && !isempty(enum_map) && value isa Integer ? get(enum_map, Int64(value), value) : value

function _apply_affine(value::Number, scale::Float64, offset::Float64)
    scale == 0.0 && throw(ArgumentError("scale cannot be zero in affine transform (field value: $value)"))
    return Float64(value) / scale - offset
end

function _apply_affine(values::Union{Vector{UInt8},Vector{UInt16},Vector{UInt32},Vector{Int16},Vector{Int32},Vector{Float32},Vector{Float64}}, scale::Float64, offset::Float64)
    return [_apply_affine(value, scale, offset) for value in values]
end

function _maybe_apply_scale_offset(value, scale::Float64, offset::Float64, should_apply::Bool, decode::DecodeOptions)
    decode.apply_scale_offset || return value
    should_apply || return value
    scale == 1.0 && offset == 0.0 && return value
    if value isa Number || value isa Vector{UInt8} || value isa Vector{UInt16} || value isa Vector{UInt32} || value isa Vector{Int16} || value isa Vector{Int32} || value isa Vector{Float32} || value isa Vector{Float64}
        return _apply_affine(value, scale, offset)
    end
    return value
end

function _maybe_convert_datetime(value, type_name::Symbol, decode::DecodeOptions)
    decode.convert_datetime || return value
    type_name == :date_time || return value
    if value isa UInt32
        return fit_seconds_to_datetime(value)
    elseif value isa Integer && value >= 0
        return fit_seconds_to_datetime(UInt32(value))
    elseif value isa Vector{UInt32}
        return [fit_seconds_to_datetime(item) for item in value]
    end
    return value
end

function _decode_profile_value(raw_value, base_type::UInt8, decode::DecodeOptions, type_name::Symbol, enum_map::Dict{Int64,Symbol}, scale::Float64, offset::Float64, apply_transform::Bool)
    value = _apply_invalid(raw_value, base_type, decode)
    value = _decode_enum(value, enum_map, decode)
    value = _maybe_apply_scale_offset(value, scale, offset, apply_transform, decode)
    value = _maybe_convert_datetime(value, type_name, decode)
    return value
end

function _decode_profile_field(msg::DataMessage, index::Int, positions::Vector{Int}, message_profile::Union{Nothing,ProfileMessageDef}, decode::DecodeOptions)
    fdef = msg.field_definitions[index]
    raw_value = msg.field_values[index]

    if isnothing(message_profile)
        return DecodedField(
            fdef.field_def_num,
            nothing,
            Symbol("unknown_field_$(fdef.field_def_num)"),
            _base_type_name(fdef.base_type),
            "",
            raw_value,
            _apply_invalid(raw_value, fdef.base_type, decode),
            :unknown,
        )
    end

    field_profile = get(message_profile.fields, fdef.field_def_num, nothing)
    if isnothing(field_profile)
        return DecodedField(
            fdef.field_def_num,
            nothing,
            Symbol("unknown_field_$(fdef.field_def_num)"),
            _base_type_name(fdef.base_type),
            "",
            raw_value,
            _apply_invalid(raw_value, fdef.base_type, decode),
            :unknown,
        )
    end

    subfield = _resolve_subfield(msg, positions, field_profile)
    effective = isnothing(subfield) ? field_profile : subfield
    value = _decode_profile_value(raw_value, fdef.base_type, decode, effective.type_name, effective.enum_map, effective.scale, effective.offset, effective.apply_transform)
    return DecodedField(
        fdef.field_def_num,
        nothing,
        effective.name,
        effective.type_name,
        effective.units,
        raw_value,
        value,
        isnothing(subfield) ? :profile : :subfield,
    )
end

function _decode_developer_field(msg::DataMessage, index::Int)
    ddef = msg.developer_field_definitions[index]
    raw_value = msg.developer_values[index]
    return DecodedField(
        ddef.field_def_num,
        ddef.developer_data_index,
        Symbol("developer_field_$(ddef.developer_data_index)_$(ddef.field_def_num)"),
        :developer_data,
        "",
        raw_value,
        raw_value,
        :developer,
    )
end

function _decode_data_message(msg::DataMessage, decode::DecodeOptions, profile::FitProfileCache)
    positions = _field_positions(msg)
    message_profile = get(profile.messages, msg.global_message_number, nothing)
    name = isnothing(message_profile) ? Symbol("unknown_msg_$(msg.global_message_number)") : message_profile.name

    fields = Vector{DecodedField}(undef, length(msg.field_definitions) + length(msg.developer_field_definitions))
    for index in eachindex(msg.field_definitions)
        fields[index] = _decode_profile_field(msg, index, positions, message_profile, decode)
    end
    for index in eachindex(msg.developer_field_definitions)
        fields[length(msg.field_definitions) + index] = _decode_developer_field(msg, index)
    end

    return DecodedMessage(msg.global_message_number, name, fields)
end

function readfit(core::FitCoreResult; decode::DecodeOptions=DecodeOptions(), materialize::Bool=true, profile::FitProfileCache=PROFILE)
    _ = materialize

    by_name = Dict{Symbol,Vector{DecodedMessage}}()

    for rec in core.records
        if rec isa DataMessage
            decoded = _decode_data_message(rec, decode, profile)
            push!(get!(by_name, decoded.name) do
                DecodedMessage[]
            end, decoded)
        end
    end

    return FitAnalysisResult(core.header, by_name)
end

function readfit(path_or_io; options::ParserOptions=ParserOptions(), decode::DecodeOptions=DecodeOptions(), materialize::Bool=true)
    core = if path_or_io isa IO
        parsefit(path_or_io; options=options)
    else
        parsefit(path_or_io; options=options)
    end
    return readfit(core; decode=decode, materialize=materialize)
end
