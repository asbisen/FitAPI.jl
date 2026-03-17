mutable struct ByteReader{T<:IO}
    io::T
    offset::Int64
end

@inline function read_u8!(br::ByteReader)::UInt8
    try
        b = read(br.io, UInt8)
        br.offset += 1
        return b
    catch e
        if e isa EOFError
            throw(FitFormatError("Unexpected EOF while reading UInt8", br.offset))
        end
        rethrow()
    end
end

@inline function read_u16_le!(br::ByteReader)::UInt16
    b = read(br.io, 2)
    if length(b) != 2
        throw(FitFormatError("Unexpected EOF while reading UInt16", br.offset))
    end
    br.offset += 2
    return UInt16(b[1]) | (UInt16(b[2]) << 8)
end

@inline function read_u32_le!(br::ByteReader)::UInt32
    b = read(br.io, 4)
    if length(b) != 4
        throw(FitFormatError("Unexpected EOF while reading UInt32", br.offset))
    end
    br.offset += 4
    return UInt32(b[1]) | (UInt32(b[2]) << 8) | (UInt32(b[3]) << 16) | (UInt32(b[4]) << 24)
end

@inline function read_bytes!(br::ByteReader, n::Int)::Vector{UInt8}
    data = read(br.io, n)
    if length(data) != n
        throw(FitFormatError("Unexpected EOF while reading bytes", br.offset))
    end
    br.offset += n
    return data
end
