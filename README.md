# FitAPI.jl

FitAPI.jl is a Julia package for reading Garmin FIT files with a type-stable core parser and an ergonomic high-level analysis API.

## Highlights

- Fast low-level parsing via `parsefit` and `eachmessage`
- High-level semantic decode via `readfit`
- Table-friendly output via `to_table` (Tables.jl compatible)
- Unknown and developer fields preserved for exploratory workflows
- Optional CRC validation and strict format checks

## Installation

From a local checkout:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

From another Julia environment pointing to this path:

```julia
using Pkg
Pkg.add(path="/absolute/path/to/FitAPI.jl")
```

## Quickstart

```julia
using FitAPI

# High-level parse + semantic decode
fit = readfit("data/sdk/Activity.fit")

# Pull record messages and inspect decoded profile-backed fields
record = first(messages(fit; name=:record))
fieldvalue(record, :distance)

# Convert to a table-like vector of NamedTuple
rows = to_table(fit; message=:record, extras_policy=:wide)
first(rows)
```

## Core APIs

- `parsefit(path_or_io; options=ParserOptions())`
- `eachmessage(path_or_io; options=ParserOptions())`
- `readfit(path_or_io; options=ParserOptions(), decode=DecodeOptions())`
- `messages(fitobj, ::Type{T})`
- `messages(fitobj; name::Symbol)`
- `fieldvalue(msg, name)` / `fieldraw(msg, name)`
- `to_table(fitobj; message=:record, extras_policy=:wide)`

## Documentation

- [Quickstart](docs/QUICKSTART.md)
- [API Reference](docs/API.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [v0.1 Release Checklist](docs/RELEASE_CHECKLIST_v0.1.md)

## Development

Run tests:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Run benchmarks:

```bash
julia --project=. benchmark/bench_parse.jl
julia --project=. benchmark/bench_allocations.jl
```