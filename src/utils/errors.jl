abstract type FitError <: Exception end

struct FitFormatError <: FitError
    msg::String
    offset::Int64
end

struct FitChecksumError <: FitError
    expected::UInt16
    actual::UInt16
end

struct FitNotImplementedError <: FitError
    msg::String
end

Base.showerror(io::IO, e::FitFormatError) = print(io, "FitFormatError(offset=", e.offset, "): ", e.msg)
Base.showerror(io::IO, e::FitChecksumError) = print(io, "FitChecksumError(expected=", e.expected, ", actual=", e.actual, ")")
Base.showerror(io::IO, e::FitNotImplementedError) = print(io, "FitNotImplementedError: ", e.msg)
