# Settings for Log, interacts with the ProjectSettings singleton. Note that these may take a tick or two to sync.



## Controls how the message should be formatted, follows String.format(), valid keys are: 
##  "level": the log level, aka debug, warning, FALTAL etc... 
##  "log_name": The name of the logger, which is the string passed into a LogStream on init or MAIN for Log methods.
##  "message": The message to print, aka Log.info("my message").
##  "values": Values or values to print, aka Log.info("my message", {"a": 1, "b": 2}).
##  "script": Script from which the log call is called.
##  "function": Function -||-
##  "line": Line -||-
##  "year": Year at which the log was printed, int
##  "month": Month -||-, int of 1-12
##  "day": Day -||-, int 1-31
##  "weekday": Weekday -||-, int 0-6 
##  "hour": Hour -||-, int 0-23?
##  "minute" Minute -||-, int 0-59
##  "second" Second -||-, int 0-59. Note that this may differ on a second or two since the time is get in the logger thread, which may not run for a couple of milliseconds.
##BBCode friendly, aka any BBCode may be inserted here.
const DEBUG_MESSAGE_FORMAT_DEFAULT_VALUE = "[color=dark_gray]{log_name}/{level} ({script}:{line}) [lb]{hour}:{minute}:{second}[rb] {message}[/color]{values}"
##The path within the ProjectSettings where this setting is stored.
const DEBUG_MESSAGE_FORMAT_KEY = "addons/Log/debug_message_format"

##Same as 'DEBUG_LOG_MESSAGE_FORMAT_KEY'.
const INFO_MESSAGE_FORMAT_DEFAULT_VALUE = "[color=white]{log_name}/{level} ({script}:{line}) [lb]{hour}:{minute}:{second}[rb] {message}[/color]{values}"
##The path within the ProjectSettings where this setting is stored.
const INFO_MESSAGE_FORMAT_KEY = "addons/Log/info_message_format"

##Same as 'DEBUG_LOG_MESSAGE_FORMAT_KEY'.
const WARNING_MESSAGE_FORMAT_DEFAULT_VALUE = "[color=gold]{log_name}/{level} ({script}:{line}) [lb]{hour}:{minute}:{second}[rb] {message}[/color]{values}"
##The path within the ProjectSettings where this setting is stored.
const WARNING_MESSAGE_FORMAT_KEY = "addons/Log/warning_message_format"

##Same as 'DEBUG_LOG_MESSAGE_FORMAT_KEY'
const ERROR_MESSAGE_FORMAT_DEFAULT_VALUE = "[color=red]{log_name}/{level} ({script}:{line}) [lb]{hour}:{minute}:{second}[rb] {message}[/color]{values}"
##The path within the ProjectSettings where this setting is stored.
const ERROR_MESSAGE_FORMAT_KEY = "addons/Log/error_message_format"

##Same as 'DEBUG_LOG_MESSAGE_FORMAT_KEY'
const FATAL_MESSAGE_FORMAT_DEFAULT_VALUE = "[color=red][u][b]{log_name}/{level} ({script}:{line}) [lb]{hour}:{minute}:{second}[rb] {message}[/b][/u][/color]{values}"
##The path within the ProjectSettings where this setting is stored.
const FATAL_MESSAGE_FORMAT_KEY = "addons/Log/fatal_message_format"

##Printed before potential values.
const VALUE_PRIMER_STRING_DEFAULT_VALUE = ", Value(s): "
const VALUE_PRIMER_STRING_KEY = "addons/Log/value_primer_string"

## Whether to use the UTC time or the user's local time.
const USE_UTC_TIME_FORMAT_KEY = "addons/Log/use_utc_time_format"
const USE_UTC_TIME_FORMAT_DEFAULT_VALUE = false

## Enables a breakpoint to mimic the godot behavior where the application doesn't crash when connected to debug environment, 
## but instead freezed and shows the stack etc in the debug panel.
const BREAK_ON_ERROR_KEY = "addons/Log/break_on_error"
const BREAK_ON_ERROR_DEFAULT_VALUE = true

##Whether to dump the tree to the log on error.
const PRINT_TREE_ON_ERROR_KEY = "addons/Log/print_tree_on_error"
const PRINT_TREE_ON_ERROR_DEFAULT_VALUE = false

##Controls the size of the log queue. Effectively the maximum amount of messages that can be logged in one batch (at the same time, effectively within one batch cycle).
const LOG_QUEUE_SIZE_KEY = "addons/Log/log_queue_size"
const LOG_QUEUE_SIZE_DEFAULT_VALUE = 128

##Controls the maximum time of thread sleeping between printing message batches, in ms.
const MIN_PRINTING_CYCLE_TIME_KEY = "addons/Log/min_printing_cycle_time"
const MIN_PRINTING_CYCLE_TIME_DEFAULT_VALUE = 5


##Controls where all the log streams are found within the project settings.
const STREAM_LEVEL_SETTING_LOCATION = "addons/Log/streams/"


static func _ensure_setting_exists(setting: String, default_value, property_info = {}) -> Variant:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, default_value)
		ProjectSettings.set_initial_value(setting, default_value)
		if ProjectSettings.has_method("set_as_basic"): # 4.0 backward compatibility
			ProjectSettings.call("set_as_basic", setting, true)
		if property_info.size()>0:
			property_info["name"] = setting
			ProjectSettings.add_property_info(property_info)
	return ProjectSettings.get_setting(setting)
