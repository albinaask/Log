@tool
extends Node
##Class that handles all the logging in the addon, methods can either be accessed through
##the "GodotLogger" singelton, or you can instance this class yourself(no need to add it to the tree)

class_name LogStream

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
func debug(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.DEBUG, current_log_level, _crash_behavior, log_message.emit, values)

##Shorthand for debug
func dbg(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.DEBUG, current_log_level, _crash_behavior, log_message.emit, values)

##prints a message to the log at the info level.
func info(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.INFO, current_log_level, _crash_behavior, log_message.emit, values)

##prints a message to the log at the warning level.
func warn(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.WARN, current_log_level, _crash_behavior, log_message.emit, values)

##Prints a message to the log at the error level.
func error(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, values)

##Shorthand for error
func err(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, values)

##Prints a message to the log at the fatal level, exits the application 
##since there has been a fatal error.
func fatal(message:String,values:Variant=null):
	_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.FATAL, current_log_level, _crash_behavior, log_message.emit, values)

##Throws an error if err_code is not of value "OK" and appends the error code string.
func err_cond_not_ok(err_code:Error, message:String, fatal:=true, other_values_to_be_printed=null):
	if err_code != OK:
		_LogInternalPrinter._push_to_queue(_log_name, message + "" if message.ends_with(".") else "." + " Error string: " + error_string(err_code), LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if the "statement" passed is false. Handy for making code "free" from if statements.
func err_cond_false(statement:bool, message:String, fatal:=true, other_values_to_be_printed={}):
	if !statement:
		_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if argument == null
func err_cond_null(arg, message:String, fatal:=true, other_values_to_be_printed=null):
	if arg == null:
			_LogInternalPrinter._push_to_queue(_log_name, message, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)

##Throws an error if the arg1 isn't equal to arg2. Handy for making code "free" from if statements.
func err_cond_not_equal(arg1, arg2, message:String, fatal:=true, other_values_to_be_printed=null):
	#The type 'Color' is weird in godot, so therefore this edgecase...
	if (arg1 is Color && arg2 is Color && !arg1.is_equal_approx(arg2)) || arg1 != arg2:
		_LogInternalPrinter._push_to_queue(_log_name, str(arg1) + " != " + str(arg2) + ", not allowed. " + message, LogLevel.FATAL if fatal else LogLevel.ERROR, current_log_level, _crash_behavior, log_message.emit, other_values_to_be_printed)	

##Internal method.
func _set_level(level:LogLevel):
	level = _get_external_log_level() if level == -1 else level
	info("setting log level to " + LogLevel.keys()[level])
	current_log_level = level

##Internal method.
func _get_external_log_level()->LogLevel:
	var cmd_line_level = Config.get_var("log-level","default").to_upper()
	var project_settings_level = ProjectSettings.get_setting(_LogInternalPrinter._settings.STREAM_LEVEL_SETTING_LOCATION+_log_name)
	if cmd_line_level.to_lower() != "default":
		if LogLevel.keys().has(cmd_line_level.to_upper()):
			return LogLevel[cmd_line_level]
		else:
			warn("The variable log-level is set to an illegal type, defaulting to info")
			return LogLevel.INFO
	else:
		return project_settings_level


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
		"",
		settings._ensure_setting_exists(settings.DEBUG_MESSAGE_FORMAT_KEY, settings.DEBUG_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.INFO_MESSAGE_FORMAT_KEY, settings.INFO_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.WARNING_MESSAGE_FORMAT_KEY, settings.WARNING_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.ERROR_MESSAGE_FORMAT_KEY, settings.ERROR_MESSAGE_FORMAT_DEFAULT_VALUE),
		settings._ensure_setting_exists(settings.FATAL_MESSAGE_FORMAT_KEY, settings.FATAL_MESSAGE_FORMAT_DEFAULT_VALUE)
	]

##Controls the behavior when a fatal error has been logged. 
##Edit to customize the behavior.
static func default_crash_behavior():
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
