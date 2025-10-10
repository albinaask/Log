@tool
extends Node
##Class that handles all the logging in the addon, methods can either be accessed through
##the "GodotLogger" singelton, or you can instance this class yourself(no need to add it to the tree)

class_name LogStream

# Preload once so log level resolution works even if LogConfig is not yet in the cache; mirrors the `_settings` naming style.
const _log_config := preload("res://addons/logger/LogConfig.gd")

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	FATAL= 4,
}

var _log_name:String
var _crash_behavior:Callable

##Emits this signal whenever a message is recieved.
signal log_message(level:LogLevel,message:String)

##Represents the minimum level of messages that will be logged.
var current_log_level:LogLevel = LogLevel.INFO:set= _set_level


## Constructor for the LogStream.
##
## The parameters are:
##
## - `log_name`: The name of the logger. This is used to identify the logger in the log output.
## - `min_log_level`: The minimum level of messages that will be logged. Defaults to -1, this causes the stream to use either the one found in the project settings, environment variable or the command line.
## - `crash_behavior`: A Callable that is called when a fatal error is encountered. Defaults to default_crash_behavior. Takes no arguments.
func _init(log_name:String, min_log_level:LogLevel=-1, crash_behavior:Callable = default_crash_behavior):
	_log_name = log_name
	_LogInternalPrinter._settings._ensure_setting_exists(_LogInternalPrinter._settings.STREAM_LEVEL_SETTING_LOCATION+_log_name, LogLevel.INFO,
	{
		"type":TYPE_INT,
		"hint":PROPERTY_HINT_ENUM,
		"hint_string":LogLevel.keys().reduce(func(a,b):return a + ", " + b).to_lower()
	})
	current_log_level = min_log_level
	_crash_behavior = crash_behavior

func _ready() -> void:
	if !get_tree().root.tree_exiting.is_connected(_LogInternalPrinter._cleanup):
		get_tree().root.tree_exiting.connect(_LogInternalPrinter._cleanup)

##prints a message to the log at the debug level.
func debug(message:Variant,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, str(message), LogLevel.DEBUG, current_log_level, _crash_behavior, log_message.emit, values)

func debugs(...params):
	debug(str.callv(params))

##Shorthand for debug
func dbg(message:Variant,values:Variant=null):
	debug(message,values)

func dbgs(...params):
	debug(str.callv(params))

##prints a message to the log at the info level.
func info(message:Variant,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, str(message), LogLevel.INFO, current_log_level, _crash_behavior, log_message.emit, values)

func infos(...params):
	info(str.callv(params))

##prints a message to the log at the warning level.
func warn(message:Variant,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, str(message), LogLevel.WARN, current_log_level, _crash_behavior, log_message.emit, values)

func warns(...params):
	warn(str.callv(params))

##Prints a message to the log at the error level.
func error(message:Variant,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, str(message), LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, values)

func errors(...params):
	error(str.callv(params))

##Shorthand for error
func err(message:String,values:Variant=null):
	error(message,values)

func errs(...params):
	error(str.callv(params))

##Prints a message to the log at the fatal level, exits the application 
##since there has been a fatal error.
func fatal(message:Variant,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, str(message), LogLevel.FATAL, current_log_level, _crash_behavior, log_message.emit, values)

func fatals(...params):
	fatal(str.callv(params))

