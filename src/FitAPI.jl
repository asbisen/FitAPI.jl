module FitAPI

using Dates
using Logging
using MsgPack

include("config/options.jl")
include("config/logging.jl")

include("utils/errors.jl")
include("utils/time.jl")

include("io/bytereader.jl")
include("io/crc.jl")

include("fit/types.jl")
include("fit/profile.jl")
include("fit/definitions.jl")
include("fit/decoder.jl")
include("fit/parser.jl")

include("model/messages.jl")
include("model/records.jl")

include("api/lowlevel.jl")
include("api/highlevel.jl")
include("api/tables.jl")

export ParserOptions, DecodeOptions
export DecodedField, DecodedMessage
export fieldvalue, fieldraw, findfield
export readfit, parsefit, eachmessage, messages, to_table

end
