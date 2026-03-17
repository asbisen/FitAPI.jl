function _fields_to_namedtuple(fields::Vector{DecodedField})
    d = Dict{Symbol,Any}()
    for field in fields
        d[field.name] = field.value
    end
    return (; d...)
end

function _merge_namedtuples(a::NamedTuple, b::NamedTuple)
    d = Dict{Symbol,Any}(pairs(a))
    for (k, v) in pairs(b)
        d[k] = v
    end
    return (; d...)
end

function to_table(fit::FitAnalysisResult; message::Symbol=:record, extras_policy::Symbol=:wide)
    entries = messages(fit; name=message)
    rows = NamedTuple[]

    if extras_policy == :long
        for msg in entries
            if isempty(msg.fields)
                push!(rows, (
                    message_name = msg.name,
                    global_message_number = msg.global_message_number,
                    field_name = missing,
                    field_num = missing,
                    type_name = missing,
                    units = "",
                    source = missing,
                    developer_data_index = missing,
                    raw_value = missing,
                    value = missing,
                ))
                continue
            end

            for field in msg.fields
                push!(rows, (
                    message_name = msg.name,
                    global_message_number = msg.global_message_number,
                    field_name = field.name,
                    field_num = field.field_num,
                    type_name = field.type_name,
                    units = field.units,
                    source = field.source,
                    developer_data_index = field.developer_data_index,
                    raw_value = field.raw_value,
                    value = field.value,
                ))
            end
        end
        return rows
    end

    for msg in entries
        base = (
            message_name = msg.name,
            global_message_number = msg.global_message_number,
        )
        if extras_policy == :wide
            push!(rows, _merge_namedtuples(base, _fields_to_namedtuple(msg.fields)))
        else
            push!(rows, base)
        end
    end

    return rows
end
