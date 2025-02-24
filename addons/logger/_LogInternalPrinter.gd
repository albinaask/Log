@tool
extends RefCounted

##Intrenal singleton that handles all the printing of logs. 
##If modifications to the logging behaviour is required, this is the place to do it. 
##Generally, an entry is processed per message, and it is processed with _internal_log. 
##Using this and the methods that this calles should be a good start for editing.
##They are called by a separate thread and thread safe between eachother. Storing data between the threads is done through the _LogEntry class.
class_name _LogInternalPrinter

##Log uses two queues, one for writing intries to, and one for processing, that way, the thread is more independent and has potentially higher speed.
static var _front_queue: Array[_LogEntry]
static var _back_queue: Array[_LogEntry]
static var _front_queue_size: int = 0

const _settings := preload("./settings.gd")

static var _log_mutex = Mutex.new()
static var _log_thread = Thread.new()
##Flag for marking when the log thread should stop looping.
static var _is_quitting = false
##Used for benchmarking the time it takes to log a message on the main thread. Microbe is WIP, but see github.com/albinaask/Microbe for more info.
#static var push_microbe = Microbe.new("push to queue")

##Settings are set in ProjectSettings. Look for Log and set them from there. See 'res://addons/logger/settings.gd' for explanations on what each setting do.
static var BREAK_ON_ERROR:bool = _settings._ensure_setting_exists(_settings.BREAK_ON_ERROR_KEY, _settings.BREAK_ON_ERROR_DEFAULT_VALUE)
static var PRINT_TREE_ON_ERROR:bool = _settings._ensure_setting_exists(_settings.PRINT_TREE_ON_ERROR_KEY, _settings.PRINT_TREE_ON_ERROR_DEFAULT_VALUE)
static var CYCLE_BREAK_TIME:int = _settings._ensure_setting_exists(_settings.MIN_PRINTING_CYCLE_TIME_KEY, _settings.MIN_PRINTING_CYCLE_TIME_DEFAULT_VALUE)
static var USE_UTC_TIME_FORMAT:bool = _settings._ensure_setting_exists(_settings.USE_UTC_TIME_FORMAT_KEY, _settings.USE_UTC_TIME_FORMAT_DEFAULT_VALUE)
static var GLOBAL_PATH_LIST = ProjectSettings.get_global_class_list()
static var BB_CODE_REMOVER_REGEX = RegEx.new()
static var VALUE_PRIMER_STRING:String = _settings._ensure_setting_exists(_settings.VALUE_PRIMER_STRING_KEY, _settings.VALUE_PRIMER_STRING_DEFAULT_VALUE)

##Note that these are in the same order as LogStream.LogLevel
static var MESSAGE_FORMAT_STRINGS:Array[String] = [
	_settings._ensure_setting_exists(_settings.DEBUG_MESSAGE_FORMAT_KEY, _settings.DEBUG_MESSAGE_FORMAT_DEFAULT_VALUE),
	_settings._ensure_setting_exists(_settings.INFO_MESSAGE_FORMAT_KEY, _settings.INFO_MESSAGE_FORMAT_DEFAULT_VALUE),
	_settings._ensure_setting_exists(_settings.WARNING_MESSAGE_FORMAT_KEY, _settings.WARNING_MESSAGE_FORMAT_DEFAULT_VALUE),
	_settings._ensure_setting_exists(_settings.ERROR_MESSAGE_FORMAT_KEY, _settings.ERROR_MESSAGE_FORMAT_DEFAULT_VALUE),
	_settings._ensure_setting_exists(_settings.FATAL_MESSAGE_FORMAT_KEY, _settings.FATAL_MESSAGE_FORMAT_DEFAULT_VALUE)
]


##Every method in this class is static, therefore a static constructor is used.
static func _static_init() -> void:
	var queue_size = _settings._ensure_setting_exists(_settings.LOG_QUEUE_SIZE_KEY, _settings.LOG_QUEUE_SIZE_DEFAULT_VALUE)
	BB_CODE_REMOVER_REGEX.compile("\\[(lb|rb)\\]|\\[.*?\\]")

	ProjectSettings.settings_changed.connect(LogStream.sync_project_settings)
	if _log_thread.start(_process_logs, Thread.PRIORITY_LOW) != OK:
		#TODO: update this to call _internal_log.
		#TODO: Make Log able to log from same thread...
		printerr("Log error: Couldn't create Log thread. This should never happen, please contact dev. No messages will be printed")
	
	_front_queue.resize(queue_size)
	_back_queue.resize(queue_size)
	for i in range(queue_size):
		_front_queue[i] = _LogEntry.new()
		_back_queue[i] = _LogEntry.new()

