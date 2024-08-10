@tool
extends Node
##Class that handles all the logging in the addon, methods can either be accessed through
##the "GodotLogger" singelton, or you can instance this class yourself(no need to add it to the tree)

class_name LogStream

const settings := preload("./settings.gd")

enum LogLevel {
	DEFAULT,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL,
}

var current_log_level:LogLevel = LogLevel.INFO:set= _set_level
var _log_name:String
var _print_action:Callable
var _crash_behavior

static var _log_file:FileAccess
static var initialized = false

##Emits this signal whenever a message is recieved.
signal log_message(level:LogLevel,message:String)


static func _static_init() -> void:
	_ensure_setting_exists(settings.LOG_MESSAGE_FORMAT_KEY, settings.LOG_MESSAGE_FORMAT_DEFAULT_VALUE)
	_ensure_setting_exists(settings.USE_UTC_TIME_FORMAT_KEY, settings.USE_UTC_TIME_FORMAT_DEFAULT_VALUE)
	_ensure_setting_exists(settings.BREAK_ON_ERROR_KEY, settings.BREAK_ON_ERROR_DEFAULT_VALUE)
	_ensure_setting_exists(settings.PRINT_TREE_ON_ERROR_KEY, settings.PRINT_TREE_ON_ERROR_DEFAULT_VALUE)

func _init(log_name:String, min_log_level:=LogLevel.DEFAULT, crash_behavior:Callable = default_crash_behavior):
	_log_name = log_name
	current_log_level = min_log_level
	_crash_behavior = crash_behavior

##prints a message to the log at the debug level.
func debug(message, values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.DEBUG)

##Shorthand for debug
func dbg(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.DEBUG)

##prints a message to the log at the info level.
func info(message:String,values={}):
	call_thread_safe("_internal_log", message, values)

##prints a message to the log at the warning level.
func warn(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.WARN)

##Prints a message to the log at the error level.
func error(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.ERROR)

##Shorthand for error
func err(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.ERROR)

##Prints a message to the log at the fatal level, exits the application 
##since there has been a fatal error.
func fatal(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.FATAL)

##Throws an error if err_code is not of value "OK" and appends the error code string.
func err_cond_not_ok(err_code:Error, message:String, fatal:=true, other_values_to_be_printed={}):
	if err_code != OK:
		call_thread_safe("_internal_log", message + "" if message.ends_with(".") else "." + " Error string: " + error_string(err_code), other_values_to_be_printed, LogLevel.FATAL if fatal else LogLevel.ERROR)

##Throws an error if the "statement" passed is false. Handy for making code "free" from if statements.
func err_cond_false(statement:bool, message:String, fatal:=true, other_values_to_be_printed={}):
	if !statement:
		call_thread_safe("_internal_log", message, other_values_to_be_printed, LogLevel.FATAL if fatal else LogLevel.ERROR)

##Throws an error if argument == null
func err_cond_null(arg, message:String, fatal:=true, other_values_to_be_printed={}):
	if arg == null:
		call_thread_safe("_internal_log", message, other_values_to_be_printed, LogLevel.FATAL if fatal else LogLevel.ERROR)

##Throws an error if the arg1 isn't equal to arg2. Handy for making code "free" from if statements.
func err_cond_not_equal(arg1, arg2, message:String, fatal:=true, other_values_to_be_printed={}):
	#the type Color is weird in godot, so therefore this edgecase...
	if (arg1 is Color && arg2 is Color && !arg1.is_equal_approx(arg2)) || arg1 != arg2:
		call_thread_safe("_internal_log", str(arg1) + " != " + str(arg2) + ", not allowed. " + message, other_values_to_be_printed, LogLevel.FATAL if fatal else LogLevel.ERROR)

##Main internal logging method, please use the methods above instead, since this is not thread safe.
func _internal_log(message:String, values, log_level := LogLevel.INFO):
	if current_log_level > log_level :
		return
	if log_level == LogLevel.DEFAULT:
		err("Can't log at 'default' level, this level is only used as filter")
	##Format message string
	var format_str:String = ProjectSettings.get_setting(settings.LOG_MESSAGE_FORMAT_KEY, settings.LOG_MESSAGE_FORMAT_DEFAULT_VALUE)
	message = format_str.format(_get_format_data(message, log_level))
	##Tac on passed values
	message += _stringify_values(values)
	
	var stack = get_stack()
	emit_signal("log_message", log_level, message)
	if stack.is_empty():#Aka is connected to debug server -> print to the editor console in addition to pushing the warning.
		_log_mode_console(message, log_level)
	else:
		_log_mode_editor(message, log_level, stack)	
	##AKA, level is error or fatal, the main tree is accessible and we want to print it.
	if log_level > 3 && Log.is_inside_tree() && ProjectSettings.get_setting(settings.PRINT_TREE_ON_ERROR_KEY, settings.PRINT_TREE_ON_ERROR_DEFAULT_VALUE):
		#We want to access the main scene tree since this may be a custom logger that isn't in the main tree.
		print("Main tree: ")
		Log.get_tree().root.print_tree_pretty()
		print("")#Print empty line to mark new message
	
	if log_level == LogLevel.FATAL:
		_crash_behavior.call()

