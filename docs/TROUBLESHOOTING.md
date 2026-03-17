# Troubleshooting

## `FitFormatError`: malformed FIT stream

Example:

```text
FitFormatError(offset=...): ...
```

Typical causes:
- non-FIT file input
- truncated payload
- data message encountered before local definition is set
- invalid FIT header size

What to do:
- verify source file is a valid `.fit` file
- compare file size with expected transfer size
- if parsing from `IO`, ensure the stream starts at byte 1

## `FitChecksumError`: CRC mismatch

Example:

```text
FitChecksumError(expected=..., actual=...)
```

Typical causes:
- file corruption
- partial writes/downloads
- post-processing changed bytes without CRC update

What to do:
- reacquire the FIT file from source
- keep `ParserOptions(validate_crc=true)` for integrity checks
- for debugging only, temporarily set `validate_crc=false` to inspect partial content

## `messages(...; name=...)` returns empty

Typical causes:
- requested bucket does not exist in that file
- name mismatch (`"record"` vs `:record`)

What to do:

```julia
fit = readfit("data/sdk/Activity.fit")
keys(fit.by_name)
```

Use one of the existing keys.

## Missing columns in `to_table(...; extras_policy=:wide)`

This is expected when a field is absent in the source activity.

FIT schemas vary by:
- sport
- device
- recording mode
- sensor availability

For sparse feature exploration, prefer:

```julia
to_table(fit; message=:record, extras_policy=:long)
```

## Performance appears slower than baseline

Checks:
- run Julia with project active: `julia --project=.`
- run benchmarks on local machine with low background load
- compare the same fixture set and same benchmark rounds

Current baseline is recorded in [../prompts/implementation_blueprint.md](../prompts/implementation_blueprint.md).