func _ns_push_to_queue(stream_name:String, message:String, message_level:int, stream_level:int, crash_behaviour:Callable, on_log_message_signal_emission_callback:Callable, values:Variant) -> void:
	_push_to_queue(stream_name, message, message_level, stream_level, crash_behaviour, on_log_message_signal_emission_callback, values)


##Pushes a log entry onto the front (input queue). This is done so Log can process the log asynchronously.
##Method is called by LogStream.info and the like.
static func _push_to_queue(stream_name:String, message:String, message_level:int, stream_level:int, crash_behaviour:Callable, on_log_message_signal_emission_callback:Callable, values:Variant = null)-> void:
	#push_microbe.start()
	if message_level < stream_level:
	#	push_microbe.finish()
		return
	
	_log_mutex.lock()
	#push_microbe.finish_sub_step("lock")
	var entry:_LogEntry
	if _is_front_queue_full():
		entry = _front_queue[_front_queue_size-1]
		entry.stream_name = "Log"
		entry.message = "Log queue overflow. Print less messages or increase queue size in project settings or squash messages into one long."
		entry.message_level = LogStream.LogLevel.WARN
	else:
		entry = _front_queue[_front_queue_size]
		entry.stream_name = stream_name
		entry.message = message
		entry.message_level = message_level
		entry.crash_behaviour = crash_behaviour
		entry.values = values
		_front_queue_size += 1
	#push_microbe.finish_sub_step("entry assignment")
	entry.stack = get_stack()
	#push_microbe.finish_sub_step("get_stack")
	_log_mutex.unlock()
	#push_microbe.finish_sub_step("unlock")

	if message_level >= LogStream.LogLevel.ERROR:
		push_error(message)
		if BREAK_ON_ERROR:
			##Please go a few steps down the stack to find the errorous code, since you are currently inside the Log error handler, which is probably not what you want.
			breakpoint
	elif message_level == LogStream.LogLevel.WARN:
		push_warning(message)
	#push_microbe.finish_sub_step("if statements")
	if message_level == LogStream.LogLevel.FATAL:
		entry.crash_behaviour.call()
	on_log_message_signal_emission_callback.call(message)
	#push_microbe.finish_sub_step("signal emission")
	#push_microbe.finish()

##Helper method for checking if the front queue is full.
static func _is_front_queue_full() -> bool:
	return _front_queue_size == _front_queue.size()

##Main loop of the logging thread. Runs until godot is quit or a fatal error occurs.
static func _process_logs():
	while !_is_quitting:
		var start = Time.get_ticks_usec()
		#Swap th buffers, so that the back queue is now the front queue and prepare for overriding the front queue with new messages.
		_log_mutex.lock()
		var temp = _front_queue
		_front_queue = _back_queue
		_back_queue = temp
		var _back_queue_size = _front_queue_size
		_front_queue_size = 0
		_log_mutex.unlock()

		for i in range(_back_queue_size):
			_internal_log(_back_queue[i])
		var delta = Time.get_ticks_usec() - start
		#Sleep for a while, depending on the time it took to process the messages, 
		OS.delay_usec(max(CYCLE_BREAK_TIME*1000-delta, 0))

##Main internal logging method, please use the methods in LogStream instead of this from the outside, since this is NOT thread safe in any regard and not designed to be used.
static func _internal_log(entry:_LogEntry):
	var message = BB_CODE_REMOVER_REGEX.sub(entry.message, "", true)
	var message_level:LogStream.LogLevel = entry.message_level
	_reduce_stack(entry)
	
	var value_string = _stringify_values(entry.values)
	 
	if entry.stack.is_empty():#Aka is connected to debug server -> print to the editor console in addition to pushing the warning.
		_log_mode_console(entry)
	else:
		_log_mode_editor(entry)
	##AKA, level is error or fatal, the main tree is accessible and we want to print it.
	if message_level > LogStream.LogLevel.WARN && Log.is_inside_tree() && PRINT_TREE_ON_ERROR:
		#We want to access the main scene tree since this may be a custom logger that isn't in the main tree.
		print("Main tree: ")
		Log.get_tree().root.print_tree_pretty()
		print("")#Print empty line to mark new message

