function parsefit(io::IO; options::ParserOptions=ParserOptions())
    br = ByteReader(io, 0)
    header = parse_header!(br, options)
    state = init_decode_state(options)
    return parse_messages!(br, header, state, options)
end

function parsefit(path::AbstractString; options::ParserOptions=ParserOptions())
    data = read(path)
    core = parsefit(IOBuffer(data); options=options)

    if options.validate_crc
        payload_end = Int(core.header.header_size) + Int(core.header.data_size)

        if payload_end > length(data)
            throw(FitFormatError("File shorter than FIT header+data_size boundary", payload_end))
        end

        # FIT file CRC is optional in fixtures; validate only when trailing CRC bytes exist.
        if payload_end + 2 <= length(data)
            if !validate_file_crc(data, payload_end)
                stored = extract_crc_le(data, payload_end + 1)
                computed = calculate_crc(view(data, 1:payload_end))
                throw(FitChecksumError(stored, computed))
            end
        end
    end

    return core
end

function eachmessage(io::IO; options::ParserOptions=ParserOptions())
    core = parsefit(io; options=options)
    return (m for m in core.records)
end

function eachmessage(path::AbstractString; options::ParserOptions=ParserOptions())
    open(path, "r") do io
        return eachmessage(io; options=options)
    end
end
