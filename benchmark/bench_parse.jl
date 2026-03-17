using FitAPI
using Printf

const SDK_DIR = normpath(joinpath(@__DIR__, "..", "data", "sdk"))

function sdk_fit_files()
    if !isdir(SDK_DIR)
        return String[]
    end
    return sort(filter(f -> endswith(lowercase(f), ".fit"), readdir(SDK_DIR; join=true)))
end

function bench_parse(; rounds::Int=5)
    files = sdk_fit_files()
    isempty(files) && error("No FIT files found under $(SDK_DIR)")

    println("Parse benchmark: $(length(files)) files, rounds=$(rounds)")
    println(rpad("file", 40), rpad("avg_ms", 12), "avg_records")

    for f in files
        total_t = 0.0
        total_records = 0
        for _ in 1:rounds
            t0 = time_ns()
            core = parsefit(f)
            total_t += (time_ns() - t0) / 1e6
            total_records += length(core.records)
        end
        @printf("%-40s %-12.3f %d\n", basename(f), total_t / rounds, Int(round(total_records / rounds)))
    end
end

bench_parse()