static func _log_mode_editor(entry:_LogEntry):
	#print("message level: " + str(entry.message_level))
	#print(MESSAGE_FORMAT_STRINGS)
	
	print_rich(MESSAGE_FORMAT_STRINGS[entry.message_level].format(_get_format_data(entry)))
	var stack = entry.stack
	var level = entry.message_level
	if level == LogStream.LogLevel.WARN:
		print(_create_stack_string(stack) + "\n")
	if level > LogStream.LogLevel.WARN:
		print(_create_stack_string(stack) + "\n")	

static func _log_mode_console(entry:_LogEntry):
	##remove any BBCodes
	var msg = BB_CODE_REMOVER_REGEX.sub(entry.message,"", true)
	var level = entry.message_level
	if level < 3:
		print(msg)
	elif level == LogStream.LogLevel.WARN:
		push_warning(msg)
	else:
		push_error(msg)


static func _get_format_data(entry:_LogEntry)->Dictionary:
	var now = Time.get_datetime_dict_from_system(USE_UTC_TIME_FORMAT)
	
	var log_call = null
	var script = ""
	var script_class_name = ""
	if !entry.stack.is_empty():
		log_call = entry.stack[0]
		var source = log_call["source"]
		script = source.split("/")[-1]
		var result = GLOBAL_PATH_LIST.filter(func(entry):return entry["path"] == source)
		script_class_name = script if result.is_empty() else result[0]["class"]
	
	var format_data := {
			"log_name":entry.stream_name,
			"message":entry.message,
			"level":LogStream.LogLevel.keys()[entry.message_level],
			"script": script,
			"class": script_class_name, 
			"function": log_call["function"] if log_call else "",
			"line": log_call["line"] if log_call else "",
		}
	if entry.values != null:
		var reduced_values = BB_CODE_REMOVER_REGEX.sub(_stringify_values(entry.values), "", true)
		print("values: (" + reduced_values + ")")
		format_data["values"] = VALUE_PRIMER_STRING + reduced_values
	else:
		format_data["values"] = ""
	format_data["second"] = "%02d"%now["second"]
	format_data["minute"] = "%02d"%now["minute"]
	format_data["hour"] = "%02d"%now["hour"]
	format_data["day"] = "%02d"%now["day"]
	format_data["month"] = "%02d"%now["month"]
	format_data["year"] = "%04d"%now["year"]
	
	return format_data

static func _stringify_values(values)->String:
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
					msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(_ObjectParser.to_dict(values[k],false))})
				else:
					msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(values[k])})
			return msg+"}"
		TYPE_OBJECT:
			return JSON.stringify(_ObjectParser.to_dict(values,false))
		_:
			return JSON.stringify(values)

##Removes the top of the stack trace in order to remove the logger.
static func _reduce_stack(entry:_LogEntry)->void:
	var kept_frames = 0
	var stack = entry.stack
	for i in range(stack.size()):
		##Search array from back to front, aka from bottom to top, aka into log from the outside.
		var stack_entry = stack[stack.size()-1-i]
		if stack_entry["source"].contains("log-stream.gd"):
			kept_frames = i
			break
	#cut of log part of stack.
	entry.stack = stack.slice(stack.size()-kept_frames)

static func _create_stack_string(stack:Array)->String:
	var stack_trace_message:=""
	if !stack.is_empty():#aka has stack trace.
		stack_trace_message += "at:\n"
		for entry in stack:
			stack_trace_message += "\t" + entry["source"] + ":" + str(entry["line"]) + " in func " + entry["function"] + "\n"
	else:
		stack_trace_message = "No stack trace available, please run from within the editor or connect to a remote debug context."
	return stack_trace_message


static func _cleanup():
	_log_mutex.lock()
	_is_quitting = true
	_log_mutex.unlock()
	_log_thread.wait_to_finish()

#Class for lobbing around logging data between the main thread and the logging thread.
class _LogEntry:
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