func _log_mode_editor(msg:String, lvl:LogLevel, stack:Array):
	match lvl:
		LogLevel.DEBUG:
			print_rich("[color=gray]"+msg+"[/color]")
		LogLevel.INFO:
			print_rich(msg)
		LogLevel.WARN:
			print_rich("[color=yellow]"+msg+"[/color]")
			push_warning(msg)
			print(_get_reduced_stack(stack) + "\n")
		_:#AKA error or fatal
			push_error(msg)
			msg = msg.replace("[lb]", "[").replace("[rb]", "]")
			printerr(msg)
			#Mimic the native godot behavior of halting execution upon error. 
			if ProjectSettings.get_setting(settings.BREAK_ON_ERROR_KEY, settings.BREAK_ON_ERROR_DEFAULT_VALUE):
			##Please go a few steps down the stack to find the errorous code, since you are currently inside the error handler.
				breakpoint
			print(_get_reduced_stack(stack))
		

func _log_mode_console(msg:String, lvl:LogLevel):
	##remove any BBCodes
	msg = msg.replace("[lb]", "[").replace("[rb]", "]")
	if lvl < 3:
		print(msg)
	elif lvl == LogLevel.WARN:
		push_warning(msg)
	else:
		push_error(msg)

func _get_format_data(msg:String, lvl:LogLevel)->Dictionary:
	var now = Time.get_datetime_dict_from_system(ProjectSettings.get_setting(settings.USE_UTC_TIME_FORMAT_KEY, settings.USE_UTC_TIME_FORMAT_DEFAULT_VALUE))
	now["second"] = "%02d"%now["second"]
	now["minute"] = "%02d"%now["minute"]
	now["hour"] = "%02d"%now["hour"]
	now["day"] = "%02d"%now["day"]
	now["month"] = "%02d"%now["month"]
	
	var format_data := {
			"log_name":_log_name,
			"message":msg,
			"level":LogLevel.keys()[lvl]
		}
	format_data.merge(now)
	return format_data

func _stringify_values(values)->String:
	match typeof(values):
		TYPE_NIL:
			return ""
		TYPE_ARRAY:
			var msg = "["
			for k in values:
				msg += "{k}, ".format({"k":JSON.stringify(k)})
			return msg + "]"
		TYPE_DICTIONARY:
			var msg = "{"
			for k in values:
				if typeof(values[k]) == TYPE_OBJECT && values[k] != null:
					msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(JsonData.to_dict(values[k],false))})
				else:
					msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(values[k])})
			return msg+"}"
		TYPE_PACKED_BYTE_ARRAY:
			return JSON.stringify(JsonData.unmarshal_bytes_to_dict(values))
		TYPE_OBJECT:
			return JSON.stringify(JsonData.to_dict(values,false))
		_:
			return JSON.stringify(values)

func _get_reduced_stack(stack:Array)->String:
	var stack_trace_message:=""
	
	if !stack.is_empty():#aka has stack trace.
		stack_trace_message += "at:\n"
		
		for i in range(stack.size()-2):
			var entry = stack[stack.size()-1-i]
			stack_trace_message += "\t" + entry["source"] + ":" + str(entry["line"]) + " in func " + entry["function"] + "\n"
	else:
		##TODO: test print_debug()
		stack_trace_message = "No stack trace available, please run from within the editor or connect to a remote debug context."
	return stack_trace_message

##Internal method.
func _set_level(level:LogLevel):
	level = _get_external_log_level() if level == LogLevel.DEFAULT else level
	info("setting log level to " + LogLevel.keys()[level])
	current_log_level = level

##Internal method.
func _get_external_log_level()->LogLevel:
	var key = Config.get_var("log-level","info").to_upper()
	if LogLevel.keys().has(key):
		return LogLevel[key]
	else:
		warn("The variable log-level is set to an illegal type, defaulting to info")
		return LogLevel.INFO

static func _ensure_setting_exists(setting: String, default_value) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, default_value)
		ProjectSettings.set_initial_value(setting, default_value)

		if ProjectSettings.has_method("set_as_basic"): # 4.0 backward compatibility
			ProjectSettings.call("set_as_basic", setting, true)

##Controls the behavior when a fatal error has been logged. 
##Edit to customize the behavior.
static func default_crash_behavior():
	#Restart the process to the main scene. (Uncomment if wanted), 
	#note that we don't want to restart if we crash on init, then we get stuck in an infinite crash-loop, which isn't fun for anyone. 
	#if get_tree().get_frame()>0:
	#	var _ret = OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	
	#Choose crash mechanism. Difference is that get_tree().quit() quits at the end of the frame, 
	#enabling multiple fatal errors to be cast, printing multiple stack traces etc. 
	#Warning regarding the use of OS.crash() in the docs can safely be regarded in this case.
	OS.crash("Crash since falal error ocurred")
	#get_tree().quit(-1)
