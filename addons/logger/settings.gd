# Settings

## Controls how the message should be formatted, follows String.format(), valid keys are: "level", "time", "log_name", "message"
const LOG_MESSAGE_FORMAT_KEY := "addons/logger/log_message_format"
const LOG_MESSAGE_FORMAT_DEFAULT_VALUE := "{log_name}/{level} [lb]{hour}:{minute}:{second}[rb] {message}"

## Whether to use the UTC time or the user
const USE_UTC_TIME_FORMAT_KEY := "addons/logger/use_utc_time_format"
const USE_UTC_TIME_FORMAT_DEFAULT_VALUE := false

## Enables a breakpoint to mimic the godot behavior where the application doesn't crash when connected to debug environment, 
## but instead freezed and shows the stack etc in the debug panel.
const BREAK_ON_ERROR_KEY := "addons/logger/break_on_error"
const BREAK_ON_ERROR_DEFAULT_VALUE := true
