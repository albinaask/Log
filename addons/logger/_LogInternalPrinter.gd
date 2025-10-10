@tool
extends RefCounted

##Intrenal singleton that handles all the printing of logs. 
##If modifications to the logging behaviour is required, this is the place to do it. 
##Generally, an entry is processed per message, and it is processed with _internal_log. 
##Using this and the methods that this calles should be a good start for editing.
##They are called by a separate thread and thread safe between eachother. Storing data between the threads is done through the LogStream.LogEntry class.
class_name _LogInternalPrinter

##Log uses two queues, one for writing intries to, and one for processing, that way, the thread is more independent and has potentially higher speed.
static var _front_queue: Array[LogStream.LogEntry]
static var _back_queue: Array[LogStream.LogEntry]
static var _front_queue_size: int = 0

const _settings := preload("./LogSettings.gd")

static var _log_mutex = Mutex.new()
static var _log_thread = Thread.new()
##Flag for marking when the log thread should stop looping.
static var _is_quitting = false
static var _is_thread_started = false
static var _script_server: Object
## Tracks whether logging stays on the main thread (true inside the editor).
static var _single_threaded_mode = true
# Used to double-check ScriptServer notifications target this script.
const LOGGER_SCRIPT_PATH := "res://addons/logger/_LogInternalPrinter.gd"
##Used for benchmarking the time it takes to log a message on the main thread. Microbe is WIP, but see github.com/albinaask/Microbe for more info.
#static var push_microbe = Microbe.new("push to queue")

##Settings are set in ProjectSettings. Look for Log and set them from there. See 'res://addons/logger/LogSettings.gd' for explanations on what each setting do.
static var BREAK_ON_ERROR:bool = _settings._ensure_setting_exists(_settings.BREAK_ON_ERROR_KEY, _settings.BREAK_ON_ERROR_DEFAULT_VALUE)
static var PRINT_TREE_ON_ERROR:bool = _settings._ensure_setting_exists(_settings.PRINT_TREE_ON_ERROR_KEY, _settings.PRINT_TREE_ON_ERROR_DEFAULT_VALUE)
static var CYCLE_BREAK_TIME:int = _settings._ensure_setting_exists(_settings.MIN_PRINTING_CYCLE_TIME_KEY, _settings.MIN_PRINTING_CYCLE_TIME_DEFAULT_VALUE)
static var USE_UTC_TIME_FORMAT:bool = _settings._ensure_setting_exists(_settings.USE_UTC_TIME_FORMAT_KEY, _settings.USE_UTC_TIME_FORMAT_DEFAULT_VALUE)
static var GLOBAL_PATH_LIST = ProjectSettings.get_global_class_list()
static var BB_CODE_REMOVER_REGEX = RegEx.new()
static var BB_CODE_EXCLUDING_BRACKETS_REMOVER_REGEX = RegEx.new()
static var VALUE_PRIMER_STRING:String = _settings._ensure_setting_exists(_settings.VALUE_PRIMER_STRING_KEY, _settings.VALUE_PRIMER_STRING_DEFAULT_VALUE)

##Note that these are in the same order as LogStream.LogLevel
static var MESSAGE_FORMAT_STRINGS:Array[String]


