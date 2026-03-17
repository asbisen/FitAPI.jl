messages(core::FitCoreResult, ::Type{T}) where {T} = [m for m in core.records if m isa T]

function messages(fit::FitAnalysisResult, ::Type{T}) where {T}
    out = T[]
    for v in values(fit.by_name)
        for item in v
            if item isa T
                push!(out, item)
            end
        end
    end
    return out
end

function messages(fit::FitAnalysisResult; name)
    key = if name isa Symbol
        name
    elseif name isa AbstractString
        Symbol(name)
    else
        throw(ArgumentError("name must be a Symbol or AbstractString"))
    end
    if key == :unknown
        out = DecodedMessage[]
        for (message_name, items) in fit.by_name
            startswith(String(message_name), "unknown_msg_") || continue
            append!(out, items)
        end
        return out
    end
    return get(fit.by_name, key, DecodedMessage[])
end
