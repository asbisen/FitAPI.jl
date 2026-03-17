function parse_header!(br::ByteReader, options::ParserOptions)::FitHeader
    _ = options

    header_size = read_u8!(br)
    if header_size != 0x0C && header_size != 0x0E
        throw(FitFormatError("Invalid FIT header size", br.offset))
    end
    protocol_version = read_u8!(br)
    profile_version = read_u16_le!(br)
    data_size = read_u32_le!(br)
    sig = read_bytes!(br, 4)
    data_type = (sig[1], sig[2], sig[3], sig[4])

    header_crc = if header_size == 0x0E
        read_u16_le!(br)
    else
        nothing
    end

    if data_type != (0x2e, 0x46, 0x49, 0x54)
        throw(FitFormatError("Invalid FIT signature", br.offset))
    end

    return FitHeader(header_size, protocol_version, profile_version, data_size, data_type, header_crc)
end