##Every method in this class is static, therefore a static constructor is used.
static func _static_init() -> void:
	# The Godot editor's hot-reload can call _static_init multiple times; shut down any old worker first.
	if _is_thread_started:
		_cleanup()
	_is_quitting = false
	# Runtime builds keep the background worker; editor builds force single-threaded logging.
	_single_threaded_mode = Engine.is_editor_hint()

	MESSAGE_FORMAT_STRINGS  = [
		_settings._ensure_setting_exists(_settings.DEBUG_MESSAGE_FORMAT_KEY, _settings.DEBUG_MESSAGE_FORMAT_DEFAULT_VALUE),
		_settings._ensure_setting_exists(_settings.INFO_MESSAGE_FORMAT_KEY, _settings.INFO_MESSAGE_FORMAT_DEFAULT_VALUE),
		_settings._ensure_setting_exists(_settings.WARNING_MESSAGE_FORMAT_KEY, _settings.WARNING_MESSAGE_FORMAT_DEFAULT_VALUE),
		_settings._ensure_setting_exists(_settings.ERROR_MESSAGE_FORMAT_KEY, _settings.ERROR_MESSAGE_FORMAT_DEFAULT_VALUE),
		_settings._ensure_setting_exists(_settings.FATAL_MESSAGE_FORMAT_KEY, _settings.FATAL_MESSAGE_FORMAT_DEFAULT_VALUE)
	]
	
	var queue_size = _settings._ensure_setting_exists(_settings.LOG_QUEUE_SIZE_KEY, _settings.LOG_QUEUE_SIZE_DEFAULT_VALUE)
	queue_size = max(queue_size, 1)#Make sure queue size is at least 1.
	
	BB_CODE_REMOVER_REGEX.compile("\\[(lb|rb)\\]|\\[.*?\\]")
	BB_CODE_EXCLUDING_BRACKETS_REMOVER_REGEX.compile("\\[(?!(?:lb|rb)\\])[a-zA-Z0-9=_\\/]*+\\]")
	if !ProjectSettings.settings_changed.is_connected(LogStream.sync_project_settings):
		ProjectSettings.settings_changed.connect(LogStream.sync_project_settings)
	if Engine.is_editor_hint() and Engine.has_singleton("ScriptServer"):
		_script_server = Engine.get_singleton("ScriptServer")
		# Listen for editor reloads so we can join the worker before bytecode is swapped out;
		# without this the worker keeps running with freed bytecode and crashes on save.
		if _script_server and !_script_server.script_changed.is_connected(_on_script_server_script_changed):
			_script_server.script_changed.connect(_on_script_server_script_changed)
	
	# Rebuild the queues; old LogEntry instances may still reference freed script data.
	_front_queue = [] as Array[LogStream.LogEntry]
	_back_queue = [] as Array[LogStream.LogEntry]
	_front_queue_size = 0
	_front_queue.resize(queue_size)
	_back_queue.resize(queue_size)
	for i in range(queue_size):
		_front_queue[i] = LogStream.LogEntry.new()
		_back_queue[i] = LogStream.LogEntry.new()

	if !_single_threaded_mode:
		if _log_thread.start(_process_logs, Thread.PRIORITY_LOW) != OK:
			printerr("Log error: Couldn't create Log thread. This should never happen, please contact dev. No messages will be printed")
		else:
			# Track that we have a live worker so reload can shut it down first.
			_is_thread_started = true

func _ns_push_to_queue(stream_name:String, message:String, message_level:int, stream_level:int, crash_behaviour:Callable, on_log_message_signal_emission_callback:Callable, values:Variant) -> void:
	_push_to_queue(stream_name, message, message_level, stream_level, crash_behaviour, on_log_message_signal_emission_callback, values)


