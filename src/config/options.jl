Base.@kwdef struct ParserOptions{L}
    enable_logging::Bool = false
    log_level::Symbol = :warn
    logger::L = nothing
    strict::Bool = true
    validate_crc::Bool = true
end

Base.@kwdef struct DecodeOptions
    process_invalids::Bool = true
    decode_enums::Bool = true
    apply_scale_offset::Bool = true
    convert_datetime::Bool = true
end
