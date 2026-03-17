using FitAPI
using Printf

const SDK_DIR = normpath(joinpath(@__DIR__, "..", "data", "sdk"))

function sdk_fit_files()
    if !isdir(SDK_DIR)
        return String[]
    end
    return sort(filter(f -> endswith(lowercase(f), ".fit"), readdir(SDK_DIR; join=true)))
end

function bench_allocations()
    files = sdk_fit_files()
    isempty(files) && error("No FIT files found under $(SDK_DIR)")

    println("Allocation benchmark")
    println(rpad("file", 40), rpad("parse_bytes", 14), rpad("readfit_bytes", 14), "record_rows")

    for f in files
        parse_alloc = @allocated parsefit(f)
        analysis = readfit(f)
        read_alloc = @allocated readfit(f)
        rows = to_table(analysis; message=:record, extras_policy=:wide)
        @printf("%-40s %-14d %-14d %d\n", basename(f), parse_alloc, read_alloc, length(rows))
    end
end

bench_allocations()
