const PROFILE_PATH = normpath(joinpath(@__DIR__, "..", "profile.msg"))

struct ProfileConditionGroup
	field_num::UInt8
	raw_values::Vector{Int64}
end

struct ProfileSubFieldDef
	name::Symbol
	type_name::Symbol
	units::String
	scale::Float64
	offset::Float64
	apply_transform::Bool
	array::Bool
	enum_map::Dict{Int64,Symbol}
	conditions::Vector{ProfileConditionGroup}
end

struct ProfileFieldDef
	num::UInt8
	name::Symbol
	type_name::Symbol
	units::String
	scale::Float64
	offset::Float64
	apply_transform::Bool
	array::Bool
	enum_map::Dict{Int64,Symbol}
	sub_fields::Vector{ProfileSubFieldDef}
end

struct ProfileMessageDef
	num::UInt16
	name::Symbol
	fields::Dict{UInt8,ProfileFieldDef}
end

struct FitProfileCache
	messages::Dict{UInt16,ProfileMessageDef}
end

@inline _profile_symbol(value) = Symbol(String(value))

function _parse_profile_int(value)::Int64
	if value isa Integer
		return Int64(value)
	elseif value isa AbstractFloat
		return round(Int64, value)
	elseif value isa AbstractString
		s = strip(value)
		if startswith(lowercase(s), "0x")
			return parse(Int64, s[3:end]; base=16)
		end
		return parse(Int64, s)
	end
	throw(ArgumentError("Unsupported profile integer value: $(typeof(value))"))
end

function _normalize_units(units)::String
	if units isa AbstractString
		return String(units)
	elseif units isa AbstractVector
		normalized = String[]
		for unit in units
			text = strip(String(unit))
			isempty(text) && continue
			text in normalized || push!(normalized, text)
		end
		return isempty(normalized) ? "" : first(normalized)
	end
	return ""
end

function _extract_affine(values, default::Float64)
	if values isa Number
		return Float64(values), true
	elseif values isa AbstractVector
		numeric = Float64[]
		for value in values
			value isa Number || continue
			push!(numeric, Float64(value))
		end
		isempty(numeric) && return default, false
		unique_values = unique(numeric)
		return length(unique_values) == 1 ? (only(unique_values), true) : (default, false)
	end
	return default, false
end

function _load_enum_maps(raw_types)::Dict{Symbol,Dict{Int64,Symbol}}
	enum_maps = Dict{Symbol,Dict{Int64,Symbol}}()
	for (type_name, raw_mapping) in raw_types
		mapping = Dict{Int64,Symbol}()
		if raw_mapping isa AbstractDict
			for (raw_value, label) in raw_mapping
				mapping[_parse_profile_int(raw_value)] = _profile_symbol(label)
			end
		end
		enum_maps[_profile_symbol(type_name)] = mapping
	end
	return enum_maps
end

function _build_condition_groups(raw_map)
	grouped = Dict{UInt8,Vector{Int64}}()
	if raw_map isa AbstractVector
		for entry in raw_map
			entry isa AbstractDict || continue
			field_num = UInt8(_parse_profile_int(entry["num"]))
			values = get!(grouped, field_num) do
				Int64[]
			end
			push!(values, _parse_profile_int(entry["raw_value"]))
		end
	end

	groups = ProfileConditionGroup[]
	for field_num in sort!(collect(keys(grouped)))
		push!(groups, ProfileConditionGroup(field_num, unique(grouped[field_num])))
	end
	return groups
end

function _build_subfield(raw_subfield, enum_maps)::ProfileSubFieldDef
	type_name = _profile_symbol(raw_subfield["type"])
	scale, has_scale = _extract_affine(raw_subfield["scale"], 1.0)
	offset, has_offset = _extract_affine(raw_subfield["offset"], 0.0)
	return ProfileSubFieldDef(
		_profile_symbol(raw_subfield["name"]),
		type_name,
		_normalize_units(raw_subfield["units"]),
		scale,
		offset,
		has_scale && has_offset,
		raw_subfield["array"] === true || raw_subfield["array"] == "true",
		get(enum_maps, type_name, Dict{Int64,Symbol}()),
		_build_condition_groups(raw_subfield["map"]),
	)
end

function _build_field(raw_field, enum_maps)::ProfileFieldDef
	type_name = _profile_symbol(raw_field["type"])
	scale, has_scale = _extract_affine(raw_field["scale"], 1.0)
	offset, has_offset = _extract_affine(raw_field["offset"], 0.0)
	sub_fields = ProfileSubFieldDef[]
	for raw_subfield in raw_field["sub_fields"]
		push!(sub_fields, _build_subfield(raw_subfield, enum_maps))
	end
	return ProfileFieldDef(
		UInt8(_parse_profile_int(raw_field["num"])),
		_profile_symbol(raw_field["name"]),
		type_name,
		_normalize_units(raw_field["units"]),
		scale,
		offset,
		has_scale && has_offset,
		raw_field["array"] === true || raw_field["array"] == "true",
		get(enum_maps, type_name, Dict{Int64,Symbol}()),
		sub_fields,
	)
end

function _build_message(message_num, raw_message, enum_maps)::ProfileMessageDef
	fields = Dict{UInt8,ProfileFieldDef}()
	for raw_field in values(raw_message["fields"])
		field = _build_field(raw_field, enum_maps)
		fields[field.num] = field
	end
	return ProfileMessageDef(UInt16(_parse_profile_int(message_num)), _profile_symbol(raw_message["name"]), fields)
end

function _load_profile_cache(path::AbstractString)::FitProfileCache
	isfile(path) || throw(error("Unable to load profile.msg at $path"))
	raw_profile = MsgPack.unpack(read(path))
	enum_maps = _load_enum_maps(raw_profile["types"])

	messages = Dict{UInt16,ProfileMessageDef}()
	for (message_num, raw_message) in raw_profile["messages"]
		message = _build_message(message_num, raw_message, enum_maps)
		messages[message.num] = message
	end
	return FitProfileCache(messages)
end

const PROFILE = _load_profile_cache(PROFILE_PATH)
