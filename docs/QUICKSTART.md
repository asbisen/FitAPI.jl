# Quickstart

This guide walks through the most common FitAPI.jl usage patterns.

## 1. Parse A FIT File

```julia
using FitAPI

fit = readfit("data/sdk/Activity.fit")
```

`readfit` performs:
- low-level parse
- profile-aware high-level decode
- grouping by logical message name from the FIT global profile

## 2. Access Message Buckets

```julia
records = messages(fit; name=:record)
laps = messages(fit; name=:lap)
unknown = messages(fit; name=:unknown)

record = first(records)
fieldvalue(record, :timestamp)
fieldvalue(record, :distance)
```

`messages(fit; name=:unknown)` is an aggregate over any messages that are not present in the loaded global profile.

## 3. Convert Records To A Table

```julia
rows_wide = to_table(fit; message=:record, extras_policy=:wide)
rows_long = to_table(fit; message=:record, extras_policy=:long)
```

Use `:wide` when you want one row per record and dynamic extra columns.
Use `:long` when you want one row per decoded field, including raw value, units, source, and developer metadata.

## 4. Low-Level Parse Flow

```julia
core = parsefit("data/sdk/Activity.fit")

for msg in eachmessage("data/sdk/Activity.fit")
    # msg is a DefinitionMessage or DataMessage
end
```

Use this when you need strict control over raw message handling.

## 5. Common Parser Options

```julia
opts = ParserOptions(validate_crc=true, strict=true, enable_logging=false)
fit = readfit("data/sdk/Activity.fit"; options=opts)
```

## 6. Decode Controls

```julia
decode = DecodeOptions(
    process_invalids=true,
    decode_enums=true,
    apply_scale_offset=true,
    convert_datetime=true,
)

fit = readfit("data/sdk/Activity.fit"; decode=decode)
```

## 7. Next Steps

- For complete signatures and return types, see [API.md](API.md)
- For operational issues and malformed input behavior, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)