##Throws an error if err_code is not of value "OK" and appends the error code string.
func err_cond_not_ok(err_code:Error, message_on_err:String, fatal:=true, other_values_to_be_printed=null):
	if err_code != OK:
		_LogInternalPrinter._push_to_queue(_log_name, message_on_err + "" if message_on_err.ends_with(".") else "." + " Error string: " + error_string(err_code), LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if the "statement" passed is false. Handy for making code "free" from if statements.
func err_cond_false(statement:bool, message_on_err:String, fatal:=true, other_values_to_be_printed={}):
	if !statement:
		_LogInternalPrinter._push_to_queue(_log_name, message_on_err, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if argument == null
func err_cond_null(arg, message_on_err:String, fatal:=true, other_values_to_be_printed=null):
	if arg == null:
			_LogInternalPrinter._push_to_queue(_log_name, message_on_err, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if the arg1 isn't equal to arg2. Handy for making code "free" from if statements.
func err_cond_not_equal(arg1, arg2, message_on_err:String, fatal:=true, other_values_to_be_printed=null):
	#The type 'Color' is weird in godot, so therefore this edgecase...
	if (arg1 is Color && arg2 is Color && !arg1.is_equal_approx(arg2)) || arg1 != arg2:
		_LogInternalPrinter._push_to_queue(_log_name, str(arg1) + " != " + str(arg2) + ", not allowed. " + message_on_err, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)	

##Internal method.
func _set_level(level:LogLevel):
	var resolved_level := level
	if level == -1:
		# -1 is the "inherit from settings" sentinel; resolve it before logging.
		resolved_level = _log_config.get_external_log_level(_log_name, LogLevel.INFO)
	if resolved_level < 0 or resolved_level >= LogLevel.keys().size():
		# Guard against unexpected values so the log never prints bogus levels.
		resolved_level = LogLevel.INFO
	info("setting log level to " + LogLevel.keys()[resolved_level])
	current_log_level = resolved_level


#make sure settings are synced without pulling them all the time. Not that this can take a tick or so.
static func sync_project_settings()->void:
	var settings = _LogInternalPrinter._settings
	_LogInternalPrinter.BREAK_ON_ERROR = ProjectSettings.get_setting(settings.BREAK_ON_ERROR_KEY)
	_LogInternalPrinter.PRINT_TREE_ON_ERROR = ProjectSettings.get_setting(settings.PRINT_TREE_ON_ERROR_KEY)
	_LogInternalPrinter.CYCLE_BREAK_TIME = ProjectSettings.get_setting(settings.MIN_PRINTING_CYCLE_TIME_KEY)
	_LogInternalPrinter.USE_UTC_TIME_FORMAT = ProjectSettings.get_setting(settings.USE_UTC_TIME_FORMAT_KEY)
	_LogInternalPrinter.VALUE_PRIMER_STRING = settings._ensure_setting_exists(settings.VALUE_PRIMER_STRING_KEY, settings.VALUE_PRIMER_STRING_DEFAULT_VALUE)
	#See _LogInternalPrinter.MESSAGE_FORMAT_STRINGS for details.
	_LogInternalPrinter.MESSAGE_FORMAT_STRINGS = [
		settings._ensure_setting_exists(settings.DEBUG_MESSAGE_FORMAT_KEY, settings.DEBUG_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.INFO_MESSAGE_FORMAT_KEY, settings.INFO_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.WARNING_MESSAGE_FORMAT_KEY, settings.WARNING_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.ERROR_MESSAGE_FORMAT_KEY, settings.ERROR_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.FATAL_MESSAGE_FORMAT_KEY, settings.FATAL_MESSAGE_FORMAT_DEFAULT_VALUE)
	]

##Controls the behavior when a fatal error has been logged. 
##Edit to customize the default behavior.
static func default_crash_behavior()->void:
	#Joins the logging thread(aka waits for it to log all messages that are in the queue) onto the main thread, and cleans up the logging thread.
	_LogInternalPrinter._cleanup()
	print("Crashing due to Fatal error.")
	#Restart the process to the main scene. (Uncomment if wanted), 
	#note that we don't want to restart if we crash on init, then we get stuck in an infinite crash-loop, which isn't fun for anyone. 
	#if get_tree().get_frame()>0:
	#	var _ret = OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	
	#Choose crash mechanism. Difference is that get_tree().quit() quits at the end of the frame, 
	#enabling multiple fatal errors to be cast, printing multiple stack traces etc. 
	#Warning regarding the use of OS.crash() in the docs can safely be regarded in this case.
	OS.crash("Crash since falal error ocurred")
	#get_tree().quit(-1)


#Class for lobbing around logging data between the main thread and the logging thread.
class LogEntry:
	##The level of the message
	var message_level:LogStream.LogLevel
	##The 'raw' log message
	var message:String
	##The name of the stream
	var stream_name:String
	##The call stack of the log entry.
	var stack:Array
	##A crash_behaviour callback. This will be called upon a fatal error.
	var crash_behaviour:Callable
	## The values that may be attached to the log message.
	var values
