# v0.1 Release Checklist

This checklist is for shipping FitAPI.jl `v0.1.0`.

## 1. Validate Repository State

- Ensure all intended changes are committed.
- Confirm no unrelated or temporary files are staged.
- Confirm `Project.toml` version is `0.1.0`.

## 2. Run Quality Gates

- Run full tests:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

- Run benchmark scripts and save output:

```bash
julia --project=. benchmark/bench_parse.jl
julia --project=. benchmark/bench_allocations.jl
```

- Compare benchmark outputs against documented baseline and guardrails.

### CI snippet (recommended)

Use separate steps so default correctness checks stay stable and perf checks remain explicitly opt-in:

```bash
# Standard suite
julia --project=. -e 'using Pkg; Pkg.test()'

# Optional perf guardrails
FITAPI_PERF_GUARDRAILS=1 julia --project=. test/runtests.jl
```

Notes:
- Run the perf guardrail step on dedicated runners to reduce variance.
- Keep thresholds aligned with `prompts/implementation_blueprint.md` section 10.2.

## 3. Verify Documentation

- `README.md` reflects current exported API.
- `docs/QUICKSTART.md` examples run without edits.
- `docs/API.md` signatures match current source.
- `docs/TROUBLESHOOTING.md` reflects current error behavior.

## 4. Tag And Release

Use annotated tag:

```bash
git tag -a v0.1.0 -m "FitAPI.jl v0.1.0"
git push origin v0.1.0
```

If a hosted release page is used, include:
- summary of parser capabilities
- supported high-level message groups
- benchmark baseline snapshot
- known limitations (for example current enum/scale/datetime decode coverage)

## 5. Post-Release

- Open `v0.1.x` bugfix tracking issue.
- Track parse/alloc regressions from CI and user fixtures.
- Start `v0.2` roadmap with profile coverage and additional typed messages.