##Pushes a log entry onto the front (input queue). This is done so Log can process the log asynchronously.
##Method is called by LogStream.info and the like.
static func _push_to_queue(stream_name:String, message:String, message_level:int, stream_level:int, crash_behaviour:Callable, on_log_message_signal_emission_callback:Callable, values:Variant = null)-> void:
	#push_microbe.start()
	if message_level < stream_level:
	#	push_microbe.finish()
		return
	
	# Editor builds skip the worker thread entirely and log on the main thread here.
	# Godot reloads editor scripts aggressively for previews/completion; keeping the
	# background thread alive across those reloads would leave it running against
	# freed bytecode and crash (see https://github.com/albinaask/Log/issues/22). This
	# single-threaded path keeps the editor stable while runtime exports still use
	# the async worker.
	if _single_threaded_mode:
		var entry = LogStream.LogEntry.new()
		entry.stream_name = stream_name
		entry.message = message
		entry.message_level = message_level
		entry.crash_behaviour = crash_behaviour
		entry.values = values
		entry.stack = get_stack()
		if message_level >= LogStream.LogLevel.ERROR:
			push_error(message)
			if BREAK_ON_ERROR:
				breakpoint
		elif message_level == LogStream.LogLevel.WARN:
			push_warning(message)
		_internal_log(entry)
		if message_level == LogStream.LogLevel.FATAL:
			entry.crash_behaviour.call()
		on_log_message_signal_emission_callback.call(message)
		return

	_log_mutex.lock()
	#push_microbe.finish_sub_step("lock")
	var entry:LogStream.LogEntry
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
		##This waits for the log thread to finish processing messages before exiting.
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
static func _internal_log(entry:LogStream.LogEntry):
	var message = BB_CODE_REMOVER_REGEX.sub(entry.message, "", true)
	var message_level:LogStream.LogLevel = entry.message_level
	_reduce_stack(entry)
	
	var value_string = _stringify_values(entry.values)
	 
	if entry.stack.is_empty():#Aka is connected to debug server -> print to the editor console in addition to pushing the warning.
		_log_mode_console(entry)
	else:
		_log_mode_editor(entry)
	##AKA, level is error or fatal, the main tree is accessible and we want to print it.
	if message_level > LogStream.LogLevel.WARN && PRINT_TREE_ON_ERROR:
		if !_single_threaded_mode:
			# When the worker thread is active we're off the main thread; bounce back before touching the tree.
			_print_tree_now.call_deferred()
		else:
			_print_tree_now()

static func _log_mode_editor(entry:LogStream.LogEntry):
	var message_format_strings = MESSAGE_FORMAT_STRINGS
	var message_level = entry.message_level
	var message_format = message_format_strings[message_level]
	var format_data = _get_format_data(entry)
	var output = message_format.format(format_data)
	print_rich(output)
	var stack = entry.stack
	var level = entry.message_level
	if level == LogStream.LogLevel.WARN:
		print(_create_stack_string(stack) + "\n")
	if level > LogStream.LogLevel.WARN:
		print(_create_stack_string(stack) + "\n")

static func _log_mode_console(entry:LogStream.LogEntry):
	##remove any BBCodes
	var msg = BB_CODE_REMOVER_REGEX.sub(entry.message,"", true)
	var level = entry.message_level
	if level < 3:
		print(msg)
	elif level == LogStream.LogLevel.WARN:
		push_warning(msg)
	else:
		push_error(msg)


static func _get_format_data(entry:LogStream.LogEntry)->Dictionary:
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
		var values = _stringify_values(entry.values)
		var reduced_values = BB_CODE_EXCLUDING_BRACKETS_REMOVER_REGEX.sub(values, "", true)
		#print("values: (" + reduced_values + ")")
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
static func _reduce_stack(entry:LogStream.LogEntry)->void:
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


##Shuts down the worker thread and disconnects editor-only hooks. Safe to call repeatedly.
static func _cleanup():
	_log_mutex.lock()
	_is_quitting = true
	_log_mutex.unlock()
	# Only join the worker when we actually spawned one (runtime mode).
	if !_single_threaded_mode and _log_thread.is_started():
		_log_thread.wait_to_finish()
	_is_thread_started = false
	_log_thread = Thread.new()
	_is_quitting = false
	_front_queue_size = 0
	if _script_server and _script_server.script_changed.is_connected(_on_script_server_script_changed):
		_script_server.script_changed.disconnect(_on_script_server_script_changed)
	_script_server = null

static func _on_script_server_script_changed(script:Script) -> void:
	if script == null:
		return
	if script.resource_path == LOGGER_SCRIPT_PATH:
		_cleanup()

static func _print_tree_now() -> void:
	# May be reached via call_deferred() to ensure we run on the main thread before touching the tree.
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree: SceneTree = main_loop
		if tree.root:
			# Runs on the main thread after call_deferred() so accessing the tree is safe.
			print("Main tree: ")
			tree.root.print_tree_pretty()
			print("")#Print empty line to mark new message
