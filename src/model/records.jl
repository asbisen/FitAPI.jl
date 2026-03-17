function findfield(msg::DecodedMessage, name::Symbol)
    for field in msg.fields
        field.name === name && return field
    end
    return nothing
end

function findfield(msg::DecodedMessage, field_num::UInt8)
    for field in msg.fields
        field.field_num == field_num && return field
    end
    return nothing
end

@inline fieldvalue(field::DecodedField) = field.value
@inline fieldraw(field::DecodedField) = field.raw_value

function fieldvalue(msg::DecodedMessage, name::Symbol)
    field = findfield(msg, name)
    return isnothing(field) ? missing : field.value
end

function fieldvalue(msg::DecodedMessage, field_num::UInt8)
    field = findfield(msg, field_num)
    return isnothing(field) ? missing : field.value
end

function fieldraw(msg::DecodedMessage, name::Symbol)
    field = findfield(msg, name)
    return isnothing(field) ? missing : field.raw_value
end

function fieldraw(msg::DecodedMessage, field_num::UInt8)
    field = findfield(msg, field_num)
    return isnothing(field) ? missing : field.raw_value
end
