const FIT_EPOCH_OFFSET = 631065600

fit_seconds_to_datetime(seconds::UInt32) = Dates.unix2datetime(FIT_EPOCH_OFFSET + Int64(seconds))
