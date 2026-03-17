# API Reference

## Exported Types

## `DecodedMessage`

High-level profile-backed message container returned by `readfit`.

```julia
struct DecodedMessage
    global_message_number::UInt16
    name::Symbol
    fields::Vector{DecodedField}
end
```

## `DecodedField`

Decoded field container produced from the FIT global profile.

```julia
struct DecodedField
    field_num::UInt8
    developer_data_index::Union{Nothing,UInt8}
    name::Symbol
    type_name::Symbol
    units::String
    raw_value
    value
    source::Symbol
end
```

## `ParserOptions`

```julia
Base.@kwdef struct ParserOptions{L}
    enable_logging::Bool = false
    log_level::Symbol = :warn
    logger::L = nothing
    strict::Bool = true
    validate_crc::Bool = true
end
```

- `enable_logging`: enable parse logging hooks
- `log_level`: requested log level
- `logger`: optional logger sink object
- `strict`: strict parse mode (reserved for parser behavior controls)
- `validate_crc`: validate trailing FIT file CRC when present

## `DecodeOptions`

```julia
Base.@kwdef struct DecodeOptions
    process_invalids::Bool = true
    decode_enums::Bool = true
    apply_scale_offset::Bool = true
    convert_datetime::Bool = true
end
```

These control high-level decode behavior used by `readfit`.

## Exported Functions

## `parsefit`

```julia
parsefit(path::AbstractString; options::ParserOptions=ParserOptions())
parsefit(io::IO; options::ParserOptions=ParserOptions())
```

Returns a `FitCoreResult` containing raw parsed records.

Behavior notes:
- parsing is bounded by `header.data_size`
- validates file CRC in path mode when CRC bytes are present and `validate_crc=true`
- throws FIT-specific errors for malformed inputs

## `eachmessage`

```julia
eachmessage(path::AbstractString; options::ParserOptions=ParserOptions())
eachmessage(io::IO; options::ParserOptions=ParserOptions())
```

Returns an iterator over parsed core records.

## `readfit`

```julia
readfit(path_or_io;
    options::ParserOptions=ParserOptions(),
    decode::DecodeOptions=DecodeOptions(),
    materialize::Bool=true)
```

Returns `FitAnalysisResult` with grouped decoded messages in `by_name`:
- known FIT profile names such as `:record`, `:lap`, `:session`, `:event`, `:file_id`
- unknown messages grouped under synthetic names like `:unknown_msg_250`

## `messages`

```julia
messages(core::FitCoreResult, ::Type{T}) where {T}
messages(fit::FitAnalysisResult, ::Type{T}) where {T}
messages(fit::FitAnalysisResult; name)
```

Use `name` as `Symbol` or `AbstractString` for bucket access.

Special case:
- `messages(fit; name=:unknown)` aggregates all unknown synthetic message buckets

## `fieldvalue` / `fieldraw`

```julia
fieldvalue(msg::DecodedMessage, name::Symbol)
fieldvalue(msg::DecodedMessage, field_num::UInt8)
fieldraw(msg::DecodedMessage, name::Symbol)
fieldraw(msg::DecodedMessage, field_num::UInt8)
findfield(msg::DecodedMessage, name::Symbol)
findfield(msg::DecodedMessage, field_num::UInt8)
```

These are the primary accessors for decoded messages:
- `fieldvalue` returns the human-friendly decoded value
- `fieldraw` returns the raw parser value before profile transforms
- `findfield` returns the full `DecodedField` or `nothing`

## `to_table`

```julia
to_table(fit::FitAnalysisResult; message::Symbol=:record, extras_policy::Symbol=:wide)
```

Returns `Vector{NamedTuple}` compatible with Tables.jl.

`message` should be any decoded message name, typically one returned by `keys(fit.by_name)`.

`extras_policy` behavior:
- `:wide`: one row per message with decoded fields merged into columns
- `:long`: one row per decoded field with message metadata, source, units, raw value, and decoded value

## Core Return Containers (Non-exported but useful)

- `FitCoreResult`: low-level parse output (`header`, `records`)
- `FitAnalysisResult`: high-level grouped output (`header`, `by_name`)

## Error Types

Defined in `src/utils/errors.jl`:
- `FitFormatError`
- `FitChecksumError`
- `FitNotImplementedError`

These are currently not exported. Access as `FitAPI.FitFormatError`, etc.