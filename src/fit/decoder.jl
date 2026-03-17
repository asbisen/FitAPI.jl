@inline function _read_u16!(br::ByteReader, architecture::UInt8)::UInt16
    if architecture == 0x00
        return read_u16_le!(br)
    end
    b = read_bytes!(br, 2)
    return (UInt16(b[1]) << 8) | UInt16(b[2])
end

@inline function _read_u32!(br::ByteReader, architecture::UInt8)::UInt32
    if architecture == 0x00
        return read_u32_le!(br)
    end
    b = read_bytes!(br, 4)
    return (UInt32(b[1]) << 24) | (UInt32(b[2]) << 16) | (UInt32(b[3]) << 8) | UInt32(b[4])
end

function _read_field_value!(br::ByteReader, def::FieldDefinition, architecture::UInt8)
    bt = def.base_type

    if bt == 0x02 || bt == 0x00 || bt == 0x0A || bt == 0x0D
        if def.size == 1
            return read_u8!(br)
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x01
        if def.size == 1
            return reinterpret(Int8, read_u8!(br))
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x84 || bt == 0x8B
        if def.size == 2
            return _read_u16!(br, architecture)
        elseif def.size % 2 == 0
            n = Int(def.size ÷ 2)
            values = Vector{UInt16}(undef, n)
            for i in 1:n
                values[i] = _read_u16!(br, architecture)
            end
            return values
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x83
        if def.size == 2
            return reinterpret(Int16, _read_u16!(br, architecture))
        elseif def.size % 2 == 0
            n = Int(def.size ÷ 2)
            values = Vector{Int16}(undef, n)
            for i in 1:n
                values[i] = reinterpret(Int16, _read_u16!(br, architecture))
            end
            return values
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x86 || bt == 0x8C
        if def.size == 4
            return _read_u32!(br, architecture)
        elseif def.size % 4 == 0
            n = Int(def.size ÷ 4)
            values = Vector{UInt32}(undef, n)
            for i in 1:n
                values[i] = _read_u32!(br, architecture)
            end
            return values
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x85
        if def.size == 4
            return reinterpret(Int32, _read_u32!(br, architecture))
        elseif def.size % 4 == 0
            n = Int(def.size ÷ 4)
            values = Vector{Int32}(undef, n)
            for i in 1:n
                values[i] = reinterpret(Int32, _read_u32!(br, architecture))
            end
            return values
        end
        return read_bytes!(br, Int(def.size))
    elseif bt == 0x07
        raw = read_bytes!(br, Int(def.size))
        nul = findfirst(==(0x00), raw)
        if isnothing(nul)
            return String(raw)
        end
        if nul == 1
            return ""
        end
        return String(raw[1:nul-1])
    end

    return read_bytes!(br, Int(def.size))
end

function _decode_definition_message!(br::ByteReader, header_byte::UInt8, state::DecodeState)
    local_mesg_num = header_byte & 0x0F
    has_developer_data = (header_byte & 0x20) != 0
    reserved = read_u8!(br)
    architecture = read_u8!(br)
    global_message_number = _read_u16!(br, architecture)
    nfields = Int(read_u8!(br))

    fields = Vector{FieldDefinition}(undef, nfields)
    for i in 1:nfields
        fields[i] = FieldDefinition(read_u8!(br), read_u8!(br), read_u8!(br))
    end

    developer_fields = DeveloperFieldDefinition[]
    if has_developer_data
        ndev = Int(read_u8!(br))
        sizehint!(developer_fields, ndev)
        for _ in 1:ndev
            push!(developer_fields, DeveloperFieldDefinition(read_u8!(br), read_u8!(br), read_u8!(br)))
        end
    end

    slot_idx = Int(local_mesg_num) + 1
    slot = state.definitions_local[slot_idx]
    slot.is_set = true
    slot.local_mesg_num = local_mesg_num
    slot.architecture = architecture
    slot.global_message_number = global_message_number
    slot.fields = fields
    slot.developer_fields = developer_fields

    def = MessageDefinition(local_mesg_num, has_developer_data, reserved, architecture, global_message_number, fields)
    return DefinitionMessage(def, developer_fields)
end

function _decode_data_message!(br::ByteReader, header_byte::UInt8, state::DecodeState)
    local_mesg_num = header_byte & 0x0F
    slot = state.definitions_local[Int(local_mesg_num) + 1]
    if !slot.is_set
        throw(FitFormatError("Data message encountered before matching definition", br.offset))
    end

    field_values = Vector{Any}(undef, length(slot.fields))
    for (i, fdef) in enumerate(slot.fields)
        field_values[i] = _read_field_value!(br, fdef, slot.architecture)
    end

    developer_values = Vector{Vector{UInt8}}(undef, length(slot.developer_fields))
    for (i, dfd) in enumerate(slot.developer_fields)
        developer_values[i] = read_bytes!(br, Int(dfd.size))
    end

    return DataMessage(
        local_mesg_num,
        slot.global_message_number,
        field_values,
        developer_values,
        slot.fields,
        slot.developer_fields,
    )
end

function parse_messages!(br::ByteReader, header::FitHeader, state::DecodeState, ::ParserOptions)
    data_end = br.offset + Int64(header.data_size)
    records = ParsedRecord[]

    while br.offset < data_end
        header_byte = read_u8!(br)

        if (header_byte & 0x80) != 0
            throw(FitNotImplementedError("Compressed timestamp headers are planned after M1"))
        elseif (header_byte & 0x40) != 0
            push!(records, _decode_definition_message!(br, header_byte, state))
        else
            push!(records, _decode_data_message!(br, header_byte, state))
        end
    end

    if br.offset != data_end
        throw(FitFormatError("Parser position does not match FIT data_size boundary", br.offset))
    end

    return FitCoreResult(header, records)
end
