const LOG_LEVEL_MAP = Dict{Symbol,Logging.LogLevel}(
    :debug => Logging.Debug,
    :info => Logging.Info,
    :warn => Logging.Warn,
    :error => Logging.Error,
)

@inline function should_log(opts::ParserOptions, level::Symbol)::Bool
    opts.enable_logging || return false
    target_level = get(LOG_LEVEL_MAP, opts.log_level, Logging.Warn)
    msg_level = get(LOG_LEVEL_MAP, level, Logging.Info)
    return msg_level >= target_level
end

@inline function logparse(opts::ParserOptions, level::Symbol, builder::Function)
    should_log(opts, level) || return nothing
    msg = builder()
    if opts.logger === nothing
        @logmsg get(LOG_LEVEL_MAP, level, Logging.Info) msg
    else
        opts.logger(level, msg)
    end
    return nothing
end
