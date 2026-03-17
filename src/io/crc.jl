const CRC_TABLE = UInt16[
    0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
]

function calculate_crc(data::AbstractVector{UInt8})::UInt16
    crc = UInt16(0)
    for byte in data
        tmp = CRC_TABLE[((crc & 0x000F) ⊻ (byte & 0x0F)) + 1]
        crc = ((crc >> 4) & 0x0FFF) ⊻ tmp

        tmp = CRC_TABLE[((crc & 0x000F) ⊻ ((byte >> 4) & 0x0F)) + 1]
        crc = ((crc >> 4) & 0x0FFF) ⊻ tmp
    end
    return crc
end

@inline function extract_crc_le(data::AbstractVector{UInt8}, pos::Int)::UInt16
    return UInt16(data[pos]) | (UInt16(data[pos + 1]) << 8)
end

function validate_file_crc(data::AbstractVector{UInt8}, payload_end::Int)::Bool
    if payload_end + 2 > length(data)
        return false
    end
    expected = extract_crc_le(data, payload_end + 1)
    computed = calculate_crc(view(data, 1:payload_end))
    return computed == expected
end
