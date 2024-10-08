GDPC                 �                                                                         T   res://.godot/exported/133200997/export-17993b99417730f055893e9f1e3ec3d4-logtest.scn @k           ��4�U�Z�w��*؉    ,   res://.godot/global_script_class_cache.cfg  �     �      w��,x2\/���X�/    D   res://.godot/imported/icon.png-487276ed1e3a0c39cad0279d744ee560.ctex�s     �      3)��(���}u.9X    L   res://.godot/imported/large_icon.png-1bba27ef5f1ea59c0d4c9d63d489ab94.ctex  0�     �      3)��(���}u.9X    P   res://.godot/imported/output_example.png-9f76c73b5c859fef08c6ef08794e0012.ctex  �F      �#     �yF��dVЖ��.��       res://.godot/uid_cache.bin  0�     �       V4S���+�V�J�?�        res://addons/logger/config.gd           �      ���A�0���w���        res://addons/logger/json-data.gd�      ~      Ⱦ7(�\�R!�ྎ�    $   res://addons/logger/log-stream.gd   p!      l#      y%��I�(8*Q�,k        res://addons/logger/logger.gd   �D      �       ��bKFzlU�I���        res://addons/logger/plugin.gd   �E      A      -b�r�i�^������       res://icon.png  ��     �&      p���(����c_|�h]       res://icon.png.import   `�     �       p+v�`L�ҡ+���    (   res://images/output_example.png.import  pj     �       �2��j��z��4�5       res://large_icon.png.import Г     �       .K�LQ\�� ���h�       res://project.binary��     �      ������X�d�O�        res://tests/logtest.tscn.remap  ��     d       %9[(�+�x�\[n    �5extends Node

class_name Config

static func get_arguments() -> Dictionary:
	var arguments = {}
	var key = ""
	
	for argument in OS.get_cmdline_args():
			var k = _parse_argument_key(argument)
			if k != "":
				key = k
				arguments[k] = ""
			elif key != "":
				arguments[key] = argument
				key == ""
			if argument.contains("="):
				var key_value = argument.split("=")
				arguments[key] = key_value[1]
				key == ""
	return arguments

static func _parse_argument_key(argument:String) -> String:
	var prefixes = ["+","--","-"]
	for prefix in prefixes:
		if argument.begins_with(prefix):
			if argument.contains("="):
				return argument.split("=")[0].lstrip(prefix)
			return argument.lstrip(prefix)
	return ""

static func get_steam_flag_name(name:String,prefix:String="") -> String:
	return (prefix + name).to_lower().replace("-","_")
	
static func get_flag_name(name:String,prefix:String="") -> String:
	return (prefix + name).to_lower().replace("_","-")

static func get_env_name(name:String,prefix:String="") -> String:
	return (prefix + name).to_upper().replace("-","_")

static func get_var(name,default=""):
	var env_var_name = get_env_name(name)
	var flag_name = get_flag_name(name)
	var config_value = OS.get_environment(env_var_name)
	var steam_name = get_steam_flag_name(name)
	
	var args = get_arguments()
	if args.has(flag_name):
		return args[flag_name]
	if args.has(steam_name):
		return args[steam_name]
	if config_value != "":
		return config_value
	return default

static func get_int(name,default=0) -> int:
	return int(get_var(name,default))
	
static func get_bool(name,default=false,prefix:String="") -> bool:
	var v = get_var(name,default).to_lower()
	match v:
		"yes","true","t","1":
			return true
		_:
			return false
	return false

static func get_custom_var(name,type,default=null):
	match type:
		TYPE_ARRAY:
			return get_var(name,default).split(",")
		TYPE_BOOL:
			return get_bool(name,default)
		TYPE_DICTIONARY:
			return JSON.parse_string(get_var(name,default))
		TYPE_INT:
			return get_int(name,default)
		TYPE_MAX:
			pass
		TYPE_NIL:
			return default
		TYPE_RECT2:
			pass
		TYPE_RID:
			pass
		TYPE_STRING:
			return get_var(name,default)
		TYPE_TRANSFORM2D:
			pass
		TYPE_VECTOR2:
			pass
		TYPE_VECTOR3:
			pass
	return default
�We޹��q��class_name JsonData

const REQUIRED_OBJECT_SUFFIX="_r"
const COMPACT_VAR_SUFFIX="_c"

const WHITELIST_VAR_NAME = "whitelist"

static func marshal(obj:Object,compact:bool=false,compressMode:int=-1,skip_whitelist:bool=false) -> PackedByteArray:
	if obj == null:
		return PackedByteArray()
	if compressMode == -1:
		return var_to_bytes(to_dict(obj,compact,skip_whitelist))
	return var_to_bytes(to_dict(obj,compact,skip_whitelist)).compress(compressMode)

static func unmarshal(dict:Dictionary,obj:Object,compressMode:int=-1) -> bool:
	if dict.size() == 0 or obj == null:
		return false
	for k in dict:
		if !k in obj:
			continue
		var newVar = _get_var(obj[k],dict[k])
		if newVar != null:
			if k == "name" && newVar == "":
				continue
			obj[k] = newVar
	return true

static func unmarshal_bytes_to_dict(data:PackedByteArray,compressMode:int=-1) -> Dictionary:
	if data.size() == 0:
		return {}
	if compressMode == -1:
		return bytes_to_var(data)
	return bytes_to_var(data.decompress_dynamic(-1,compressMode))

static func unmarshal_bytes(data:PackedByteArray,obj:Object,compressMode:int=-1) -> bool:
	if data.size() == 0 or obj == null:
		return false
	var dict = unmarshal_bytes_to_dict(data,compressMode)
	for k in dict:
		if !k in obj:
			continue
		var newVar = _get_var(obj[k],dict[k])
		if newVar != null:
			obj[k] = newVar
	return false

static func to_dict(obj:Object,compact:bool,skip_whitelist:bool=false) ->Dictionary:
	if obj == null:
		return {}
	if !skip_whitelist:
		return _get_dict_with_list(obj,obj.get_property_list(),compact)

	var output:Dictionary = {}
	if WHITELIST_VAR_NAME in obj and obj[WHITELIST_VAR_NAME].size() > 0:
		return _get_dict_with_list(obj,obj[WHITELIST_VAR_NAME],false)

	return output

static func required_items(property_list:Array) ->Array:
		var output:Array = []
		for property in property_list:
			var name = ""
			if typeof(property) != TYPE_STRING && "name" in property:
				name = str(property.name)
			else:
				name = property
			if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
				output.append(property)
				continue
		return output

static func _get_dict_with_list(obj:Object,property_list:Array,compact:bool) ->Dictionary:
	var output:Dictionary = {}
	for property in property_list:
		var name = ""
		if typeof(property) != TYPE_STRING && "name" in property:
			name = str(property.name)
		else:
			name = property
		if name.begins_with("_"):
			continue
		if compact and !_ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
			continue
		if !name in obj:
			continue
		var data_type = typeof(obj[name])
		var value = obj[name]
		match data_type:
			TYPE_NIL:
				continue
			TYPE_OBJECT:
				if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
					#var t = Thread.new()
					#var lamda = func():
					output[name] = to_dict(value,compact)

			TYPE_ARRAY: # todo
				continue
			TYPE_DICTIONARY: # todo
				var processsed_dictionary = {}
				for key in Dictionary(value):
					var key_type = typeof(value[key])
					var key_value = value[key]
					match key_type:
						TYPE_OBJECT:
							if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
								processsed_dictionary[name] = to_dict(key_value,compact)
						TYPE_ARRAY:
							continue
						_:
							processsed_dictionary[key] = key_value
				output[name] = processsed_dictionary
			_:
				output[name] = value
	return output

static func _ends_with(v:String,list:Array) -> bool:
	for s in list:
		if v.ends_with(s):
			return true
	return false

static func _get_var(expected,actual):
	if typeof(expected) == typeof(actual):
		return actual
	match typeof(expected):
		TYPE_NIL : # 0
			return null
		TYPE_BOOL : # 1
			return actual as bool
		TYPE_INT : # 2
			return actual as int
		TYPE_FLOAT : # 3
			return actual as float
		TYPE_STRING : # 4
			return actual
		TYPE_VECTOR2 : # 5
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 2:
				return null
			return Vector2(d[0],d[1])
		#return actual as Vector2
		TYPE_VECTOR2I : # 6
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 2:
				return null
			return Vector2i(Vector2(d[0],d[1]))
		TYPE_RECT2 : # 7
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Rect2(d[0],d[1],d[2],d[3])
		TYPE_RECT2I : # 8
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Rect2i(Rect2(d[0],d[1],d[2],d[3]))
		TYPE_VECTOR3 : # 9
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 3:
				return null
			return Vector3(d[0],d[1],d[2])
		TYPE_VECTOR3I : # 10
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 3:
				return null
			return Vector3i(Vector3(d[0],d[1],d[2]))
		TYPE_TRANSFORM2D : # 11
			return null
		TYPE_VECTOR4 : # 12
			return null
		TYPE_VECTOR4I : # 13
			return null
		TYPE_PLANE : # 14
			return null
		TYPE_QUATERNION : # 15
			return null
		TYPE_AABB : # 16
			return null
		TYPE_BASIS : # 17
			return null
		TYPE_TRANSFORM3D : # 18
			return null
		TYPE_PROJECTION : # 19
			return null
		TYPE_COLOR : # 20
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Color(d[0],d[1],d[2],d[3])
		TYPE_STRING_NAME : # 21
			return null
		TYPE_NODE_PATH : # 22
			return null
		TYPE_RID : # 23
			return null
		TYPE_OBJECT : # 24
			if unmarshal(actual as Dictionary,expected):
				return expected
			return null
		TYPE_CALLABLE : # 25
			return null
		TYPE_SIGNAL : # 26
			return null
		TYPE_DICTIONARY : # 27
			return JSON.parse_string(actual)
		TYPE_ARRAY : # 28
			return JSON.parse_string(actual)
		TYPE_PACKED_BYTE_ARRAY : # 29
			return null
		TYPE_PACKED_INT32_ARRAY : # 30
			return null
		TYPE_PACKED_INT64_ARRAY : # 31
			return null
		TYPE_PACKED_FLOAT32_ARRAY : # 32
			return null
		TYPE_PACKED_FLOAT64_ARRAY : # 33
			return null
		TYPE_PACKED_STRING_ARRAY : # 34
			return null
		TYPE_PACKED_VECTOR2_ARRAY : # 35
			return null
		TYPE_PACKED_VECTOR3_ARRAY : # 36
			return null
		TYPE_PACKED_COLOR_ARRAY : # 37
			return null
		TYPE_MAX : # 38
			return null
	return null
/�@tool
extends Node
##Class that handles all the logging in the addon, methods can either be accessed through
##the "GodotLogger" singelton, or you can instance this class yourself(no need to add it to the tree)

class_name LogStream

#Settings

##Controls how the message should be formatted, follows String.format(), valid keys are: "level", "time", "log_name", "message"
const LOG_MESSAGE_FORMAT = "{log_name}/{level} [{time}] {message}"

##Whether to write logged messages to a file as well as to the console.
const WRITE_LOGS_TO_FILE = false

##Controls how the message time should be recorded in the console, valid keys are the dictionary keys in Time.get_date_time()
const LOG_TIME_FORMAT = "{hour}:{minute}:{second}"
##Controls where the log files should be placed. Valid keys are the dictionary keys in Time.get_date_time()
const LOG_FILE_PATH = "user://logs/{year}{month}{date} - {hour}:{minute}:{second}.log"
##Whether to use the UTS time or the user
const USE_UTS_TIME_FORMAT = false
##Enables a breakpoint to mimic the godot behavior where the application doesn't crash when connected to debug environment, 
##but instead freezed and shows the stack etc in the debug panel.
const BREAK_ON_ERROR = true

##Controls the behavior when a fatal error has been logged. 
##Edit to customize the behavior.
static var DEFAULT_CRASH_BEHAVIOR := func():
	#Restart the process to the main scene. (Uncomment if wanted), 
	#note that we don't want to restart if we crash on init, then we get stuck in an infinite crash-loop, which isn't fun for anyone. 
	#if get_tree().get_frame()>0:
	#	var _ret = OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	
	#Choose crash mechanism. Difference is that get_tree().quit() quits at the end of the frame, 
	#enabling multiple fatal errors to be cast, printing multiple stack traces etc. 
	#Warning regarding the use of OS.crash() in the docs can safely be regarded in this case.
	OS.crash("Crash since falal error ocurred")
	#get_tree().quit(-1)

#end of settings

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
static var _start_time = Time.get_datetime_string_from_system(USE_UTS_TIME_FORMAT)
static var initialized = false

##Emits this signal whenever a message is recieved.
signal log_message(level:LogLevel,message:String)

func _init(log_name:String, min_log_level:=LogLevel.DEFAULT, crash_behavior:=DEFAULT_CRASH_BEHAVIOR):
	_log_name = log_name
	current_log_level = min_log_level
	_crash_behavior = crash_behavior

##prints a message to the log at the debug level.
func debug(message, values={}):
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

##Prints a message to the log at the fatal level, exits the application 
##since there has been a fatal error.
func fatal(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.FATAL)

##Shorthand for debug
func dbg(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.DEBUG)

##Shorthand for error
func err(message:String,values={}):
	call_thread_safe("_internal_log", message, values, LogLevel.ERROR)

##Throws an error if err_code is not of value "OK" and appends the error code string.
func err_cond_not_ok(err_code:Error, message:String, fatal:=true, other_values_to_be_printed={}):
	if err_code != OK:
		call_thread_safe("_internal_log", message + ". Error code: " + error_string(err_code), other_values_to_be_printed, LogLevel.FATAL if fatal else LogLevel.ERROR)

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

##Main internal logging method, please use the logger() instead since this is not thread safe.
func _internal_log(message:String, values, log_level := LogLevel.INFO):
	if current_log_level > log_level :
		return
	
	var now = Time.get_datetime_dict_from_system(USE_UTS_TIME_FORMAT)
	
	var msg = String(LOG_MESSAGE_FORMAT).format(
		{
			"log_name":_log_name,
			"message":message,
			"time":String(LOG_TIME_FORMAT).format(now),
			"level":LogLevel.keys()[log_level]
		})
	var stack = get_stack()
	
	match typeof(values):
		TYPE_ARRAY:
			if values.size() > 0:
				msg += "["
				for k in values:
					msg += "{k},".format({"k":JSON.stringify(k)})
				msg = msg.left(msg.length()-1)+"]"
		TYPE_DICTIONARY:
			if values.size() > 0:
				msg += "{"
				for k in values:
					if typeof(values[k]) == TYPE_OBJECT && values[k] != null:
						msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(JsonData.to_dict(values[k],false))})
					else:
						msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(values[k])})
				msg = msg.left(msg.length()-1)+"}"
		TYPE_PACKED_BYTE_ARRAY:
			if values == null:
				msg += JSON.stringify(null)
			else:
				msg += JSON.stringify(JsonData.unmarshal_bytes_to_dict(values))
		TYPE_OBJECT:
			if values == null:
				msg += JSON.stringify(null)
			else:
				msg += JSON.stringify(JsonData.to_dict(values,false))
		TYPE_NIL:
			msg += JSON.stringify(null)
		_:
			msg += JSON.stringify(values)
	
	_write_logs_to_file(msg)
	emit_signal("log_message", log_level, msg)
	match log_level:
		LogLevel.DEBUG:
			print_rich("[color=gray]"+msg+"[/color]")
		LogLevel.INFO:
			print(msg)
		LogLevel.WARN:
			if !stack.is_empty():#Aka is connected to debug server -> print to the editor console in addition to pushing the warning.
				print_rich("[color=yellow]"+msg+"[/color]")
			push_warning(msg)
			print(_get_reduced_stack(stack))
			print("")#Print empty line to space stack from new message
		LogLevel.DEFAULT:
			err("Can't log at 'default' level, this level is only used as filter")
		_:
			push_error(msg)
			if !stack.is_empty():#Aka is connected to debug server -> print to the editor console in addition to pushing the warning.
				printerr(msg)
				#Mimic the native godot behavior of halting execution upon error. 
				if BREAK_ON_ERROR:
					##Please go a few steps down the stack to find the errorous code, since you are currently inside the error handler.
					breakpoint
			print(_get_reduced_stack(stack))
			print_tree()
			print("")#Print empty line to space stack from new message
			if log_level == LogLevel.FATAL:
				_crash_behavior.call()

##Internal method.
static func _write_logs_to_file(message:String):
	if !WRITE_LOGS_TO_FILE:
		return
	if _log_file == null:
		_log_file = FileAccess.open(LOG_FILE_PATH.format(_start_time),FileAccess.WRITE)
	_log_file.store_line(message)

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
�sX@tool
extends LogStream

##A default instance of the LogStream. Instanced as the main log singelton.


func _init():
	super("Main", LogLevel.DEFAULT)
��D���1EF>@tool
extends EditorPlugin

var loadSingletonPlugin = {
	"Log" : "res://addons/logger/logger.gd",
}

func _enter_tree():
	for names in loadSingletonPlugin.keys():
		add_autoload_singleton(names, loadSingletonPlugin[names])


func _exit_tree():
	for names in loadSingletonPlugin.keys():
		remove_autoload_singleton(names)
��	:3�o��#�.GST2   �  �     ����               ��       f# RIFF^# WEBPVP8LR# /��z �0h�H�����="b�ѧ�ֳ���ԅ��\I�I�<�)ݺJ��ǧ�J��(e�<h+�E����Q�Y��I��;��9��zJR��U��p��<l�6;�m]s����|Z!41$� M�1"�t:�bDD:��t�5� V�����G��I1�oo��;Ʒ'{�mۆ��o�U�mI��}[������$K�$�"�i O�
gQ73sc�����/%���7ך�8㈀8*)��)��j���_HlG�Ȍ(�ܦf��TE"T"a��ob������f`f�q?���m�K���m�r�������$I�$I�E����a�Ȍ�`������o�{�������9���%2PE��"�ܒ/���"�7�(�*p\����!QC]N�d �%����f��ය|�%�K���A�V�0�������qI'��.W�(U��rGDS-F�`a���'�[��S��v�L�a��v0شÊ� ���q���i3+��T�y��B:����iӴ-@���P#g�]vɅC�]�؛�)+W�>��s�
2�:��{�T�(N���շ��*ф��:=�9�p�5�ʣC��,d� �o��˥wM�$�{�omv��-��^}k�h��rƱht���ؾ�sW#le��/������Ҳ�[C������ ϹPG
^?xy����-���Ⱥ��!I.Gڙ63K�Ɛ���heaip��B�Nkս	L�Vx}Z��0�E�3�
E�4�U�����kЦ�`d'�PQf���** �
ڠT@1�[
�����ٞ���ut�@��\�*�xP\`ܬJ�	"R,P��D@f7�"�C\b �+)EF�XXC+=H � ��a9$"�B*��UY�nay���d�@��m������+�	w:�3�i#4������n���<,�	���NG{���,t|��p�x�k\C�(k�l�ӣ���Ȕ�T��E��.ι��%F4�	��hd�?в8���ȴ��������>�# r��z� ���Z��em�*)�J(p#Kp9� �Ј��u+�K��Z��2SWJ����.����!�E�T��E�H�Cu��}�Zfj�t[��-3���r��E�hIu2˓��,k��F7����ۯ�/�(c�+@@lvy��#� 㻲Z�,��W��u�JY,�e���pw�-���" ��e�L-��@O3VKp�Xf���Niu�����Z]�<�Z]`������vY��*+˻b@��5�Ż��R?be���'���h�3  �1�v��fP�k��:!�уW�%���1��.8�"���8��Y�tŰՉxH̘߭�T�_-$�_��.Y]��)���ex](�%�Y�e������:Iu\#zױ
�0[~q��+�by��o�� l߶�����vip�A�X��������:[��_D�"]���N8�w�X����@NVO�twu�����B���[yR,ז�R�氰�	��&�J� �0ڹ�1�wf �q��K��K��D-/n��z� �$�(`��� X"���5B �(��
(��P��@	�K� �������n����f���F�[,����mmu��X~[	���R:��E@��mz�x��� E���7�*7�N�pZ��V��Zߗ�ehZ+R����
(��zs�E��z\ %�veL|Taja4����N�t��8�= ����
h�&��ޕ�e�Ļr��t�����M�H��(3���:��hq��q��f����J*۷.�� `��Z���R�u*5�p@�;�/����CGnu?9�<�wN���/W,���֞�p�a�+c� ���G��ש������af�7���W	�m�n~v<?��\W@+�:N�xƽ.��F xy�]�j���ݼ��V�J�0�Y��-.D&���ٻ+�R�A��]���.�"!��� ;�Bл�i��ͮq����YX(��wW�HM.8����j�ԏh��R� `�{��ۮ���&,�,�Ј�*�X<N���s7��ɮ~��?6@�ֻJ!�x�*`��@�:��س�,����l- ',-�A�W� �%�e!���2�/�tõ�ih����ӕTut)c�	 Ï�2��ml$,����ڿ!�����aq�ug�]�ҷ������q����V�������ʁ������^�\���s��n�� R��K�#�m�G���V� /���ڬ
x�-,D&N�$�¿����..�]&�||W�m�������хK�`to���e���Қ �_���Y0B]%��F�V8Y��">[���/�� T�'׾--:�쇝�P��}�@4�����'#�A�p�J�����.pA=�S��u��R:�g+ ���e��/��7V@�?��_���o��o@D��us�4�{�M��g`$�O^S}�	�Y�XE�,r��{���s6N�s��� �	���ÝN���`�����~Hu��u���7� ��H�"]�c�!�9�dLu6 ��N.���z�"~dv��xy{�j��u@\�P�V��Y��T9@�ן�i/t��m�)U����_X/�<�����p���l�������6rd}�2J��X.:����P��ED�t!�b��o�� o#! �Rip��R!�IvQh����g�t�Y�I,�3��V=d�L����J����!t�VwP [�$J� 6f�+�!��(n�A��`�\z��B0�E�� �xt�ޝr�2N.��a�D�������Ə��BPzבU�,$\rɮ��c��*`�w��Y�tG0�cT ��w�Z� � [�|�B�s�9r�/�bB����UFXXڬ:H-���4����+ ��24m��2�Z�K6�e��������r��*�!��3 4Z*��J���b@o��VD�����*��/��+R���l ��%w��7k#`!�I[����K����R� 8_�Q��J���lo@���o��u��]��C�7�fX���aq<^o����x�E��2Ȱ��r2���G�����?��3l�T�[���R ǌ��D�Ɡ��f+%�}��WY��v�zW��j�6�d��0{���R�jAIud�� �A��؊�pMut��x �X��X��D]Ζ�Ό8F���B�;F��B�㩮�ra��t�.��;��%���2�Rz�p���7�H�e�#߿���٭w��	��D�����d����R�N/��ՍW	 C�㈈8�ĺ�ed�����@�@�8�ᄋ��q�|(�.^~[�0�nu����/��"]X%ٍ��J����XY�~��`��/�.���%���J��U#�.ǻ��v�r�Bz���n��@��1!�Vw�\٪��ڿa��g/�زP��ő�s5�mt����IdQ�uLm�"�����j%$��k�=�tr %4 �2��rgʸk�%�e�1��+��,������r2����Y��ڈ��l�d�kRBU�HE��}�G�AM���h��o>sO^D��:4�}#�JC�c�\p��x����шZ�%м(���&�#vh�/�o���G�/�e�^�uk>s
�m;$u�������s����Y[�������A��I�s����Q!���n���	g��Ѣ��r@6a������ܒ�_E�[!��{QȗVG��.g@�4}����)�.g�E�.��:m���Kկ�t8���g���]_{6���L$�Y�;$i�o�$�dw�C�� S])�����#��4}�K6�~�� Z6��5X�����u�N�:�؉֤�u�*�G�d�;�ۨ�g�nŪy�`��	v�c���~1+Ȁd5
�et�(:Ʌ/�	� T4���zI�{k��YB�ĺ��uzY�L X
�uz	�����f���ze����su]��ܑ��շ��W��N@^��]�4�t1��$��Vv&Q.K�����C�u�����[㥒�
���_�W9
�qZ�ۉ|���w��ŋ�hM����_e�
ȡf2=,�� Zunl��K����JE�"AP��O4�Xy���N�z�O]��]?u'�������Z���T� �w���|y�bO�° �?(GEB~  N����UJ�Ф��U��sIk ���cϸ�#Z�phe"=�zGv\5n���K�XU%�^��%6 4`��`�JhB@@=��D��8�K)d"A@�8'�M�ԏ����E)(�C"  ����i���%P"�(��U5d�S���i���;U��Ҧ ��-&dLQ	�Șd��
���@q~rwV�wg%1M$j���p%X*��e��3d�KLH됧G%�g��&�q���:R=拈�R(����elY !uc����	�/����>LX<C���܌$B|(�-n�`(���f'"��zgeHk @��@���A@��H~bh%��ZG;M("`ڨ�׺��j�����:���]
`�ֹ:`�,��\L�X����}YY�(�X���:�������6��o������T		w���^,�i�|��.pD6��e��J� ���.ޑ㘆�~@@@M�4�b�ڹ��Ҵ�Z׻�%Z�9@���V eLv����w�ݛ%ҍ�:l���V����M/��Z�n�] =��B�����E��&��%�$J����B	.�Ϊ<Ф'>����E�/35����o��/�Z��|�\N8@R�(5�\ �p���qn!
N�;�����T�����P)E?uǑN0(;�]ծ��xy���&�'m<��U�J&p_����e��� �8Z'��w�����H��o+��������;3 �8�b�[ʏBx�����zy#4@#D:&�?X0�4�]��J�j]���t�2��v
x��I�;"ђ���%Q$ �}Y�bAL�0Vj�k�I��Xq��\�>]�Ĉ��*1 `�إVJ�3��EWRW�EBX.��m�,�{+�S�ƃMz�6:��:B�S�%;]�o��/������8����%w:3THp�B�sʵ5PE$D�E��J�`�,m�õs#|���s�(}V�]��X�#⋅	�ӣ=#^̨�WI�w ��2[f�l)V$�֑:	�T
p������R(��YX(��wW�~k�nl�g�g��0�\�j��R� `�{������SEC�>�)G��oZ�rKK��@@m�h;�ة�3n���.v!�vI	�K������	�܀�b�L/V�wE��"! a��lnS]$̵/��+��ع=]y�I��-��شM,��v�!���cpu˻bķ���f�w=���v��D�K3�>���	��ȅ�!��=��er!��\0������9� �"���咁����iሐ�}	QU	��u˅;�)c���V�V���P�W��R�VB� �d��* `�[X�]d�6Z���iu�hH�4#�n-�������+���~��^���Y-��l6\\N�Lv����`ހ�:�x�Է~�|+yeD  ��"a�xa�б=[y�I�뀣˫�g\�؛,[�S�7P���b�OS��������{�� �v��E��( �B9� ��I��r]�w�����s��p҅K��:n��Ez��������/T@���w�c�d=va�1�ـh���hMK�����+������y�
����vm\k�5����'+�֌~M�4>(�����0 O����iǗ3nn�a�����!թ<aċ��R.mvj)�Lw�����E������$ZM `��d�q��v�讯]�˅�q����h��~�g-Una���  �r鰀NH�B������w�?�,��7-���  �zW&(C��^d�.&i�f�]�� �"��ZW�2� ��]� �$�
��2�0��Y��&X�=B�[X�8���+�_�#����	[�Alq�x��z0���f	����i�����*�ȥ��)�R����8ڿ^r"
ؿ����д-.2ȠC��~���r�2H��NmJ6m䎅]�@�� Ц�2^[ bR���m�B�T0@�w��K]
�ܳ�glvW6@@�����C	fz/���� 5,�R, ���B[����K��k�M�qJ����c�$ѕ	`�K�,��@�_�D"��Jl,t"�v�P�+%�Żȧ�3dc�kv�,�-�w�MϗKx�^�<l4�he�4��1:r��,T9r4��n��uM�Y=[�`�.���ے�Z�[,����C]nw��wՄE_-�.�=X3�л��N׿"i���n����T��4�4���>w����.Y�]��b u��#���Ϣ��:��&�T�^�ک�T��-.� ݶź%ܝv��O;���n�Z�]��nDGu�+}����Zؿ�t�ΖX�܍.��Tw{԰H������zW"��ZI��j�ؤ�K�X�nf���eh����i��@�_�L��H��@�C��Z~�4b��"�a�\�ܫ�1��*:(�V�Y���,}���mz������f�#��C.��6�\sAee#Wq#hS���27��ǉhD&}8U�R �����b�
��K�}�����Ɵ�0��5l��Z�7В#�ǌ������%�R!6�:��'ǿ������Ͽ����o�������_6�X`	,#�V$�[�E�6ۻ�}����R-���"��8�^,m��Ζ{k�쑠Z��J 0�\� 6�b�j������2\r��ɉ�R�V�[J�p�QY�Hp�.wH8���X�x���~(?;@�lv����� c��m�U[�-���~tn5�����at9# rn�A�
ؾ1;U'�e��u�a�d0�#k��C�#u��"˦� �u\�(�X�w X `��@���u9�HD'�ѕ���Y*X�C��I����!iv�+e2��]�Hp��֕2W}�[ ���@�?� ,��η���zX*���.,�V�����k�o����ϝ�:����Piv3K��l�^����J(-z ��2[:��\h��exm٦�����ݵ��-M��V�zkM��V��tK�zk�+��^-�A���vIu���o����TW�xP��c�p��ْ"2��e�p� g\:��zMuzL���[}k�T�t������һ���s(K��k�
xy��lIN"�u�
�:�\_V�,LuՈS]��s�
P��g�ų��4�V��8�a��b�$܉�/�.5 x@�;��q�%O�\8��r��n�,�e"���[
9,	���t�u����[]� �.=��[\��։��9����l��ͮp ��zg�#w��¹��,�lD�f!���H��[LH�*Z���RUЀ��qᢨ����*jU@�GD�8A@*�8A�������E)Vu����]�X���H���k"*Jl�-�蹿�r�-�[�p`e�g���TB6�.8Y*2��".-΢�.	Ft��I�!!r%�gA���/YH5|銴�J��,{,Hu����[X���
h!O׺�A��"���c�Y��>@@�	���KA����8zkb��	`�� ��c]�^�,DЃ����M�k�0���d���c�I�{��f�ڧ+�6Z�x	,�.X�@k���-��"]�Ku]��t:,c�.V�t�.ґ�Z������찇��.�*  ��-3���rAvY-��c��^t[�L�.KK�h�|,���ea�A@+�#m�|�t�06��%��j�-��`��^��� �/�(c�+�����-�1~�68	�t�naY(c��
ș$�]gK�{�X� �`U�����7��Bq�bџ�d�x\`�kA�~(R>u���U�
lp�j�����/�
��a��+Ȉ[�A�4o�%�R���`�YLp��p�������S]���uOa�@��2W���=<n��V�/�b������b�x7��.������Bnp�oN <"ђ���%Q$������v�F���`�$: ֈ&��76@'��P�x��<�-��+P�gk�8].8@�{�o�C��P��R.���c����xX�����udlt��w��"�͆�`N�l  ���rm�uXy���h�HW)6PE��Q�,�P��SW%N�{*���r\(�n�̖�2������bF�%�e K������ڶ�X�C�@�Y.o��9�Ƞ��ҷi�)[]rU�QF�;�D(�-����������K��ϸ�b��%�C:Xp�x`�[\ ����R� ����������ֺ��.v����e�.��
�R�A��]��N�\.���URH�&vI	�K�ƻ`/E���u�7ׁ�7ɖn�^p�כ+si�DY��r�r{+��֗�gp�g��ۻR�P��+ ���&G)�dg�\Zz6@}�p΅:+p���b�Ɲ��
�b���x��r��2�:4`�;�r������g]����T#������4T�-�h�@��pa�B����T�h���
?��N@"��<�4����U���dq9�r0���B+*���&����V�pg���p8ղ����D����-@@�:��sP~_	�K�������s�.)�u�2*0��^��L�/�O�K�_��R���έ����&$��h!�7#�?��X-5�ǝ���gF\,�i7�0"ҧ����D�T99z��a�s��E+�bi߆��p?�:方&�e��V�N;��qs�bX)���:��&	6�\�;�Vr�����U@�K�~,,�{#0���w�A@�+���s�S'�:6Hv��dW(�"� ���fe�# `��fd^�c���siH���_rP2�lvv<�>w2 ��fW)2� ������%��t��"(����*Cһ܁���_����2Ȑ��"�/W,�VJ�g1S��"fo��%�]�/t8�T2@Η��.�R��Nx]@o�z���ɮd 2$��i[\d�A�<z�ɥǎ.8�t5Bk�p^�`���͒c�_��>[W����*��x��
����^[:㦗p� bv�;� e�\J�m�3�` �SnaQ��mt
� !V�&�xmu���^�*���������TV�$�cT ��<��J�[+��E�(C�w�.8e���������F�� ���%�},PËF��mv�����n=�5�b�dW��\�����������Sw�z7FG. ��mu�ՄFd�L/���c��[����S.��%���V׿	H�ȩ��
�����%�%��� M�Y���mw/�,l�b݇�N;��H��/5�o�.�������}Dx �A��؊ �v����X�Ւ�݃5EltW�bU�g7{_R��O���H���k�1Q��|u�+}��3N��.�=ZQκ���﯉.խ�&�e�3#  炗��ǖ��J���x�T�ׁ�7I���e��ߨ�X��֊K ���6m���n����} �-k��o ��K�Ő쌨�nd����sA�!]eL�lf��M��oU�H�֤���N���~wI� �n�>_R]jR��z�m��*�I�%P�M.�A���n|�sjr��hv��F���&P�d�Y��u�4�]Wʃu���*@�ku��5�Du�ڼY��U�z��Z]�~M�?��/k��,����f	.|ժ�ǹ�ߧ�y�lt�F�V���?�-_�ιD�t��Nꤒ�Y�R��Z)��?7 ���u�	V\gj~s4o����57�2jĀ\$�?u+�fy\6Z�Q��؅ʦ_Xt�̞uv�y�<\˅��ѕ����1�C5��W���N������U
�8ʤ���" "k%\jd/�܀��i{f�y;&��q��i�G��sX|�o��J�u����gvaip8�R����:��΄��÷�_S�Uh����շ�	�DF�K��k�
�,@��|\��6�wkn��˛���8*R5&�.1" �=��EQE� `�(��	�i��  ��}D�!NP����H�;�%��T� " �B���X�6 ݢ( ��O\�sh�]b�}�h�:�(��wì\��j,.������,�<!Q FtK�2��8�4�h+P�.��wD��x�*���n��� �鶻x�t�ԅ%P��-����岸j�+�2�b�K�"9��]"�Vw}��aޗ�e�&J��B�yxy�G�Բ�����!��L�t�%�-Kej�ԕ  �V�b	.�ń\�?J߶�͗x׾! �G���p�d��^gK�����܀Z\^-35�uZ�n�]��t��W�f۷�n����]T�s9�(O�'��N@����M,�nh��ku�e���VwH�F`�̸ӭ�C���zyD`�X�͘آ*ٳ57 ��r��YE�ܦ
a��xe������!�(`������kz�� s0V��F ��~��mr�}�^ [[�����E�c8%^� xPv�}��p�@	�]#�v�F���27��%� ��v'!�bW�f�V����x�a�T�P9"�١<� �+n�`���/nh}_��uh�d�\��}�	���Z<, ��9*��b��up="Nqo�� l+b�(��V
��ە�l��$a����6�?P=�`@�{k�Zo�v�K��vTP�(:��]�(��Q�j t �Ut�x�b�x?7�� ��K�PpvŬR���Ѷ-�py�"W����b�L/�i��xѾ!�U�f�.X��{�� T�����_u���UZ4t_|Ԝ����k���~R��-T�տ����Z�Q�~�@��l].��Ĳ�.���n�h���0�RT�Y��K�P��塀n7T�����l�@X(g `������`p�j��$c�� `�Z�(��f!Ԋ�,�@����p� �s��+f���$\**�<��sZ���9	��Ł�W9��l� <]�2�o��P���C�]�` j��ڿʐ�<h�>.O-n�d!�97���;"��X�V.�【>U�D��~���*��������v����Zh�o3Ȑ����F�� K�s�Bp9�p$��j��W���)Gn����L[|+�8����=\s��TG&,�-�w��Kt��\�a�ou<h�>.O">X7��n�8���Ļ���C+叛��H��$�����R]���8�ĺ�ed���� -��Բӥ:���?�x��Ɩ��B��QT�_t�.Ց3�2�B%V�6y�F`�xAm��a���h�PS-b�=@C�wc���liL( ���H c:s��Y���˷}(w�LԢV�\�C�n����8ឮ���J��vB���[��lz�朔������7�����o����d�7���PD�o��Y�bi��5C@�$�w˥u�����u�[%�O4�B9�P��w�%�f��֞�S7��p�mu̱Հ
�ߥ
�;�@����
��Z�]��#��zW �Q�8v�@�%���.�A8$�.ʤʩ=r�府g�z�`�+�t\x��\�X0kIƯ��ո�Pk�z��P���ra}�����T׿�\�*����֪��$�-�F�c{�x�d쳻��5o�DEuz `O^� g��շ.�����:7��.[]Ӧ�&7] U��T�<4���84a�TW"�ܻ��m`U���['����]�/��]�Kǅo[.�����<��������u����R�~7�y K�h)@UT�,�db)� ǿ�:�$�яD�
xP�����z����G� ����&��/�f�
���č�D��g\�(��~ 4���Z�>������d3���qG;�]�C<���gN<\R(�"�i��E�� %ӡ�D�����2 �]��KW�.� ��	�o q#�  ��*�KL șE3����+`�T	W:-.Ltd�<_�8@+(��7E%��!.1���Z!%mJ����@�<��]b��F"�JDB���EZ* ��.J'k��$KA�� � �,M�"]���N8�Cz_V�|y���-��яD��8�|(�-n<"�ex��nls��x�D����z_����(���E�hIu�ze,��ʗ.�E:r��_#]�#��p � ��HG�w9>=X�:=Ї�S]�S�-���|�F��+�V��"]���"]��!77�/��q`�^��@ vqh0V,�����Lsi!x���o q3���H�|л�ׅ%P?w? g������f�l��]b�R�#{����%�E�c(�lY*S˧�4���Z-Lv?;@R�>�ٽ]6;�$A������:-�)����#��-.�%V����f�f�n�jY/�Dp�`�.K'j��ꆗ���/t�{�-"�XQ\�(O�Z���u$������عM�#���-�;sxP��Kv
X��;=P�N��~0 �ۀ��vѮP����:�0�Z C@���o�<h��R�	 e�]e�Z���K���S�o�iz� ��� Q�p��:��4B��Q ��ҢG�����8 G�ZL��N���m��m4��o}�6�ؾM/��m��~qN�*ݛ
�S�%O�%�e"`�K ��NB�~���⺽�Zk]� ��ń�G�t�},z ��@泀t]!��O���5I������3�zW����D�*�e?� ��"拢�n� �`��z��ND�@@	S�4��DDK�#�}k��\rAC�3p��FW!�ք6���2�k=?7@N�ڦ�t������lv��7�`@�{k��nĠ�o���ޝ�B���ٚ�C���.v��P���ѿ�r���z\���� 
�슔� ��K�P {6uʟ�͕��rKK���SE	��ݕ�!�*�<�-3�X�t�w҄9�?=X�<H���X^.�%PW�v��9�������Ҳa���Ms��*�Ԕ5�%�w���������t���ފ4��!?rDbov7!�a��u��`!fF@����D��Ny��s]����9 	���6��%���p=^�5Q��bE��r���ebIuV嚪�F:/앉���Y\�ݵϒ�bxy3" `�,$���q����k�Ђ'��P%���J��w���AIv�ʀ��u���['����c尬u��4 ��ďI����"6m����7�+��z�jl��+ex5����Z� ܛ��f�S��-�m��=��{���J|KHX�6@@#�tj�q���Y
��h�Pr�iKt �@dXYN9��[*2��pE�g�x7f�uh�3���7K�����ɽ��!yH� �YA=Ї�@ J(CӶ�� ��� �:��A ��ܲd 2�����ӋS8����pȫ�
�6MzT�ϐABnn V2���a��(��S?�-��-Q4f���K��o ��b���5[�6:d��)�̸��8@m����*#Yb-n�d!�97�jh�Z7^���� �I�l�""N.rS���D�^���E@�G8炋	�ݦ ���t���R�:v����n gv�[\*���_ 8�$�P���8`aI����bB.���`�n��+lZ( F�V���'�ul��5�.Ց}i�ctv0 Ō�e�Ku�VD�b!����"��Ņ�-��κ��	�;]�$�k+ �qD�T�Z��XɎ�J�u��1�i`�pl�*�ڨdti��]�f�	jV���D���R:M&�d�lv���J*LVK�#}���٭w��	Z�:Q�/�[��7�d��T0@�H�bt�Z��%�B��]B�]�ި��k����R|#��K���*1�Q�]��݀��ԃ��l�B�֜�_���L'�_DΜ�FT!_6���i��G3��@��lF�!/O� �l~���ڨ7@�V&P�Y@M�Ïx�50"`zmPs����j2����W���u�|�����o��qn��[+��N��1۶Ffa��OJ�o���wv+c��Ic��B���:<�|�.�B4�4��y�l�����7�Z�i�c�LdkBﺛ���",�.�To��]��u�*c�d��Q�~vVa����
6=�E �R,����@H|!C�j{LP.:Zfa���.�LDQ�g��V
�\) ֹ
X%%��H30�*�n�k���%��w�%x\�M�P+�V@�i�� ˤ�!5���@��&�[�_�R�~7 pp]*���5X�sX|�o��J��LdƮ`�X����V�����Vߺ����[�V���'-b����l��:ػ~�N8
��,Lu�����2^DȄ��b3HKi�0z�oMv��o� ����^rSez�P���ze�fط�n�S˃pl���tJ��+R�*��۝u��ա��z٥e����ޕ��j�[}k�Y}k��]ֺXq}y�3�Lw2��fﭱ�f1Y�
��_�B����+�����!I������%�[AB�� �(.���7�	��K�H�+$ �f`�Q:��
x\��`�v9@@���v���:Ɩ�pq�/H;�|	��L��}'�jt��*��#B�5�zW(ء��J���m�����`����H�xad1ٹ$Q�/*zƅ����گ|)�L�� h/Ed����VG��
b� �.��_eli�,0���,];�ױ��"+9I����-,l�`�3��s\�?��X��o�`Y���G�s��X�o}�,.���p��	 �wZ����m�Ї�4�8$ԕ ����<_&� �,MW���v���!�wjO�Y��L�Q��\$x��+�z�tE�����P�ER�"]�|�"]�{��~=]�������< �<���[��OZ8瞮g�x��o����;oP���P6;yY(f��֋�",h�`Q�f�'�3pyc,�+�����V>ʟϿG��[狈�W����'�#q��/͛p�/�7���F'���WG���Y_,�cnQ�4�J����_ֻ�PT���G%�\�ջ=_���tȬHJ�#�>�(L��E�� �� u8����ps0\�(O�Z�����m+�x�p�-��Z��7xލ-��R
�,�r!r��϶m����������q��}��D�3	�+��£E����K���?��ݼ[��lc`�6�W��+F|���}�񬛬ɮ�i��]����V��@
�f1��#M����s����P	.��q!`�;$��Q!�v������Y���m|�vn�,��B�V����
��h�O}�B��>�_$؟�Qs.��hy1��Zz��5���gZ���2��D)uLv�[������[����`��x��j�?X�<����j{�`���hDĬ����ڳ�\&^��_��0�3 �\������ ��v$��� ��9�9�ɨ������u�p9.i��4��e����x�C�Vr�Z W���Mnx}�r+R#��<�N��,�?���@��fD@�Y(h��.]���S�:��C�\��]�:=~������n �Z��<(��P^�k��2d �1��G�s��|=F�6��h���8xy�u�� xɭ@�.G*���N�w">Z{,�NB��`Ӗ�,������2�K��~Ժ�� �K]`G��ń"�_G@��%Td�d+�w�V$E��Hn�g��[$�IvE ��t�+��n� �s�m�x7f�uh�A\<[;, ���� � f���X��ÿP�ti�-���5�n�]�uW�~7 ���J�Kt���ޗT���1ςD�s��|=�	��xI��U��<���.^�*G�-Y��;�f7�������JȖ�º���"$�u����%��m�_��be�C��áu���^+��mv�E���;nE��P%�.�%�Ē/�"a�҉.���g]�ltk�%��� ,,��ս\L�ûq�+zP�U�ϗKx�^��\���A�,�Fg�/�RQ��w�&ק�f�}6f""��h�]��pY�V*�4�N����j�c1f�gjt��	�ܘ��	����$7�Qk[�?7@��Y�V
tda�]i�z��䕘w*�J�f���B,�d
�ͽ�P%�&������?7 ���{��m�yp}s����y'�|Xap��YؼMԋ��BsE����ri]/y�_���(�X�w (b���!iv�)�M5ޢ�� k\��4�R1B�3 sg7�]���:lt����M(ڳ]_�D=�_JvlVp\u����O2�:���*���q��!m�mkuL���2���Ի���"P/���U�P�;m.��n�\�Si�vXMvK���,W�.�.w�!�w]��yF:�F���#&�jy�����6��p��]x"��N��:^�?mIYss?r�u�|i����[��p��ȣf��J��:j>���b�q���W�0��
,�-ևK~�n���+f<4��B�;��9����[㥒i��%
�õEy]:��΄�L\-L�����l��P'�J��ck�>��c�{���@�sU@B�8�;���7�I�u&σȬ�Ċ�҄]��ۅ}�$
�_������Ω��kг=Z�9�E��$�{�omv*���I�v~�ҬN:?���V�˛o�\f�v������1�Pa��mV�<m��#SE�o�CF�'*k��\�o�˖#�T9�}�&��b��.��0��1�:j~���[η�q��QS�W��D�U��l���!� D�����%6 � ��N���'hE�򦨢@�B6��Q�BD27@�����s�-��_�"mp��3�`���>�X2�(   ���pX���]�CʟK��h��.k%X����ȿ�ԦM�e��+٧|,�����B�6�bGH>�໎�==Q����rqC\�kHs�Ź�a��x�*��K���rH�� $t�Ei]m��.( ��G.ᘘ�i�C\b @D�>P�_UԈ����lgb)���.Ё g\`a����̈�Să�3��`4qq�e]'C�I�fQ:f�m�Z�C�8�)�Y�Q .)�d ;j��6�Z�`��t�u���F�k\�z1��ť�q)%�<\Ek 
��µ�N`�ʀ��ט��C.��|c����qy��s��"�&k�J�^��3�n�l�k\�Z�8j���7��e5n�-R�0�x����oe�����8�P�G�"��*�Q���6���׸��n
�{oay�|sA+y���n�{�D��U�H�Y�.�����:- 2�|,���ea�A"ix�-����H���K��t�!��%��:������!��L�t��E�c(,�����Y�>�ٽ]6;�ð�j	.�L�I�tH� ^[/o�÷��)�ӵ�I��v��ʜdG:@@����j`��l��VMu:D�vG䀰���W�[�M�T�]G����N`>���|�!�YCZ`��0���?X��8���e����,��ڈ��%Vn��$jbj����m��bYZ��B��-Kej�ԕ "��F�D��"]�#a۷��nb��s���j�/�`��pJ�{���V�� ��5�͖ͮ�b�����7K����@M�fG���,¹�M�w���2[�6�1���gKu��Ց]X)�%�,b<Z��\��g��(�q�Q��K_�Y�vJ�D�����.�%� B�0b�-,.��J�^����1{v#Z�Z	o-;��6�ֹ���wMt�ndq9��wC������@Y�o�>X����&!$l�,��^R�I�^�!aF�]�[��9�}�'f"����ra�_��0�$�} �C��5���*,8��Ql��%���`1���qr�P5Zv	�n��f�_]�Kt?��ݴ�{�u`y�|����%o}7@��R� %X�N:�D� �q��$D��+P�gk�F8� ��ٕ1����J.��m�<~n �F ��~�R"�u�24=X�G��:%^��\]&"<[ol�"N�������xX��rh- �|��uX<�S"�/�CkϦ�gk���DD�u3uq���E@@��*��n��~Շ�B�\~�J��#��w�}Y.���/�R��H1�ZD�c��z�yT ��h�Ɨ�+��#�͕4�F M���J�]�V��N��m����u��=��" `�6����>G$Zr�$����l��,|#�� Unh�.�2���� �/&<*۝��b�tX~q ����®m�p��:��w@�\y�|���:������ڿ���:��~[�@�e�]e�L�Qs����������t��X=��-pJ%�#��p\��SD�����]4��J��ҿ�V"v� ��xo9�����\�p���#��d��@Yv�		#�Ʋ�
7���cp��XY���탅�fԜ3^X$������������/;&��*h�^�P���\,r��}s��:��"vn? X�4߼5�g�$����w���3�� �@@�J� ֺ��.v��FV� ��i�q vnOW^?7�`@�{k�����,]� j1�q� I[.R��R� ���I�Oc��8��U�F.�W΋�#;�
�a�����ᗥ�A)F-�:J���l��f@@���O�b�( ���+l����-�JV
 �������
X툆���j�ԏh��C8��]�b�dW�C�w%��`Q����/`�*zHR�\��5�"Y�1����(��nt�+� �qCw
 ձ�da�(:��]���l%���Hɤ�p~%Yb��.(���l��iۖK�<[3��͢]�,Te��]�t��Å�v��iA;��#��V>_���
*�-����t����r�V������H��B��	~�OB�>^�D�w�����#��I��3QG�2F��ؾJ�|Q��M�<o�xm���J��'�а�`Rưp�P7WI�}���9�P��ұ=[yy�� ����WT5�^�:�p�]�6Z�d�t�m�V� 5�����Z)�(V.���FUº�o.r��%P ��g�.v�:h��3� ����?�vo���D,�}#/ᬋ�V��_{W�#�av�3տL,���nr��¥N��!�r���m����R�>н������2�b{�Rx���D�n|���tl���C6l�͢)A�@����N���V�]�Nf����nd�)���2fy#��N�!�R�+��:o�I�½�C�ݗ}D`��Y��v�_$D�r��ſ�"��y1`�L,6��X��w3��z�,�yB:4md��d���s4Q.�����<�p�S !X���b=\w�+���������W��v' �u �w�K��q��l� ��K\u��� ���d� �����<�w�+ʗ.��W����m�d=�40�^��<��nfa��]�,��Í��$��v��P���A��~�zGFzH���,�+H��3`��8��s�.�.-��rf���V��c��f/�jU�tFB��"����Lg�rC���0lB�#��-���)3�!��˘��Nb�#.��a��q������b>\�˓�88F���� �(�6�L����
��Wuؿ]p(7�o�F�B��K��~�X��r�]���(%�8�ED���k��2d ��uxՃ�6��������2�Eн�K� �֙���M��w���f狌�X�WY��cy���ot5�h�;,��,$l�ٮ[�L)B��U��ʁt�Kv��о�,���l���l�l�R�(�P%�:d`���A�����5����
(`��:J�����������ˣ�|�����.�R���p����-����`>�ҷ�� � �<�V	 �G���'- ]�]O:-�ݮ�ج3�2|�`6J����AB@��Z� h�D)�̰S# `�x�r��O���bޡ�,�7BB�r�߮#K%����}�v�~���X���-�@ ��;���E�������rc�Z*�`#����0-����(�`�W�/�C�P�����@q��}s"1�������j8t8�T2@Η��W�Y:6@�o.�e��pfe�tX�ZH��������[�(y�OJ�K�3&�k�ӹ�6:�A��t��b�qn{ZR�^����h⬛���̶l�]��P*#�}Iu�}�$�d�`�@M���������zu���G��D�,�O�ے%�,xMt�n�(J0b�,��R>�XG�]�@��K��2ս!�O�[��-B�뀀�k��s=�[��n���]C�c�TDY,|F��J�`h�g��%Q���*��JIv��_�D|�nv��rq&0�����o��-�=+��;��0�w��n�|�r����%Tޕ�� �̅���ŻXW�����IH���i�Х��Rج3��K.�-��eh������R�z�����J���"%3�Ԁ�G�Ku��S��~ZL&;�Gn�vGHhv�A�E�{�Y�M����(���c����&�o�dy��\FJ��曽*��e��j�dO}Mcz�̖��%��Ḷ׹n�����=g(ٿਁ�2�Dbp+Q��_��l��s�ݽ\��WU�p�\ޕ?6��-ե;�[ge�Kvm�)O�o΀z����w�h#&�+�%�b����E,Oz7@�|��Ɨ:�ͬjE�P�j��Bo�g���6��7�z7�,=�!��M��FKA����EẊY �8���a��xa̻ƻZLS��ܧLF5VZ#"��Mk�,s5�� F4��I
�-�>i�zW�?�&P��f�+�l�,�f�j����Y���B�}�ƚ�j��.����+��=5�N`��#�� �����~�^[�c!?��{���6^7�T�!��j:�X�8߬^\'ʷk^�n@z��*��s�o�z;��'� Ζ�l��.�U��z'�6������o_�O��N�{m[�û�B3ׅ�Fi�x������?���&1��ud���7�Yض52W�� ��"4oa3Kl�,(�n����)�v�\]xb��P'+�V���� ��{����0A��[�8r1�Z��.F��7#k� hj���#���s<w\�4!����^PmD����� #~,�֎m�<\Ub�����g�Y�kk�z�:h��������^4����߂��@rL��O��FX?�o�\�^-4,�4&�?�]=pI�*�G�M��V���6(P��=ZU&���x ��Ǘs��Hd8�[�G������zH�7�j�連��)����|r�tV��<=*Y�fkDa���݀\� Be���O=L��)�D��'��%X�:3^t[�L�.KK�p0��50�.��r.�l���V��\%ҽXD����P��r�1p�aL>���H���P�K����I��U�w�H�4a��/�����,L���
(��P�x��<��X����A �_�g�#/�+n�`���
�B� 4B�������9 Q��G�L�? �,�Vb�oS3�5��J��n@�D�]҇I������/M�� ���������/��]p��|:<�R�A��]��N��r>Q/8� �K��g����t�t��ع=]y���(������h����R����.�;	Q��R����\|��  ��/���Xy4���Ss��[�/�y��.XDdO��t%�tl�E��l�M�6��J��n@�|�N9�]��o��j@;� �-�`ּ�  _���c�T�|1U�������y����]�]-R��t%�t���재�I�FZ���ȅ�ҽ�"�1�> 8_���E�� �_�*=�ٺ� �Ԏ��� <\|9��D��p�;� e�\J�Gun �cT ����j���1"��t�'gKG[����K�U3�5��J��n@�0rꄏ���N���E�#���lŊ�3�c|��  _Χ�c��e,ԅJ��mr�� �n���o��J�Kg<3]����Qnlk%Q��Lb�(�~�� D�x�bb��4p�T9V���r#��%/�5���DnZ.�0Uޠs�\4��C���q"1��U��w�t��X����f	.�}��WiTz���3����c�*�	�N*���db�d�W)]���?���f�d�&�u/���_3,�qytQ�˓",8����~��thrN���m���U�ܮS&�R�
���� k\�h�.���wL@#��q�c[�Z�w������d���J�]΀(�g�nŚnM֋a�u����S��_	fJ;?t�]�H`��R:;]9l�#NQ^�=.*����]N0�2��M�"L��N��Z��k ۉeC���XO-�����)��Q�Ra���ĖG�F�dz�`��j�t]�m;,��{c=�(�Ļy�I���>�p�vǶ
���Q�+��6^��!������w|{f�y;&�pp����tD�*	�6��:Mn�0��D|���`r:4��n@��hL��&-����]�/��]�K��R��j���aHu&�h��K����J%͚�s���w(�>���W�م�θ~� ��SK�B����}��(ʋ�o��˥w�	,�BcC4�4�H&7	+�u0�~���w�����5�픕����	^�.�=�b�J�ڳ&K#���[!���o��f��y���ݯ�@�ep��B�c#�э�������n�kXգ�Q�+��6V�t�$rY��@Q}�7 I�����& �R����%�ۡJ�����j $t�E)�EģR �;�.1M���WT���[.�����ݘ���JbP@EEP�"Mu�׸»<��C6��̻D�A9*R5&�.1" �>P�_UԈ���C Y��6�K���+`�0�9O]bF=�/�@H�/��,��ńX#�� �	�2�&Ϣ2� m�(��o.p����pI�P�\Z�E�s��ZzWN:@����U�&�p���P	.e׸Ɣ�U��E�_zt�p��#0�-
���HKE@��Ѕ�t�B 9;K0�q����X׭ �J� �j�DKg�_�Fmq�we�@�G�)�J� �!�;a
c� f��dP=�T�� 6k���ok���c'��,㾦<�w�\	�Xr�b�0] ̨A�
ڊF0�YWפJ-AtV��&R�f�Ā��5�u�$�[G+9\�ulHW����˝^� �4�ƣb d���
�h�B��#xHJ|bV�\f8@:\�VQ]���!�e����r�9�݀$��]"�Vw}���2��T9mk+Oʃ��2V44K�,.�rk%�U^,�<�6^�@��� �f���FBݮ4�-��`���@��+s5�=Y�u˅~���H�R�F��] �� ��-Y���n���n���ˇ���@@��rY\5ޕ`��t�.�E�H�����n��c)WB�6;������n�Ļ���'M��Ղ� \,O���,f$�wK��sH#���tl��_�˝u���y�e��.��'k�;*|# ��2��]��\<Z��\��g��$��I�[K��.����jQ�	3��{yR~-߮�k�Kv#!!�p����.���ֺ��j�����b�%�-,el!4��nb	uC���Y�Z��B�ve��,t�:}y��LwK ;[\��)n� ����d}��ZgF�vr�͖r���S�<N�O�r	u!<X��e�� ��:["݋�,��b#!��ʊ��2�A��R1+jh�o�� ��NIY�}Ey���[��v���:��E���2ם���- n0t� �0���d��Q�4���+���j�t0�l7e��9K͚d`�+�;+ه�h@�������K�M�������6��d�e�O]� ̅h��!lu�Z\��tF�	WրQ��5�[E�~=�u��B^x�> -��'g��s�?��]�6��];�p����&btQ#�&�vnX%[]���v'!�w[Z�xy�[ G֛+ �h�j�F@���o��l���� �c�@	�]�?�LO�w8Ɗ�o4'�Z`�)r��YE�ܦ
a��xe���č�.ַV!{D�Q� :%^� xPv�}��� �� u8����h�A�Ò(������0X����\y�圳h���voH#��(೵gC\�!ՙ P��UF@�2���g ����.�R
�1��ׄ����b#�u�`�(LK�����2��%� ��v'!��rm�uX�+n�`��b�},z ���OF&�a��^a?�����P�W�o�z;9�ZF��a��8�����m�2�u8Q{7B� 4B�����#�q�k�^�YF2��Y*aE	�Y��5��@��NIY�}��&׷��ҷ��펰~\J�p�����~�.`� �V4���C�F�ZtW���d���=�1ͺ0vH�=���.wO�m�������,��	�쳪�S��#��
��@�{��/;|���5@�A:\�U����w��X#�P,<�����w|K���Dq��¯Wgk�t"��Dmq�<�]1 z7���E��2�ɮP�'�K�lt��Ĉ�*�X<N�� ������9�s�����h�[)�W�%���,#��2�l@s<�u,Vp�.$|�e���q��.v�K�+�X��p�"Ͽ48V���gC�֝uv�K�6�".���l%��9��ڳT7f8����q_�-�z���p�`�^�H�n�+��xP�b���C��]�z+�'�*!$������� ���u�wX g��ª�r#+�
d�\p������^��X(�H&����p � ��;��P�<�/9Vh\�H����A[�F�|�m�_�a��븚(^��c��\=|��P	.���0���������ڂ��k�!Չ�����ٲ�I�b�nhY����	k�(�����9��H��83����� ����-�_��X$�/�������V��/�����;"���7XN��mz٥��UPD|�.�B�YU���(�oֱ��_��P�>���	��B`.���6��z��0j�v ,�B����ſ�ͦ|#4���A��*�ӽ!. K���ŻiPv8��{��`K�v�֡��s�� R��	Ǚ�/��}@��儕�\����G@�S��*{�;�/��^[�6B	�L!!��@�;q8��1�t�������b�![�A2��u����븚L�/d�<c�c����z��EB�!m�V�`���ꮯ� �\T�s׀�U<.'l5T����h�'��W�:|�ެ��'�v1Y�9�*Y+��nwE ��H~�1	w�D�D�Y����jo�F��w(5ne�! �|��*YYH�R].0���'���QǰP�8@�j�J�ܛ�P+2z���F��N;��?mxy<H#V�
Qq���dW�w��y{����Axq=k�M��K�ÝN��jxkX�C��@�k�h��N념��r�I0�u�n���r�ކW�M�I���[��-U�D%�`WT��5P�~��8z��έ}��{�->�؊F0��A���.��2��0�1B��S@�zk�F ���|��./����;�>K�K�g�유�	�5@�A:w�[E�PMt�.ѥ:���p�h��n��I�n����5%ȰQS�o��O���hd�diw�&ɲE�$Uv	���[�����R�nn��H���]J����bP/�]�fp�-t���G������v��<0O��R���
s�3d�����Ù��p��w�܀K�F�ލ�}��A�����VX��&����{���|wı���\�HX'k�	D^��$�R���p�� Md�<�1�_�׫���>t��%���*������5�aZ>]yM�� <�FKm��:�1��GK"@Tx��J���F7��5�Q-�W� Nuo;������n|)E�l�a�X�%�ֹn�0v� !�� A ����d_Y�ׁ��A>���R���zcu�^������б�!���j��M-��Y�d�T���Oy���.�x\�؉áWV,���vk����-�n�����!l0Kۖ*��)lE#ɜ�,��� V�&�e�\zV��K��κP =c�䂀7��Y��M���dZwse�;!j��sg}�ީv��D�	�5@�A:�VQ��=ε~��>�{Tܒ��n��I��`T=�qWl�����N�Ҏ��.�9_�w���н�;B���֙��Z!a�v})s�dg��O��w�e�4�_�W��sV��	���*��#K�[ZF֙�DM�ltk�%���R�j���+?�}�K"s�t7V��6��8�,v�u�|������Q1$u�?�%K		q7����-��D�w�Ō�8U�v��t��#D@,a���{5�=���jd��u��-��+�?K1�[fˋ��BBVa8BxgY�&˗��dgH�M�۶�n�{V���:Q��h��:�n6�M��rv��i�Ƌ�B�,����%����]\	;/�F9��Hv��"�n7(���إ��V�م��S����n�Z"�pf�.��ѷ?w��Ͳ%C��bV������� ^^S]��*��@��v�p����c�Ї�dy\No�.���b��t��8�`���@!d`�[�������b�XM�H�����y	%�Ē/�d�%�xYX
�K�lu/�&���\����N���^�dW%��_�n2��&�*ҹk��*��8����� �QqKr���%�{=�����&�B�Eh�P
F�p���*�&F�P�J6����5�
.�>�47��Y�F��C3P��6���Y��a�Ɣ��P�2h����2�Z�-ƱP(O�M�_�bڨ��#j����� ^Y-j��C��� 4�(�j_"!�_�]����qѺo#4U��t1���Q�wtunL��qL�x�8�����bW���>�7��_��0je=���x��f�f!TۊF��^No��)O�XG�[��ܺ�B�t7ߥ��,q�d;qPa�t�"��i�����$w���c�_~Z�w�����n�X�W���qn�{^�J�V*�N?8[j4��@�E^)4iC�;�$�Y�٭����;+�m�`J��.�=���y��]���:�-�B_v1�2C+�t^g(k�:����r@���*[e%�a�B������,!6�L��J��p��kP�a$��(2�V\鲗��jv�����n����y��&�eá��W���נ������p�\X.��r������.���$��b�n���ޭ(O�F��&����D�Ę����zm���_�gw~��3��^��k����$����fY�Z�7�K�\5�(�//S��f���?��;x�.��\�zʮ�l��"�tA�ta�_��r/D���l�;3�N��!�I|�P�;��3TG]�;���C��t��u�B�=a�1�]J`�	�N��"�=��ئ��r���ޭ(O�F��&�6 ��c�w9���5ÁVg�������k��>ێm�ʉMT6	�)S���֚I���)ð�6�x񃅥��ޤ���/mۥu��`�Ig�b�o�E ݕ���څ�{!����k�6��Z�.ʟ�%���� �H��3d��_{��W�6"г��c�̚1� �&�X�DqL���7K-X(B�1o��!k��}��5��2�Pt.3}�,����D�g*Q�����`��bĀ{�Vg�����0�A���	���!�_N��f�1�hM�/"�J� �@]�� �r��'�ɿ70܏�jt���<����1C6�Ąh�y��5��@����X��B�g��1���r�{�/W����xU�M�'�V�"6zVV36:#V��p
���������5�h�0��A:� �}��'��u(�z�T���.�@=�B�d�8��  �� �j�_�t����ÛZ:E��Z/e��t1��p�x�k\C�U:c�7��G錪��0�@�N\t����f5�P�{�8�?߭�����WH�l�fL2f&���{T�-\�?aL�!�1�P��3]�����0C<����_�W�<�	�@�pO��&Q�I��د�w�t�"b�7�mcT8d�s��|\��K���A(:��^�6�`Tx�ř�|8\����u��/�]L1���!k��V�&ϻG�X�-L�7� Y�rr=4������W������i��mvo�H7��P=|2����[���q�g�~u���wXv�G�#x��ea	,�R%X���%��wN0c@���u�&�̀{&��AY.��fmۜUKw��,���I�v����q)��j��]�[��9B��a>m]�[�]��ȡ�$*��dd�q[@�D��&���Y��d9mQ\fK۷�n����]0r�Z�,#�r��r� �߇�ց~���B�#$$�[��Z:E�g���ג�Nl�ޥ�_��.Y]��)ޥ��f�)C�º�g�0b�@�N�!��lVq	wF��nЈL_L�s��/��iW�(�1��ƺٲٵ[@@�/�e�<X��o���wCu��.�"���A�j�3İ�]ז�N�v��3��<�	�@F�'��?�&��u`�$�3	�\�;�0
s�n��!�L�6D�c�5�~�=*n����� <��Dq��&].�N����1Z��h��Ww�F���5/'�C�ژ|�&�d�(�Kv�����a��:@	ֺ�N=|2���Z�j�-�a����fH���`8�>�c�d"`�}���|��_�0ӽ!f����AY.����m�������eR�o-_��^[�\�*������c7b� M��}�Na��>nh������U	�y����e�����`��;��"�ؖo���_�t�����r�[�6�tr�ŀ�5Y�րZ:�/��dW�����C@XQ�!��f��K�R-��.�O��.��]��WB�'+J�|
��bB��Bн�o��=��&���d�/��,�"/�o3]ȫ�w<��TI�zmMw�׾�w3��<�'�!)���k�L7V:!9103�-���H�f�7 *#����z����j!�t��(��q94	Om7V��huȚ�2�;��W�/�fȷ� Ț������'|(ԬC�Fp.�Tx��@=_��Ϳ7l��)��c#<k�]�<��#�1H~�Q�>U�p(B�Kk�a��cp���8xVS��K�R��z��nD� ��{1@t�4�I�1��Ð�b�Z@�>�%�@],.�כ+��˛� �_�1�T�(K����0f��FC��N���uNQX³th� +�3�]�����a����rm�U��zqE�݆�y��!!Z�+�,s�*����/�tgĚE^*�f��B^M���� 1$_�}��?H�{eb�������H�f��p��v��<�;��n�4�g|K�S�����huBB.3=�o�5UF�ŐoȚ���1��X-ԂS�Fp.�U���/����s��Ƌ�Se�`y&�LJ�hN��>ʖ�3 ��D0�^!��ge[��l�{RV?&\�8�"h�W�u��Ǡv�'Q���sf�\����ﬤ�'�r�Ͳ���v��/��'�6�trn��'��?�3�p�c��!��(.:v�3C
�{$[��*s�����e����%�Y�qq�iA�-L�9�{:�4��T~�v!�&�.8C���D�p�d����cd!� ��� Q�y-���ﻙ�+�%�g�Û3$߯F�Cּ�^����W����y9�^�����&�+�M�w3�<|_��˿��L�e�	�<��#�1H��I������5\]Ol�_�_vzS�K�7� ��VV	�z=`�w�U��Ǡv�'�38�̖� �I�T0~_�*�bA8��BK��_2!Y\�O[�tr�����E�V�k!$,�%<Kg�t�jLwk�`�E��6<����8���K�\�A>7V"EB�ݵϒ����D�a��� ̔f�ʗ�C^Mg�3Ny:�`�H����d�k�v5��� Q�y���[�@xpLw��t#��嘍@���L%�k�tqs	b1�/]�huȚ�2�{ד�F{��+�|�@ּ�\�1&'ѕ	`�K�,��]���m�V�
���/������g�|�������.���bo��#�Kk��D\��{H���{EN�1�k������b��{Q�Iտ��k-���|����0E�L,o���G���,e�"�IT��2@�>nh��� ͊��2[��������Heh�n�@8V:,a-��zA�d�p���j�)L-���2�m�|��t7�o�F�B����|����%�KW���v!<�ԂV�.��@����6	��E�l�6 t_��m㋀����[*2��pՂv[����o����N,�"/�o3�!�&����!a�:��AB��>�)���a�c2�5`�H�f��t��fXCu�Kv��A��L?����633=S��4]�۞�T�W��@�:f�s����[�Re|�����y9��cL>��2�F�V״� .�l�ĻD�� Us�>A�=�v���B,�	�7�`"�1F�@��ֻA����p��!��9�ExyMu��H���v�EY&U�\�T��n�0���0�9C���G8�	W���إ;4@�D�}�*�q[P�DhV��]�ltc�B� ,�n۴�;d �6�(�]�ks�F�=�$�d�d%TK'w�n�lIto9_��*�K�Kw1�A���e��άK� �{n�<zA-\x;qѱ�6�%Dx�%���g��e۵���2�� O�.��toN.�.Tn�Z�n�o�!���F��X*Ϸ�.�������2,�]��n��d�`���^\'ʷ��pBBM�����b,Fe�|��k�A Mfzf��.Z��R�B7A����Ո!ߜ�r��\�9&g�0��\QD�|����ߟ��,���V��λ�]Iҿ�l~���{eNy� ��+�U�ꇱ��r!��p��{]�;�<�^�7P��ۂv�$2�+�����TPu�6��E� �(�RJ���A:UN9^����,��҅0�>Ig�`��`�$�.׆�
�Z`^���10���'������"E�[��49�<�f�C^M80C����R��wi����m�� @����f]�CQ��
g4&_���U#�b*V�[i�J�݆V�v���9�<�ʲ!�~�� ?�wȬ��܎Ϳ�X6:��ٯe ]�l�l�Nւ}`e�6�~�ʵ�_,���"f(����V�h�pfuR	+AL�r�X��*l�r@� |[���1��fj8xu_6`Y�R��ZQ���Z�����9׆��Y���	W�3��G���������B����"��<��?�T��B��g����k��#�����#[����m}޶��/��K�_Lb�~�.pu��BpH���ra��o��?��fY����/F^k��3G�t!��y�&��|1M_�b�`�37=nﮭW�ha�E���g&��tx&�½,��_Q�)��'�Ǵ�0�aĲ̤� ��p!�!�P��X��a,E������y&o��6"H ��	W��Ǵ�Hz#M��%��p�r��-b!v���\`�]z,	}Z\��T������c������ ������k.���6�Ձ�QiqX$�#�@��6�B�7˃��{)�'�St�yې/�vsy��`j7<.��_X{6���Ci��K���׻%���0]�C�9X;�h�ɭ�R]��y�Q�r:<F_���P�h	"��@�l/�f�����`�mȇ`�^�w��߬�t�yۘ/�vsy��`j7<.��7�?� V�bW��������2���Q��s.�v���
��j��K���������8�6{�DA H���}{@�M��'e-�/_��e`Y/��m�����=�6`S�13]>�*��c���`;njr�~��B�Y.o�ŀlj�r[����E������F�wGH���A 	Y6D��e7�^�n{�D	 t�yۘ������\j7<�8_�V��z�!�K���&�K�3����s.�17?rp��) �-02\��])���X����� ^aC��������uّ���m�@��	�ڍ�����.��]��	�K��.�JHxg����x҅{�Ɍ�N�=<p��<j��P���#�9���Hw��@�kp�,.�� .TAB���r�Y5�<\y��m�y>H����R���q9�����e�bi�\.9N�� �wǄw�{��n��U�2�   ��_�B���ϣ���z�5΃�����뛥�񲸤�]��P	�w���/ݖ����PK��^�A�|�6����k���]S]�`i�\.9N���e��� y����y�@H��A}SO�WE=�׶�hD�ό,$*��Ns ��l,\c��z޶��n�fբ�%�s�5oH.�Jdxfᮇ�[�6[�K&��ᛌ�&|��k����6^/8�.����Z�s���7y��X�{�D���rV�۟�_{����2�hE¹%_Th���߇{k`	,ղ��j�rd+�L�r�0�Ъ]�n��p���&'"J�[)n)�%Gee"�f|�;$����
 `���
���� 3����KN��ַ�s"b1�G���APlй�8F������ ȹQ���o=�t�� t�[��Y�R���
e��htv�|�l�������0�E�)��N�� ��7��:g�]�,q��֕2W}�[ȗ�������V�9 PKſtڅ�ъ�X��tm������ P�W�p*͎cfi� ���Q��U	�B�E$]m�t��%�Ѐ���ڲM/��_&�շ�Z��F"�R����J!�W�wC�q��]R���f�[}����?�GkǶX�x�>�l����*x7NF`ip���2Q;���|I���Ѫ�	,�����[㥒i������+Ј[ݻ� ��)�p'"`���l��C�;�S�q�%O�\8��r��n�,�e"�P�o<(�$��r�ֹ� `6nu�����Z'j"�`�;&W,ó07�R X���U�D�\e�P�
�����H����H3(wV\b�)�J� 4�>������3R���� P��%6��`���������F$��-&�db)�@=�C�x�A���Y����.l���E��m��8���(b�S@y����aM(" O�:V������!Q� (ݿ�g ��證�R&XL>���u�B@=�!� ش1��s��(  K�X�'��$�Qy�`@@	S�U9��g7���f�q�����!<X��e�� ���b��P�C@@���f�@�Z\^-35�uZ~n 2��F�D��"]��Ց��z7�D�9h��e�̗+�]ֺ�����~��\wOVU�\�o[�L�sy�쁢X?)��JV�*Y� 68E�py��͗
F��0Tj�dĭ�P���'�6�} �nG\r:\-�����hw{ş���[�^� ��Ḳ�<n��V�/�b���R�p9i��x�S�rIt��ݖ=^����
�Éڻ��7W@��z���t�V����e�����@^�h�A�Ò( vo�ED�+��rs�8p�@	�]S�w��[�O0O��(�p�J��-�e�L/i�G#zF���G�t��n�* e��m,�P<���pg����ˠ��ҷi�)[]rU�QF�;�o�K���s��� 
��л�]]���FV@�
��e��]�h!��K�P���@ �3n���.vIv� 8�zW���R� �	lJ;��������]� Ց�,.{���֗�gp��Z�w�֡�7V@�*M�R��9���l��E�p1��V��6�V@���oEqJ����\��YGOI�:0?rDb�#�h%�	�Ӯe�^ ����s�� g]���ٔ9����r;A�g�r�/�%V<C�[�����nb��uK� �Ϊ���W��R?0rp�s w�6�e!Ż�VF�f��+ �_�:� 1��[)	MH/n�B&�oF ���Y��v~�N9$t?ܛP�;�����
xL��ё��J�;Qg�F�r�|�8���@ ��nfae�]�,iJ�T �q	`�[Yt8_�@]X!�I�T�.a �K�*�(��%V0
`�;"��ܧN@ul����%䂍�2�0��Y�ز�Y Y�W�� �zW-ǫ�Ad�D�C������ɀ���ϗL������ �2��#�YH�Np����FB&� C�;,2���\��fX)����L�FGd�toD��|��D���$QJ�q�����me1�����B�z� �toL��f�����	`���,���p(m��b2�.�R��Nx] ��[*2��pEy�>^3� .���ղ^��.�g�s�˵UF2�w�Í�����n�l�}�ch�����D��T0@/�F��ź&GT0��=�5�b�dW��\�����������Sw�a1��`�nu[�d5!�9�aa��X��Vgz��)��\�e����Al���J�FN���Z�rH�Z��.�}(�d�mtY(�]�;$�[k���f���Њ�y�w��S�����p(98��t��m[��P��ih��%م��Ţ�K�lu�U@G�X����3�3��7{_R]�kv���]�ltc�Bٛ�"�M�� 'Z�K�@D3���)�d���<��Yu���C2ʘ���F�� � #�Me�X���\Μ�&�uc�7eb�5y&PscD	�� ���\`u���IȞ�H�UR���W)Kbw�hu��Ӣ��9@���YRr�ku��HwU�),�%�������7͎���s�3�n@����eκK��ω#��z�P�𴻹v[��PG]N�c�ݼk���v�B9��n�s2ʤʥ�C�]�`��.��.������j��O�:lt���ү�B�ֿ��LD�N�*.:��$���`��v��]_{6���p�b��Tm���c�c��!����2��zW ��`���ݤL�`�+�FW*F�r$��|��M*�L��R8}7���W�r��ǒ��P.�ER�E�>lt=�w��J���N�`Q�J8�m`M	:�U������4��{L4�DC� ��ץe���:-��{�vls��""��x^}�o^�t�wOV�C�Oջb���B]��_?w�J�&��q�����D��2U�$V���!R�uy�� ��M@��G� >\���Ļ>_ ׻:��tXR�	/��Y��&��1[0}7 �;"za9� u���Np��T�C\b l�=��EQE���[
�������
Z�����H�/r�� jBB�X�\D<*@�����:z\QTD+d"`�d"�Mu(���*��Ĳ�E��*EQE)6(�䋢�� �	�}2�NG�u�6m���/@@�w5�z�8����+ `�s  �'@��V��W��	 ��zs�����=��`2���~�����\� �5T;c�{��n�P�.��w���� h�<��<�Є�� �pL�R��N�.m A��]�W��0X���K��h�#�q���n�&��;�`�n�R�c	H	�י�/J0[����+d@�t��t����F7����U@@�j����elan�h�x}�u�e�#���n`]+��	wj�Nbeq��[+��b����m	�ua	���h���Xk$����Z-Lv?;�H�CD�H�ӝp���.ҥ��.�E:�'��T�:3b�]"�Vw}�k�6BK��� �Q��>X�� '��E��Z�u������(㧎^���%�]D$�C+ �>��9�� ����y��m��[CŰՉxHH��7P�-Ꮉ�,������nvo���� �f���}�� ��Ĳ���]��C��2��]�\,O���,Dw�X�� ��>]�_���c���Di���� j���G��&۷��\D�C��P��R.��$ޙ�ơ�$Q���.5�+��	��v���N��x.�D�J� �0ڹ`�lu
�f۝���mi�#��mnY��������~qN�*ݛ
�,'�b`p����X	|M�F��S"�/�Ck�xy���`���H�G����K��/b}��>[m��T�%=i���-���Ҵ��c�nu�%_0y�/% ���YCH���vIv �:�D|�X�dc� ���K��K��D�
�h��"�Yk�w[*z�}�*������ڳnl�:�\ȱ��j1 V�2������@���\Y/�ۤVl,H�� ��68����j�ԏh�@�A�;(v���r��q� ��k�ķ�Jp��
����Tg��΢'��
����:V��&j����B&�b �nĠ��
��e��]� xF�vʵۇ�qy�j�� ��wWu�j��w�B0�r	,��ܲ\d��-"z
�b9��q�B�>�x�*`���_"�D%#&���<�v�֡�#����,�<����x��x�8���,�߀'�K�lt���^ڀ"\-��_n��2�
ӈjG��֝uv�K�6�Hl�vc�n~6w��n���$�H�\`��D��,�  �Hut�	x���qu�`��j�g��2S��Ēꬪv0�iu�lu`~��:҆`9�Z���D&j�u����r,�?�݆Vuؚ�}A �c%s��R�Ю�=��� ҧ���Z ��V�/�/����B$\_��� 4a�3"+�JpI����bowEʿ���*<L��<_��h��U���C����*ic�F����g��r�F�`Jg@���qA\�Zt �~Hu��a<_ M�!��͈d7�P4Ȼ����E�}��z�V�Z�{�" �n�V@�cB��_rufit���Հ/�kk��%���C�=�w[��7WD�����H�������>y�H�"]���_7��"=z����Y��q�$ǌ�<D:�mw���!=d#EQ�P�e�Cip�E�;��}ֻ��U��� "�,�I�w���>W8}7`��� %��7_��Z�A �W���$��p�;� e�\J�	��|�C��Ż�0��Z��m�}����"5/`��:J��*I� ֏�]&z����o�a��f��hMֺ�
8� 3PV�SNz�'V<C	y�F�[�W���	�}��p�����P��]����8Y�/26>��a\��Va|"$4�}Ư��iW��@c��5a��QZ3�ɮB��,dm�/�5tXb� \�d ���,$U��И.6v#�g���p�x��^�a�v��c*����rx+������趺�A��f��-'��  ��D�����P*�ҷ7�m��t�+��D��^.&� /O�.��to�`�+
�f+%�}�~q��ţ5Z��3��B��B����2Q�/�[���c��B�t�n�h� Y[_�Z�T.J����������b���k�2ۥ�����5����Ɗ3<S%YR���Bf8,�Y�d��l�< [C��x����G�� �=w��U�ms�B��8[uGD�x�y:W#�F�9����
����
��QDQ�  sA�PB5٘��� �6HF��d +���L��c��VW��}�Gͪ�w��f��Q�8y:"� {�*��n-͎�F=ZF�@�R[���n���
��|��S.X�'���B���r����]W����&�=��������� �n�������"v�.׹5m&@��lӯ�.�.wɱ���	,��;a���L��݀,Lu��տD�En��V�/��� �⯾���F��=ۣ�[f�e~Q�|7@�EI�o#��-�sk����s�(�<u�S� =� !�O�e�J��Aq��!�	�� y�}�#bn���������Fd���A�򱚈xP\@M[!���0r%t�E�hEEt�d���Ba\8�%�z�X3���X��BB����M
��h������nb��s����D�#�m��|�w� ��ʧn��:� ���K���\hu=[�k���C"�G�h��W�t�o����b}��eq	�xW.��n�]��t��W�Pw����#5��]Y-o��o`^Jp	uV%����%Vn��t��l	����j�<[�`�,���SW3�t�1�twu�����B����L
���(#�`�4�#-9xXE~n��(�ċ �NGj���g����P�W�o+`��#k������V"���5�3_D���U�~�'X�.x��|�&�n�xH:,��J��m�:��!i�nF8� ��ٕ1@3�8<zW;��E@��mz!��g�6-/�af�7�l�����*��d�캭��g�|��]�슁{����U��� �wW�
�pa#���ݕ��F�w� �pHZ[	�ލ:�.x��|�&.��G�
Hh������
�΀4�`@���q���z��W���۫]�R?���)B�Kk�0�?�� �n��M��B"͢�&�۔���E��ܳ!z�+M������.�ɀ���F.x��4�&���хK�0m�۳���_Z�\�j)�'k�K�F\Q9�������g��(�P8��[��|fa�0`s�(��{�Z�p`�� �l�K�
FΧJ���W@�Y.,�p.4��P�s.��6r�z�Z��͟����dW���+si,}@���3)X���R��
h�x)P@'�. �.�Ve�@nn��(�B*[�EB��m��P������`�\z��B����"��W�M�}��A��p.����Z% ��0��1_�(`��:J���Z� h�D)�7_���3ql��Y4�l�<���� �Yn���m[��P��u�f�K�Ku͎��%ʿe�w��~v��"�]�]��[����m�V��D�w�Ō��MN-;]��~  �B;HMra��t�.��;m�$�\5��JIv��_ �ם.V�ݵP��f��-'0�����E@���3?L�@����Ldn�j�?��(�i�(_�'�(���M�Ez5���X<ND�q2��У��J�ɒ@��14���L
�������_ֺ����3����KQ��R'u�%~�T����܀|�݀TC@wM��bO�� ����4!���1GC*��)X0$ �"������u�VW�jw}�و��sΪe�T��}��#6�����[�5� �c}k�]|�P��遀=+�q2�Vߺ\zWD"/�o������:6@��-�u���sW��I�����x�����>KP���"���� |c)h�tA��D�Hd(zƅ����@@3(��UY�n!���L�E%�XyH�?27 ����j��`��	 ��zse��j��2�(  ńG�""I����"!s�S%"�ƫq�x�Jޗ�e�&J�lp�.ZRQX�"]�|�"]�#G��5�Ż��R?be���'���<��5ґ��.��C"���*X4�Y@@��HN��V�\4`��\>��*! `�/�%�����jr�P5ZH���F��,�X)�o�W���B�+P�
����Mu2��hpG�q�0ڕ1^s� �
/���g��!�w[Y	2�w��A�?��+�\mu���Jx��� E���7r%7]�7'hxq��YE�ܦ
 ����J:Z+��Ľ���BOK��ZcE],��"��
��G��sp��xIv��S���X"��.^���ň�2�����R� `�{�N�ѥ�堶1_mv+�H[Z�e?|{��Jܻ^z(��vD|�.�B�R����Ҳ� qn�� ����~��\2��\� ��6��c�����.��οH��*���\�K��@@=^�5Q��b��x�݀R�V�-�pb�� ���P�g�k`�����`�rR�pe�q�\tX(g `�co�d����-��޻��/U"�yHE� �Y���!ɮd0 �մ-.2Ƞ�jY/�h����]�3�` D�w�[���<vn�&:���@e�A�4x��z0���fu8�T2@Η�O�Gx�tl�:����%'�����KH���޼�����q [�TױA�[�KuC+'+�G�X����3�b��ӥ�G+"o��߄��`�h"�Pu�%,�jIv�������>w���%���
�˻��Fp�Z��%����I�v�Ş��_c�@��]���,�[x3�ߧR�(�>#��n�ອ�F���w ��܀�h9B9�|�� ����yڻ_��=/�{��m_��nS��&�^���ʩP&��Fgʹ�.����.��C���p\��e+��  �c�q�()�qaQ1+b��@3�V�/H�8���z�� k `��٫[��4���{�  ��>5mH�@���g�u�������R�ֻ�m�O9ڴu��N�ˬ��M(G��^�
���9��)�cs�4���C�I�w��7� ����l����"����j_�X�'�5s��֑5��Ҽ ��z��F��.����D|����2�Vߺ\zW�,}�@3���􀔋S��]�/��]��м�����5ޕ
�����W7�F;�:%ّ>M�����Dk�7����[��r���X)�v�
���J�X."".�5ĖEx�vo���׹��9,���ݓ���|-��O׽?s<a��"��*�KL@9��C��X�٠"**"^{P,P�� h	m@d�V��@�q�o�BQ�c�An	��ջr���,��zH4.a� d���** c�%F��z�W��0X�k��r�^���,Z�����
�x!Z&���y7QY7�R&��C�͕P �rH�>!o ��d� .�5ĕE�➖b$$dl^��&ܹ �m���gn���f�v��<�0^�@��� ����u 4�vW���5�t���ʧn��:� � ˓��,k��F7����U@@�j������}{���pGqH� ^[/o<��,��:["݋E@�Z�^D��=\\��&��-�naY(c��ʩ�*�fV�@u3���.����jlr4��{YE$eQ ٙ���_dpB6
hb��:�^,7V@�O� ^��Dq��!���ٹ��clY;6�=��9 
�ׂrw�n{�x�)񒧀��2л--z���-��P��w#�P��h�j�i��� {���GK32|����!V�(�z)�c�� X�����"�SJķ�U�̡V �xx�YB� 4B����t���*nQ����
(��2�r��
��X-&�/v��R���\�@'땍�sm]�~��w�}Y.�����~���"�[	�>!o`�x7��.�������W�7�+a�v���u�K��c�L]\be|��9���ȸ�gn�<�u0�)�w��� �<�ˍ���l��D#$�B���ջ�7Vf�����/�.v�^.8�3��0�)�pE���,v��]�f	V �� ���v��X�IHX5/��ڳ|�~(���u��E��G��U'�5{���iԋeh%�]/?;���	y�\J����E@�����vH�Ĕ�I����ͷ���B��/��Є��q.�+�r��=>s<p�ѿ��:0?rDb���F�,�]�6� �B�TJ�c��
 ����p�~r�W���U4@]�f��/�Ъ۝UG��P���^_w@@z��T*��ʺ?�֊�x��æ�֗K�ή�(�b�|��7x���mS��~1e���Z���'�P�.�xe�`��8������gn�����N� �w���pGht���M��&����Ї� `��:@���ot��N�!�e {�2_ M� a��Q.�x�Y�M'�=^��%_��R� �u7w��y{�P�%VL�0U�X�_Yh Ra�`n���~���E:���O�����NW�~1euoN���I�l�QDR�G+��F$L.���z}�47@�V"GB��(%�8�ED@ﶲ�A��mr!�V=HX�7�>���.1�#���x}�6m�ń"�OWd^ �׻SP�ɥ �@n��8�4o<�mx���b����:6@��1!T��njd�]��
��c���C#.��<h���%�Y�!B���mAd����H�ڷ�ŀ�^�����ZW�2��<�@_�}B���:]rP���}�s��!�,�[Ǘ뫀j�q��@E��aA��=@s�@吺�l�]��PHɼ��P6�PwH��P���,2Pa�"<�&�V�(����"�]�]��[����,c�.Tb�o�h��"]��0�ĊT8��
f�.;]�{�r.x���-\v:�;R:��y�mr<*ҕ�����V�m�UgK�|�FF�3 [��J�!�����}��K��T�r�����A6�.�.�- r.�5�e!��6�xIv�W=V���ݯ�ˍ�=Ms��	hY7F`�z��c�"/�g}E� P��\����ӡ���/����������r��s���H/��,t�T�	���Wa�lL7�� 2��Z�` .�5���`&r������nvMn/�܀S.X��l�ǹ�n����LO��M���z��fwH �S��{�a�[��rV���s��w�@�V\gj~Kx���;�ɕ�Z�/\2��_�cK�|���ψ"�U��/K���n ��k�𔻹^�P��g�E��r]�Օ��pL��w-�kG
�a�!�iws��&<�\���$���XT�W�õ\D$�(#t9�ºи��r8$��O�g�3^X*Aў��Z%��p h��g@~n �ԴQ!}��V��	��cx]Z�E�m�C1b%���{]<H�ۘC��=�I�����8�6��MR��d�,����~�(J�ҕ����i�B�q���rP{�|T��j���?u+���jn���+��5����F�|�:�6qX~��B�&�(@���u����_0)ϐ8�����0s�G���-��n ��kx���-��mh�tf�PyԘ��ſ\_�Xױ�F�6�ۻ�K%#��zQczivڸ��U������ ��ͷN.\���֪������
�P���aHu&T�q���9��4�y[.��qP��[����o�ja8�V�Ċ���R�D�^ڷ��xW*
�:���B]��]��]l���pa��F��鯩.�z�vc(�,-���X-�����\aʓf��\�^Y{W�t��+�T����C ��ɣ�^jގ	����M���շ�.�J,\f�VS��t��ڳ��\� =��5��/�t]h����H]�=���0���n�9�� ��W `�#��/g��n����`�cb$� ��":�	R�	:TT�,��B�Y�zt�S���PQ�� y�P�.7�P�3.\Ut?�⹅��
���MQE@�8�%@�&��H-Z���AD2/ yV���b R"E���EQE�����;ʟK��h��:�xX	����)�"g���8f=���̗�H\`�������0�8��͕v?up8�V���27�]j�xWN:@����q�t��������^ms�DF1�G�]��x�,�R��"`�:@�|���Q���f���@#��f�3�	��KHәUh�ld]�N����P/���}���F�k\EיY��u�s:�Ђe�L��k�FHX���UX	qŉ���G�@�FHuf`�g���m��.�BE1X���eVj a`��ph6"䋢���U��J��xj\���T�)FB�!~8�Vít�p�\D��>��"!eU+wH�<��?/Gl����L؅fp	��]j�Ff`q���K�p�Ā�����k}7���W+��ۭu��X��#��X����>����nx�-��d!�,�2S��.T�h�� �A�X������� Ґ�u�F�狀c{��E�X��E�HG���#V�j�{�
�_"�v/�.�@	f�R�Z>u%�`�d	l�"�Nw�"�˓��,k��m�Kt�.�E�_Οs�����$��	H�Z�WYY�3�����+�V�>�ٽ]6;�#k"��Zfj��DG�X�'7Y�>�I�zLu6��ՖЪ�N���p ����|�! ?7�Yj�w4��Ղ=e�ՉxH�Ȅ��u�wQ����/� ��΀����P�]#o0U>u�%�9������3C'��n���<\Z����/��%PI���*,���0�����2Z�veȹ��:�ݫ���� 8�MϻD��(����n�ڻ����Zpl��B�������Y�����n��D�s�ɣ�o���q;�"�X!�e!R�*y_����*�-��ōu��p�{�&� ���5a8�ֻ}��v�t[���Z��2S���/@3���[�� �����u��/�]Lq��������r���v�E[\��)�.��X�d�\>�@�� ��2�nt7�{K���i\�����?m�]hw3L�Ge|+���k��1
��b7U����,��r��/�{�����<,�"�w[*z�}�*|6?�r�a�+c�%��, X#j���V��b|��l�� B� !��(.I��k��@��]��z\ %�veyѱM.�oӋZR��`��p�<��
(��U���R�B�0�}6�Vv|��
8��\u+5Bb���)񒧀��2��%� ��v'!9N��?
�',�߄�Έ�kٜ�������p ���/% ���� ��x�K���g`�v@��ԷK��� E\,��.���!�B�qfu�L� �t�[`��E����.z ��&+�/�!5(����P�ww���Z����#��ls��wa�Z��_	-(����e��J�0g��~���,���G	­��w�:�~���`p���Q�lh�+ꔳn��B�V�EwX����,!�(`{�A���v���@9���H���kB��ʕrL� k�?��/@�
w��J�yE�of5.��w_�n8C�pw}����ҷ���̽XD��>�twV;��xD�;���ŕ�bg!�'�n4��C�L؅bp?Y۝#s	!X�0��g�����		�w��N����w0&_`�<^�ݳ5ϸ�b��%�37�ڭ.����/X�Ⱦ�8[]�$���)D�Yg��m#+?7�`@�{+z�����P	.��rkDE],�0��^�b�����G ����Um�r	R@l[)�t&�)��Ҁ4���^@@�]���p�JK,x.�W�`88[���J������x��Px�8�,�,��F'�	��7<���w4@��o��p���3���!��~=Z�%�!��%0[x�1��|��2�`����`��)\��B:-.O
�k����k��Ѻ\�]�c����r[TeV
=5���E����v'��u����"5����).7W@�q��hZT[M�?mZY����ˡAHxj����b�����O�"拢�n� �`��zFҝ�8$Yz4�[��%�֋��'�n7����Y+��`b�U ʸ\�:��.Zh�M��U�Z�l~��V2W�d�iq������*Qݽ�s�Ϋn:|��_D|�.�BrW��BԎ,����T�-.��)�y�/���B»k��� ՙ�P���S�K
� ����  ���"|W�m5T���o�!��oU��8�78"������g�͐����	�&w!��r�o����.U�7�����\�\k�L� ���H��,L���E�ܮ]�V�oy�u:X�&=�F��$;�h��'�F���;YW�c��c�aug�_Q5辆>U�����_u� ��d�Q��m����e���2P�s����.�9�� &&_�M�-  ����
xڱ�"\6�*9Q*n���0�n~n�:^ތX#�ƭ,:�/��U�R>#ҽ�������Kj�C	�j!�9.�(��?Y�9�G��u��)������yо�۝�8�p����B�#�v��܀4w��y{� ����Eg*Q���V��~�ya`�� �pұo�f�:Ψ���3�tFB���YHo׾]�w��q��Å�F}�%p���B�8�Z@��1�ɐra�(W���������R�
]�Kj��� �	4��:� ~8�9���+�á���B9� ��;$Y|���`��B³ք],��v���k}7 b���|����xi��$Y���� \6?2�G��2����E��۫�:��.8~n�:��Ż�0��C+�@�` �jY/�h����t���H*���K�sC+&s��� %�B����AB��A��唓���<�6�f1��\N8�+��"��˧+�����Y��$�a�� �R'���t�Q|���ҳQ��|�Q��t!�X��p�t]##$dmu��w�Q#l�Re��<]VJ0���\��Qw�%�� ��E-!�(�B��S'5W�[]��A� `F�J��A�9\L(`�FJִ-�8�>]UaF�á�f�yw����΄�o^�r鰀NH�B�]��4QlT���W� m�(�Fo�x��w�_K��+���W��TV�9�������V��("~�
�u��§ݭJط/q���)�G哕�.��kJ���:lsKh��q��w�s�yn.A,����"����R���P�Fd�A@��
,a {7(Or=Sh�C���m�^�K� �cw��ҳrw�C�����w &_�Y��\��}�:e�f�ge�{�"\6?2�p�ێ�4��s5�mt����� 8`aI�����Kt�nhqd�uK��:S	�H��,Z���z�\��ᒕ��:�\U���D����Y�x�/�<��Zv�T�8��Ga)��%U�[5����DY�^t��a�6�-t�J#1}p�xW�xMt�n�(J�2���0�w��]�#$[x7�5�@!d��l�����b@B�|阯>���%Vֻ�s�X�"�U/�K0�SE@uy"�]�]�,�b`� ��-VUF�á�f�-�,ϻ��H1�曗�qDVJ��w-qAh��P�ם.V�ݵ��8"]�[-�]�����[�$��R�����\q�y>����aP�� �� @@օ�.o�-U��CX�R�H5�0�9*��ݙu	�_��L)B-o��9�<綧%U��(��"�_�R�ǆ.�h��R��\�4��n�<.�mP��z�P�fpO�d���/}+s	�0�q��d+��N�����n@"�}7`��a-He�@@�6�%�e�&5F� ��m�F5��VR#�����A^��o�P.��?,����$��
�>��6;�tP��Zj����aa�V��R�P�l�,�����,�.�����B)�R&	Ӕ�# ��$P/4����!���oU�:�]��b��>���(���kۂ�PO�~���qa	����]p��]s���V��8�j!��/-6f;��xiu�lɨ}o�v�3���Mg�\��z���C7�EX��k���0�-b�\^��.�y7@?��/k��
��ʤmBVu!C��"���u-��Tgcf��X)VmX��h���N�l�ɒ�SV���~ �J�3�ԧ4�q,$\�V��lh�)�J��a��e�Lz�m��O��I�s����+.��_�"#aF��'�{@WaVcaV�.�Y5�R	+�TF���P�y7�i���n�!�'W�p�E��p�� ^ڹ�� ���޻���W=��݀��k�}7@��s���d��݀�NP���ח��p���]ڹ�� h���n��˝unٿpi��e�n wi��w��B߻�n�S������� ��n 6Y�{7`�]��}���0��w�&|��ö�Y����w���w�&|�_KXf)����\�n����n 4Y�{7`�,��M�.����.�\�n 4Y�{7�v���A����n wi��w	����̻u�?��xE�݀=k��w7�g[Ϻ_	�4�&�]�P(�jַ���NX��o���[;�й�o-.���0�B��F0شâ� �v�מM�R8�Pf�joXF�3�C7���J ��݀FIu=�i;Y�n�����؅�'\��Я�s�8���?��.-۽5��h�O�ӵc�[������[}��������A���kD��\���+Vz4	�C]�"ve(XF�3�C7���J��\�n�`9m		��b��@�<���������yn�2�(  ��zH$�JP�z��h#Tr�MH��Ԧ����)`��q|�h�˛�r��H#n�d!  ҈h)@����JK?S�\0ȭ�u���\�n7lF�+��w&�BHh�bWj ��� �=&VɧN���h�.�%�|,3UB��u�D����U�Wy�0���4�v�(�E�� �Q��>Xi��r�q`��u�Vj��5P�O���7B@��HN�V@�}-ND] V�zWLy��T�@F����w��p��wAT���8].8@�{�o�:7@�������Fh�F�t�X%[]�����@�V����8%���,0��l����* `F�q���j��H# ��V@�69@��2����2��-M��v��/U��a�?V��@F����w�k�f�f}R�Y	�`�;f��l�0c�Q�:7@,���=^Yy��c�$.��swD �K�ӄֻJ!a���unY.�����ȇ�#�8*�bU�m�6B���J���~[��ŻZǺ`�B3�����P=�f��"@�|7`�uM2�U��}�pz��
?��N@�sT�2�;�����/����=��v��I�	@@@z��c%s��R�� �P ��}���� 
�ɭ@�>X_.X#�����ʻ`Ԛ0�E�����3�_ ��@x�v��z0�3�_,���ڻj����y{�l
8��w�U�V�~� K ^��{+�� ^�q��R���* � ���?@@>ti�w#i���Z �F �X��o�U;�".j���PBy�oV�u����[��d�Nm\Z����f8匛^ ���YYd`j�p^�`����:6@��1��Dq`����oN͗��  9�.�X��R�&�u.A (b���#��4�l�҈�m�+Pd� �
ɮN �c�8��i��H�HKū����{ȩ����\� ��5U0��� �dc�,@@�spY�Z�Ւ�݃5	�[��t� y�h��D�|�Ӯ,"`9���D�xa��:��.|XѢG@@.tiֈ�B�r!}\/�(�Vy�֭.^ޗR@�q��97HF�^�������.f���܀,��Yșf���X�7����U�i�OS^.�QŅL(`�n���=����vg��K9By�V�r�{A�_Z�("Ϟ��h���=���J��x]:�Q��4�K~��6ĹMQD�r�o�6Nh�]����qw0A��[�8����x��ֶ}(훆�
����g]训=�)��{Ld�ס\֋&�o���R�x؇��7H�$�{�omv(�K�����<Z;���p�77 I��_o��0�hy���p�s��Wka3X�$��� � �J� ��@�V��G@E�4�U���r�pdt��*�!.aT�T� " �=��EQE��[
T�{�#p.((�C���UiR^.��5{�\��˛�� )��1O�Jj0yq{� � �aO�� $M��l��VMu:TbHxu�����BL��� �'��%X�:3^t[�L�.KK� �#]�Ku]��t:���-lvo�H7��q!�lY*S˧� �RKpY.&,c�.V�t�.ґce���&�P7�
��pw�-���" ����J��9T�SZݣu���VW��K����%�E�c��.��%��:�j0� �0�YuO�� $M��ڲ9�����_�0ӽ!l��c\|���
/5���������X�u��u'�c�\lߦ��ȕ��V�b�-���rQsAh�F�t���A1��3$J62����:]�ehZ[���t���J��m�Lvl�eo�� .M�rɽZҤ	/�-��Q<���]�@/�,.j`����H�lj���z{��]�G���E����`�TwP�b���SsA� �D���7 �.`��b�U̞u�СW:B� �ܞ�LR��b�=qs�4} `z��p���� ���
h�T' �¢6/ ��HuzD]�_�ſ��B�ؽ������2�2����N80�e���7 <�ED��3��tl�]��l�d�)�R)��{�� i��+��d��3���=�tN �C����@�(���f
 �W-{�9�� ��b�T�|1U�������y����]�]-�`f5���д��ݓU��B��р�=qs�4�6;_d��:] =c&�c�x ���l]YP c�3d������ci� �.��͗,<�V@�tG0�!ɮd0 �׻SP�ɥP^�k��2d �б*�	��x��]� yx��x��Ye�A@�t��E�Y���X&sa�to��"���g��5�ź��h�@�?6/ A�Fwe+���qD�T�Z �y��f�%�%J�� �u�[ /�x�X^���ؿ%�TGޠ���P���M@7{_R]�kv�B�.;]�ȿ�T�t6@��j��<ե:�������J��U#h0Y%LE�d�� �4}=�dn���I����*�u^��fD���%0"[
���O��"�P�:��E���(]`�8����޾��H����/o��"�߷����Ae��c��=(9B+����%��:�d�ے�u��_�tb��?7 �x7 3��7�{��m��a��ˣ�"\�a��݀�$���S7��C�#�t��[?�@�*��I�Ի �;6�W)ڰKja7���FP��� m[�S�^� []��W��n5�ѕ���Q*��^݊5ݚ���k�x�ӧ����.�v~��*����H'b���!iv�I@�qQ)�]D�rh�i��LlWa���u�N�:�_�N,�����xj��t�N1��ҕ
��'�<B4$��� ��VC��rm�aat���	G9&�ͻ�H:PM�F-�xWX}m�.-C.K{(�����
��D�vLҡ~���k��#J��wXw�&7]�CX� >\�W09Z؍�=ۣ0-7vY*o����]�/��]�K��R��j���aHu&�h��K����J%͚�s���w(�>���W�م�θ~� �٩�΀��DιwE�<|�o].�+N`ip��YF2�IXQ��i��g���-����l����>��O�Bwi�Y��Uz֞5Yl������L��7�$�;�vg��~u��/�k�*ٍnt=�w%v�����
��,�j��D.K{(����d"�?_U��4]P �C
��/Y�� 8$t�E)�EģR �;�.1M���WT���[.�����ݘ��VRbP@EEP�"Mu������ ����� ��D�A9*R5&�.1" �>P�_UԈ��@�(s�ŹE�+��
,�b�S���QO�����K)0KŦn1!��&9h䂌%�ɳ�.�D(�5���" � \R(�?�gQ�"��ޕ����pU�	;�p;T�K�5�1%d4�a���]b#��FtK��f,�R� ��,ta8]�@���k\�j!!�z�X	�%����t~銴�\���E�u�)��~(P,P��D@�)�U���2�A��R�ج�ۆ��7�_��0�������u�s%�be�m���l0t0�y*h+�Hfa\]�*�M�uXMF:�H��MBBhּ�]�(�m��p�ֱ!]]n`�
��tA�i6��G� �>+ �����G�"�Ĭ���p�t�̭��6ί�B���L-��s��H��D����J��2���D鶤����fY���$V�X���*/F�w�K�~�~@3lw�
X#�nW��pGqH� ^[i u����ֺ�B?�V�C��t�n��t�N��� ��-^K�3 sd�\>�@�� �֗����\ �m�Kt�.�E�_��Ku͎��mv`T7#�m��|�w�QO�X%�q�X����}YY�H�X�&�h9�F�5��ئ���;�Zױ!���X}]��O�XwT�F ��ezy�,,9��x�F��+�VIF���K' ���] =�բ^f8J����Z�]z�D��FBBN�>�ٽ]6;��u���2S]��pK�[X��Bh���V�|������_Y��u��zo��� 2v��D7S� A�������2^�ve(ۉ�.V,�����<N�O�r	u!<X��e�� ��:["݋�,��b#!��ʊ��2�A��R1+jh�o�� ��NIY�}Ey���[��v���:��E���2ם���- n0t� �0���d��Q�4���+���j�t0�l7e��9K͚d`�+�;+ه�h@��eW�n�9���n�<)W��ݹmn�/�>ˈ������C��ֵ2����.���&��0H�k�����z��*a����@���������n+C�+P�
��������76U5h�h�f�U��(��mwz��E�����pd%';���L�R"�u�R��V ����z\ %�ve���2=��`,r��}srQ䤻��عM�|��6W�+0���� �n���X-& tJ�X��t���wA���pr�c<"ђ���%Q$���7��+`��)7� ���9g�pxg�ސF��+P�gkφ�0C�3������eb�:@l-ŋ]j�<czQ�	3����F�s�x��?P��,O�%�e"`�K ��NB����
(��2��!V�(�z)�l�X� x�-.|��.L9�N���~(�%�.����|��vb�kz�������h��� {��ʨ��D�����RH�֛����A�z�fɠzf��%�f� ��;q8$e9���\�:X�K�ڷ�;�j�q)E����`�Q[�F��3�nh!�u\M�&���Ƴ���4��|@�} =�x�ֺ�-"�R�;D'�6��ϯm�;���>�Z>u98���
4��+���S�'\M\T��5�[Eᾍ��qG��52�R,<�����w|K���J�����^ɧ��S�w1Q[#O�dW�ލ(wqQ�6�L4B�+�����,]��(1���.�S��1QG�2F��E�E��J!����-�\}�,,��� -�ǽ.����j �����l76�3n���.vIv��7B+��b�nzA���'�j���lH#ֺ��.v��FVą6���4<6�0^{6���G�ڽ:�K�%�]/R�?��.��k���u`�A�;(v���r�!f�D����K��^�Y	������WB�g��ª�r#+�
d�\p������^��X(�H&����p � ��;��P�<�/9Vh\�H����A[�F�|�m�_�a��븚(^��c��\=|��P	.��#�ލ0C�a�~��R���>kh�-k��(=�V��e��O����� ��*�sʎ݀3�xYx�@�<�� ߒ��,��9Y=�T��;�����E[���zG$֑��iײM/��׿
������_H<�
�� �Y��v�_$D�r��ſ�j!0��t8".p�$�z��qA�VV���ٔo�fxy<H#B�\%r�7�`)<YC]�x7m ���y}�sl�خ�:ta��bn�@���8�8����O �ٿ����.����6���.�-U��wL_v1��tm�(�BBB5>���v�p��c��X����%��4C���d���&yхA�q5�H_�@x�N�H�����aF�Q�$��g�Tw}� ����� ������q9a��ί���G@�<�� ������u�^r��.&�9X%kP��� ���?&��h��3K�cP��(���ƭ,:�/�X%+iU��tn �q�\t��v����A�{�Ц���W@�Y.8�������� �XY*D��:�]�j �@���������u6A�/�w:4�R� �u`��.U��}Y�'�&�!�娓`\�8�Y7[�d9vo�+���$�v��ٖ*U"��I�+���(@��N=by�־��hLq[|���`$#��d9�]Z	e`5`"=b�T������J� 
xy3"�P-@�-� �,=.��m�s��'� ��5�oC5�%�D�� /o�ݣy»�'���^Z{�� �FM���{,<a\���������Y��$�!l�T�%�ǋnvoKXػ�ٟk Y�bt)�?�/�A��w]��I��52 ���Z�K6�e���<��J�[+�-DϐAB~n �g�Jh��r�!s,a {7�c��R(B~x���H C�|�d���b���qf�ɥJ	��iW
6^]/�
6I�T+a-�/!@@,a�x��^�a�v�!8��b@�&J0�tc=�0C˧+�	?���h���WV�0F���h�@�
o�T��Cc�ب�f��0����J���m��;�v`�}ߍ/�h�m� LK����:����D`#��D �:�����+�@�:���3ȇ��R�6^Xo��k�0���:6�8$���P�����7˖�
W����b#O�{�����k� �;q8�ʊ�1��n-��%�m�_>_#�"�fi�Re�20偭h#��e�{]�j2�D��K���{�B3�Y
 �g��\���r!�޻�0��C뮣V:-0w��ja�-A��\T�s�o�����\���G�-������_FS�w���i{x;�+����ҝ�}�(݋�#t��n�)���voח�2�MvƯ����~G1YF�A���}��?g��{n���8�ĺ�ed���A���F�V\Bi�.խ~n �����n�{�d!27��Mwc�q�l�Y��b��Z�[��(��))�|�/��̖D��s|��R%��2�q��힕��G��&2X���s5�mt���:\w�XIv�V@~�bz�̖��%���&�p��β�M�/W��ΐn�0
�ms�B��40Bu�$��ruu.��l��,���f!Ӭ�ׅ.YFK LKtm�e���2v^^�r:6p��ԱE��n&P��e�Kw߭n�ݽ%�_���|7�D���6];�o~��%eK��KŬ(��ϻOVB� ^^S]��*��@��v�p����c�Ї�dy\No�.���b��t��8�`���@!d`�[�������b�XM�H���:Vx�]�K��%_ ɒKv�
 ��D��^.&�uTJ���Y�K��� �/g7�	W� ��5�o�}�k���} ���%��� ߒ���C�~�UA��"4E(��U8[v
tA�H(P%���R��pph�p,t�}ա�Vx��)��/�o��J����� ��1�zm1��By�n��� ��(�ƵT�aDMt�A���UV�+��E����B�f�U�K� ��K�����y�>.Z�m����.F�^9*񎮡΍)r!�)/�_�ZY�ʕ���5�W����C������W�l�,�j[�A���鍝!~5���vkr�[�Y�&�K'�Y��v���
��[Et��\/j!nI�~7 N�ֿ��<�|�5���x�Яs���l���K�ЭT��~�0V��[�&1��Rh�(�wLIL�D�[�C�s�wV�ۈ%��J�]T{ҹ?�����\OLu6�[f���b�e�V0��P��u�����lB?�*[e%�a3¿5��YB�%D�F��r_���BB�w�0���EҊ+]�_�ώ�/��� �-����=����l8�U���] ��1�����Å�P�u��}�Ӆ�S]�$v�]��mB�һ�A�(��d���������!�_��j�cw	����UpϤ�{QVў��Z%���,]��p)��fE��e�0Ь9�g�]vo���YO�5���UB}�.�.~�k^�v؞�}gc����	�߷��
����1C�p�u����0t�N��^�L ���lqsݥv���tO(����m��,G�_�݊�� m�Ll2+a#�Y9&�C��^[���`��)��{�F=(��Ļ?���Ci�T+�-�S6�j���5�(�/.S�a�m���K���Iwu�_ڶK�d�l����jߤ�@�+W?��B/W׶mp��d]�?�K�w���N�`�Ί1C6>+��g�|�k#=k�:Vά�	Pk����IǄl>�}�Ԃ��"��!*����w_�z(E�2����R�?/LTx��1.`��A	V�)F��hu&k��LC�I��o1*����zlV���Ā�"b�
�ԅ�.P P-}��{�}�� �
�8y���\���_�)���Rdc̫$�q-B΀ ���Z�B�=�����,�S޻�\Ɏ�cI��l�>a���ѳ����Ѡ�z�Sxĵw���5�QD�IԸ҉��ö�&8� ׬C�C5��8��%6pA���%m���n�U���+E'��p����)� $��z)?��A\���[\����Y<JgTm����v�3]��6���������n���P��6txiq�U��������`�Uo�O�zbL� ���A�j2w<�O%8������A.|�5� ���ᅁIg������2]�����y�Y�\�{�'����>r��e�����,��Dq&.���ru)��dS��huȚ�շ����2Vf�0@ּ�\�jc�����_fj��}E���w�ݛ%ҍ�:T���L��{��ցe�s���OV�5t�����������2�/��$\���%��wN0c@���u�&�̀{&��AY.��fe��t�ne�T�M���L,�KxUV3����b��b����i��R�B���G�&Q�>H' �����$���6����r�&�i�Z��2[Bؾmu3���킑����fY�o� ��>���K��!!a��e��)� <��u��dwb#�.]���^vɒ��N�.��7�L��%<K�s��v�apm`��K�3��v�Fd��`B����~-O�2D鰏��5�͖ͮ���}Y-�������~[���n���eti�<�f��W�x�!���tw¶��ymp��O�2B�=a���5I��&Q�I��Ҹ�q�Q��v3D�f�!*#������Q��p�tXE������%��d4�riu��np���5�E���[t@0�`��y9�����#5!$;E]��� �ޅc��J�֝t�9���	����W�l)c�Ű���%yy���]`�?�XY����S�1Lp�/�Q���3������,�S:���״+ˤ��Z�\	-��~�zUV1n%����nĨ94@�D�� �� �}��'Q�a���=�j��lInu?9�<�w6PE��-�,? A�d�j%�w�зvmj��.���k�ح�t�_��)ɮ��%<K����8C�\�	���Z
'] ��="]B��6���+����C>�|1!�Q!��f���7V��n�oa���
M�f��ʷ�.���;�@��o�����k�ڻ��T�ΐ�po�e�+������࿖V�`�$d3����L�{=�u��F��P:
�K�������+�c�:d�s��nt�+Η^3�[c d����~��>j�!|#8l*�MM���/�����WҔ�ұ��+/��w��N~��-�����@Hximq"L��p.�W!��b���p)T�VYÁ`�؍��}/��㶀&8�2F:|�]P�g�������zs��uy��  ��?!��e	�tr��h��	�"ݻ��"
Kx�-`Eq���6��A=LwQ\"[���>_/�(��0O=$�C�w%�E`�Q�p�e����X��K��1]ȫ�w<� ���`y�O8C�)�~�L,6�A��"	�����T��wgy�M�f�o��c�ձ��b\��NH�e���m����R��-Y�rr�2&_��Zp
����Ts�%���{���.XD\/���caפZ�?�S�M��lM80{O��U Ү�a�6����aO��Ä�X��� �����$�0�{��[bv������[.�YVV���������Dצ�N���~�$��?�tF��Y:�`��E�.��`fH��a�d˵!�]e�t�Xu��T�2��:�2.N8-h����/wOG�f��ʯ�.����g�3X��ΐ�pp�,�� *"����}7�yſD�Lpxs����huȚ�Ջ�����!�2�5/'׫c���D�b��\���n� u���>q��z�v=v�����]`�?�#�N�)�j �^�յ}#'�۝��U�K�7� ��VV	�z=`�w�U��Ǡv�'�38�̖� �I�T0~_�*�bA8��BK��_2!Y\�O[�tr�����E�V�k!$,�%<Kg�t�jLwk�`�E��6<����8���K�\�A>7V"EB�ݵϒ����D�a��� ̔f�ʗ�C^Mg�3Ny:�`�H����d�k�v5��� Q�y���[�@xpLw��t#��嘍@���L%�k�tqs	b1�/]�huȚ�2�{ד�F{��+�|�@ּ�\�1&'ѕ	`�K�,��]���m�V�
���/������}v������������R~���0X�\Z{�� ���C:<��+rʏ��"��7��¦��SY&U�����C����V��pa"0���"B�av���A�'Q�� ���-�	N"4+���lI 7�fX�;�"M��ջMd �X鰄��*����+���:�u�40�t�.6�|�M�����X�Y#�KW��kB���.]��wۅ�{ZPXQ��kQ\B[d��$�o�]��ڀ�}�cз�/68�/n��(��U�m�"�/���.��:�4��T������ �^�����R�'�3�@
���َ� ׀	�j !���1�a-��.��v�"3��3������L%�k�tqn{ZR�^���5�e����n�K��0�[����z�1�8���-[]�ȃ�p����wT��W���,�� /	�g] ����:�Muu�PF�����C:<��+rʋ����b�BQ�M;O��L�~�.�2�ݪaP+�a8�s��T�p
�Ɓe�Kwh�8���:T�㶠&8�Ь.�%�?�x��Ɩ��Xݶi�w�  �m2Qf�d���/�t{�YIt���J��N��ݖْ��r�H�UƗt��b�t���.ѝY��A���ly�=-��Z��v�cpm �K��Kv���n�˶kC�e��A��]B�]���\�]��\���.���C�[�:��T�o3�]ȫ��� �_�e8X�t��
��>�)��-��N�oW����� mO!��X�ʬ�0���Q`��d�g&Q\�B���(�k!t�(H�Q\���),�����c�qV
�(�ɅET��G��M�}�6����w��g���.�Nҿ:�_}0�^�S��}���k���T�0�^Y.D^�z��pg�'ы��j�q[�N�D�}�s8��
�.���h� �_J��@=H���)ǋt���A�%�Q���'�,\�܃ ���؅���]B\��kCwT>F4 ���ԗ�~[���&'����pȫ	f���?^�3|�.m>��¶��Y�h�t�֬�B�u(��S��䫰Z�j��CLŊ�*cWK׽���v���{N;��eC���~���Y�37��y�ltj1�_�@�*14�.��$��� ��rmd���k�ҿ<X��E>�P&W3#�b%
��*��.�V��|3�侱��L���m�f���ʿ�Aį]�L�� ���,�S
uR+��1�_+�t�9����04K�42�J�a���>�ڟ�_6Xhc�u��P������ǖ
��C� Q�l��}��r�6�>sdKrผ�m��ۖs��4}	���B�OӅ�n}�\i�[].�ف��Q��X�,k9�����kmr}�Ȗ.��q9o��C޶��/��K�_LLy�/�����ݵ��-̷��C�����c���D_C�7�屑�k!
;������C�4�X������A �`�.D>�J�+�0��hvy�\��"��m�A�F	�v3������Io��3���R5�E,�.�������K�%�O�����Þ�tx�����!�½�<>2|t^^t�%��满:�<*-˂��� v��&\��fy�v�#���vj�.0o���n.o��L�f����k��0�|� Ms�12���z�$���u�>�kg�m?��B�B��½?/0�^N���k3ܛ�c-A$�t(��A�����  ��M������N��u��.0o���n.o��L�f�����g@�J]�J��0�#�Za]� ��}��Nv{�P�zX-�a)�o�����y��>��G&�������u� mH���A �6aC䟔�п|����e�@������r�0HۀM���t�p�40��Bh�	�Ld������C|
�g��-��)�el�6��y�?��ǽ������� �2���ō,x�,���ۃ �&l����nv�����@��1Yi_%��n&x\q�\/�����C0�#�MM��vg�%t_�\�cn~��Ng�oe�o���G��y�3�N�`d�L)��Rp3ӱ,'����ȟ���g[#�#!�y۞� m.���5l��]\��&�"�]*�����3�5t��
�S��
����[�L��tx�tx�G^��Xr}��� K �58^����� !�Mna9�X�<|�6�j�<���ms��|�|@W��2Z�4}.����tl�
Ļc»ؽ�}7��*EdP�/]�|+���>�q���_��/�@@.�G-^��k>2��s���O�7K��eqI��> q�
"�/�0^�-��͡�ڍ������m.��א�ػ��:����\r.2�һ��N׿�.v/t߻1�r��(�v���ߺ��?����>&iH)U���#õm"��3#�
Ǣ���9!� �"����%�[�Y�hu	�|��K���Y����ֱ͖��ME�������&|��k����6^/8�.����Z�s���7y��X�{�D���r�W��*o��W�X`	,#�V$�[�E�6ۻ�}����R-{;��.G� ��.W!���X����( ���okr"�Ժ�� \rTV&�o�w�C��� �9^. ����0��o��d ��a}�9'"�D����[�c��i]���E�@e��eE{��k�P����r֡T�*�B�p2�]4+ۭo;�20-L`Qu
��>7�.�l��Yg�=K�v�u��U���e����-{`�lv��l ��R�/�vay��,�7][}�o}�|�$ ��-܅J��Y�7@�g��B�nẃ�B�E$]m�t��%�Ѐ���ڲM/��_&�շ�Z��F"�R����J!�W�wC�q��]R���f�[}����~ �V��xP��[����o��قs}XU�n�����4���e�vڹ���=ۣU�.X���8,�շ�K%��E�=L/��W,  ���w���S&�ND�|Iuو�'��wd�Z�K���p(������Y��D� �J�
�$��r�ֹ� `6nu�����Z'j"�`�;&W,ó07�R X���U�D�\e�P�
W�:Y+����� KZ���@����PN��P*��o�EED.���������@�.�?7 ��_�E5"��n1!%K�*���C���͒u�wad�(R�o�w�9�@@S�Z�ӵ�>kByzױ
h�,d ���@@	��=P=�GoM��2�b��l�K"����Yh@����\�c�EY2��ҿ���T�he���� �j�h�T��4賛��e��8�x]X�s�������Y ��]��H�#r���1k]py���D�i���@�n�]��t��WG����-� �	ޗ�2_�(vY��*+˻b@��+s5�=YTsѾmu3������b�P�|�*Y%�d������K7_*���P�V����Bi��.��R���`�YLp��p����������n�zqd�.1���Y�[-�8�E�Ja��[��R���	�����K��K��D@ﶴ���6�W@N��pd%�)���E�鸂&� ��v'!77���8"ђ���%Q$ ��f���7V����
( q"�h=.�F�2��"���`�ƻ=Pd�l9.�d7[f�l�^�B�F�x1#ʏ�2����U@�\m�X,��x ��Έ� �ɗA��oӆS��䊂#��.w�7��Ќ���B��^-i�q� ��ɮH����ю�q��]nd�`]&!�����T
���@8��]�b�dW�C�w%��(+������c�*�X<NޅR����n`}�xy�~{Wj��zcd���(E��L���KK�H`^���nun�h���`T�ܿ�V=&LuF$ ��Y7[ �:0?rDb�#�h%�	�Ӯe�^ ����s�� g]���ٔ9����r;A�g�r�/�%V<C�[�����nb��uK� �Ϊ���W��R?0rp�s w�6�e!Ż�VF�f��+ �_�:� 1��[)	MH/n�B&�oF ���Y���4B�3#��J~����N�#�$:�� �n�V@�c���H�W��؉:�4:��K��[-����`�v3+���gv(�R-ļK k�ʢC@�����
�NB@���w	��_zW�@�/��Q [�<�>u�c�dW.�.!lD�A���ʠG@�����2�2�׻j�8^�K� C&���.�'��N$&p}�d����We��wYe�Bzw�;]��K62QR�a�AD���4�Ji�,f�4:��uy
ر�u���"��7����{+1'!�I�l�""�w[Y� `�6�F�$,��!��e!F�$�cX�b%9���@ J�}��A��K�(�^ �▊�">\Q���4����+`���l��F��� ��rm�Q��]�p�kv�%�۳t��F�� ���%�},PËF��mv���L�}�Fo�� ٕ �'�D�d!#���Żp�ԝpXL�>��[�V7YM�`DF��BXX.9����ـ�0z���x���7i[���/�֭.^ޗR ���k��uEQMP��n-�f��>R2�6�,��.�­5�mu3�T؋eh��޼ŻD����r�s�� ��Zv:���-�}(��4���B��b��%Q���*��#K�[ZF֙��� ���/�.�5;���.^6��e��Mz���} �-k��o �DD�C�SKxY����\С�eL�lf��Mh V�dO���~=�5�rk��Q�˙��n����L��c��Cd��0��@ |�C.�:rPj�$dO^$�*�ͅ�Fܫ�%��[��Vw�iQsH��
���,)�޵�VW��*�������a��fG�����x7 �E��2g݋�m��đ�v=�
��x��\��	�
���.'�1�n޵DXy�C��wj��9eR���!ɮa0؅y�Fg��c}�V5��'@6:��i�!:����e"�u�(�Uqё�DU��s�g�l�a��V��k���v;��q8�V(Ϥu��5K(�X�w@*߱ָJ�Mʤ���"@it�b�.g�o�hR	d����wֿJ�^?�L�rY/�Ȑ�,����zl�/����;�p��B�p2����6tZ�"9���i�#��h���>��K�vou2Z�S�t��方ED���2��V�:�~�$\D��F�X��by�2LT��u�su]���+��K�#$��@[�<�z�-e��8$K�
49���*�(���u7�����Ρ�.V�Tg�o��hr���w2p�#��3P����H�:�%�P�3.\Ut?���@Y��/��>��E��̌��"��!1�&$t�E)�EģR �;�.1͡��EE�B&J&�T�"*���YH,+Z���RU�b�R1 J�(��	��p���'�t�_gj����r4�zW㐮ǋSHV���;02/n�@bg��V��~��	 ��zs����=8h+7$6�.G7����Y	N��BqK� �ލb��" ��0�PB�\0�1aJ�G8�����R
t}^��W�`�@��.-΢�.��/︂�Huĝ$ %^gj�{�(�lY*S˧��A e,��ʗ.�E:rtk���V��2SW����=�A��5�͖͎�ӷ��u���%�I��:���%Vn���ʋe�&J�%�ׅ%P?w?���b��P�C��k�0��� #�m�"�Nw�G�H��6�H�tX����RY�̈�v�t[����	�-}rB�$G��`�c�\.8��fP�k��F�#r@ � JH��d���+T|�����$bh$\3�V�rp8�VnHNm�� �F��M�b�pK�c.����F賛��e��8@��Y ��Bl�:7@�6�,-��sW!���c�^�.K.���|y_VR�6;���b�}�68	�t~=��`5�(MR0}7��@@B� !��(���" `�6��� ��Hz�� J�^���;3 �8�$�ӵ�e �y�|1!�Q��� ��)�����嘨��X�@F;7����@�l��л--z���-��#+�{~�^��<��/�	S�{��B����_��N��V�+��	�tcqJ���Y`h�� /osU@�����w	�u3uq����wl��^�{�ڴ������A|��[n-���!�ʕW%�R�-n�*F�rc�e���b:�D|�X�dc� ���K��K��D�
�h��"�Yk�w[*z�}�*������ڳnl�:�\ȱ��j1 V�2���g����jre��n�Z�� �n@�X ���� ��۫]�R?�? �����.��xƽ.4�Ԣ�Ʒ�Jp��
����Tg��΢'��
����:V��&j����B&�b �nĠ��
��e��]� xF�vʵۇ�qy�j�� ��wWu�j��w�B0�r	,��ܲ\D��l�� /���+�R.�b@��/V����v_D���T��Z�{]�;�p8�V��������:��$�r@ʵcKu� ���,]����ׅ6�HWK.��[k�L-��4�ڑ��ug�]�ҷ���S�e��}7?���L7^�J
���I.��x�B��G~ B�::��<�f����:|��_5ȳ�r���ebIuV�;���:�G�:0?rDbiC��v-���P"��:��r�u9��nC�:lM҂�  걒��r�wh���N���q�
��J��{�@4���u_���%������ze��@[��������:�vns�bG�������Ô�m�󥌍֋[�[):��`x�n��6vo�:��~4,�\a�� �t& ������E`�T������^ތHv�E��+Q,a:X�އ���`��"}�+@�vo<&�~#s��,�C2���rm�q�_�t(�x!�ݖ����UѮ���� ���1��eQ(��S���"]��t��Z �,�s����?���m��J!�9�e�:�ַ�YZ>p,�ޡ48rƢÝN�>�]��*Y�]X V��k!�ߗ��>W8}7`��� %��7_��Z�A �W���$��p�;� e�\J�	��|�C��Ż�0��Z��m�}����"-�����<(�rH�� ֏�]&z����o�a��f�ߊ]��+��X �@dXYN9���X�$��qo�_e�F�&\#4�)��3 4Z�C)�v�ºNh�dq������/�qMv[0VK�FJCw��n��>�]�� ��1X蚅�Z�(��me��/4,�z��'��
��e��J���F��nd9�X���۫�:��.8uLe�c�����V8}7�%+%�mu� ����n�[.N@ �o�.Ց7(c�.Tb�o�c��t�+��D��^.&� /O�.��to�`j�(����d�������hItǦ.e�ụW�R>�D}� vl��C���Q�_�#ҥ�բ�`dmu|M�Fh�S�|(�.^�;����n�1S��m�?�l��>r���:���X�oZ.d�L�dI��Wa8�V�<@�R�}��ŻHw�����U���m�[�g`���/�#O�j����5�e����s���B�FQE�F�8@�\���P�t6f�FyF4@��Q@�6��5�#c�|�E��i��m�1�?�K!���T+D�V�hYj��z0���*��n-͎�F=ZF�@�R[��>wcMu5P�|7໵�r�"�?��Z�.�����
%�6��9,������w�� w} �#�p�n��]��unM�	�BD��+a����]rl���`�"�N����2S0}7 S��z}�/��@����շ�K%�:�����o�����C��hE|+���_*�PaQA��6u��Z��d��� ,�#O]b�T�:@�+H�E�� �e�J��Aq��!�	�� y�}�#bn���������Fd���A�򱚈xP\@M[!���0r%t�E�hEEt�d���Ba\8�%�z�X3���X��BB����M
��h��J�Z׻�%Z�9~n �зmv�%޵o���*����H"��.�B"�s���l��ݶ����Y�e�>\�ӵ��c����/��%P�]� n�m�Kt�.�E�_ ;@����D�we��Y�#��ex](�%�Y�6V�X������%\�U@@�Gk�����lP�ٲT��O]	̸ӭ�l���u�&�A���3)X���b0��K� <"ђ���%Q$���h��wJ�X��t�6�� {��J\|������:������ڿ!qn%��, X#8�ED�+�\����}���ꂇ��GjR��������D}���X����f����]4�Ó�w��c�\lߦ��}�m���a�Fa�{C ���?)@��d�Kvɮ�
x�����.ɮ��� >�_%��X xw����.6¿��]�8h�z�� �����l�ݨ�ꂇ��Gj�ͮq�����ع=]���HӞ	V �/h�ͮg+zejh����.�#ڱ���r $���8 ���O
��hza��H�h���6���pQ�*�l�^�J���875��n2`0o��QC�.:��i7�lt�R'lF[��le���VG/��ZJ���Ż�BT�,�`&�9���y&�w48��[��|fa�0`s�(<��Z�p`�� �l�K�
FΧJ���W@�Y.,�p.4��P�s.��6r�z�Z��͟����dW���+si,}@���3)X���R��
h�x)P@'�. �.�Ve�@nn��(�B*[�EB��m��P������`�\z��B����"��W�M�}��A��p.����Z% ��0��1_�(`��:J���Z� h�D)�7_���3ql��Y4�l�<�B�J g�[+ `��>�p�d������R]���h��o��]�D�� ��w�d������G��v۱A��-Q��t1#�s��S�N��<����R�\��;]��u��pc[+�2W�@*�R��������u���dwm���٭w��	��r�`�f������w��悀*f�Z�(<�PD	��P�0O�Q@u7�����j"!#;�x��\�dTs�G3�핀�%��qch�e��8��D��(�ſ�u��7Z9�g���ʗ���N�K�v�h��������q�������w�����{��n�>���?�����=�s2PE�5y{��������ֽ�s /:�˄(�V�� ���`���h<.�<D^Z4�.��Z]	P����g#~D$��9�b��O����}����6W�.K�)ʂ2+"S���G��h�o�ڷ�oX3I5�� ���n `����nt�@Q�W����r�a��[}�r�]y,�����_��k��� ;�P�����]��'����5^��,A�[._/�?܋��9��
�HȖ��s-��7�q{ݰ��U�e�h����w��I�0�M3�@�F�/ ���.�*J�AQE���u1�f�`� -�(ٌ��C"����V�� ��L �֛+��U;U���E�ࣣ� ����Q�����JD���bA��"�n�v��}�Zfj�t[@��%��e,��ʗ.�E:rT�_#]�[X(�#V�j�{�
ȁ�^#���r�<$���ES������kheip�EvY-��c���l�XB]���O��Ψ&�%P���lt��r��|_V�k�Իi��
��mwz�rS�*/E��z\ %�ve�����:�v����#�ٹj���VF��]%c�����1W[]�����76@'��D�M���	^�twV;��x{�����$���m�*Ի�X)���:+h��XQE��i��������� ��.^�����($��𹋗�n|1"F��C�d%��*�����ut)c9��E�E��J!Җ�j�ߗ��e��
�n�7��
�����ſ��T-�`��l�<H�;7 ���l��/��8$� �������F+ ���e��/j��},/���P���@M���X�+��Qy]^�z7�Q�V�-�pb�� ���P�g�k`�����`�r��pe�q�\tX(g `�co�d����]�Y�C^�z7 PB�Jd�!�h�:+��:$�������EtX-�%���Q���b���ns�>������)@�� �i�p^�`�����pf�d��/����f�� uؿ��KND����{�O.�ɰGkn `��j��V4�ulDP���R����JuGDđ%�--#�L��q��t��ъ�[,�7��8ع�,T�rI��Z�]�{�f 9&ǻ��v�r�B>���������\��%�D	.��� ��)+]��c57�klh�+s��z`o��T���g�Ԩ+�7Xf���:ܻ67 �+��;n{O�C��܀�h�+�����*�_��=/�{��m_��nS��&�^���ʩP&��Fgʹ�.����.��C���p\��e+��  �c�q�(��qaQ1+b��@3�V�/H�8���zx`X(��a��C��5�U����:����R�d��ƶin��u`U�����?���ַ���n����<<л.5��X[�K��k�
(�o��˥we����4��NH�8�(���X����m� ��%�e:����Z�w���.���ޟ��0�a��rg��%&��r��T@,�lPU�s��zD� ZAB��n)PƳC��ۺP�8�c�[�p`�n�\2�7K�@�M@�K�/٨���
Șs������x�u�lܖ�V�j,UB�n����i�g7���f�q�����!<X��e�� ���b��P�Cu8U>u�%�9� X��o�`Y���06��%��
8V�e���۫E��;�C���zy��]�f	w���^,ֺ�"" ������"]�0�En�w�B[VN=Z�6;�dB���E������� �ЎS�%O�%�e"�w[Z�xy�[�+�'j�8��Ӕ�z���n_= �l����fd
�j�m�C��P��R.��$ޙ��14��E@���o�̙C� ��.x���h�HW)$_�1�U*ܢ�˵P��e`�ԣ> G0V�׉�ickQ-&��s��1q��{z�x��^@@�]�z��+ ���� ���
X�6�L4B�+�]�+y�p�ae�ٻ+�R�A��]����#.��p�=\Q2p��F�Bxx�Y� '����_ �݇"��:�n���o���ŻZ��ȅw�CY.��gn�'κ���9���#���^6�_�`9�Z��Pz���P�W �ο��c\��𓻽�����U4@]�f��/���i����ҳj �U2���wp��>\Q�������ip�D�;�����
xL���vo4	蒛�3K�CJ8"��� ־���;�T�����|4��y�F��w�]�f	6�\hv�x�cK�|��J�v�����"W���rg������{+1'!�I�l�""�w[Y� `�6�F�$,�a��f��֑Ezx�>\���bBק+2/�G���)(��R
�N �OZ�[�7�6�
�uj1��\�f	�����V7� 2p�.�Tg��zա�
[����@?�C�׽?sTP��n-�f��>R2�6�,��.�­5�mu3�T؋eh�0�d��e��PĻk�Kvs�U�y<�e,ԅJ��m�]��]F�X1�
g�\U���e�Ku�V�o�л��N�|GJ��;�`��M�GE�R��R^�
�p�k%Q���t�Ѻ�in���9M  ���o��X9&*�{�WD	 5��=0o`@	9����ٍ/j�و�,�=�9*�΀�b��B�:Ae� ٛ#�m�@���r���^���\�|k��\�87�M�w���	��)�}_�y��	�
�Ow;,��om��Y�����+���I��`��`�UR��&�r��7��\��= *�� $�t%�"���û�a���y�府g �I�S���$�+D�ֻN-V���~ 6�Xy��$�]_o�o��V�R�o#$Lw1]����-��dah���['���&��-a�)�
Ѷ�_���0P] x���:�0�K� ֺ��Sg�Ê�n V�@@EEt�D��h���JQTQ��Rq��|������1O�
��]���:TTD'8�����Z\�@�|)��6u�	QLh�}�#r����=s�C*�G�4��P�&	��
�^Ȟ�cqH�+�@mv��n��\��Ê�n V� S��:[��_���!�E�T��E�H�C���\��	� ��%��:R��L/o��%��FLu��L�t�e|WV˛%��� 5�X,O���,f$G��nb��s÷�\�@�w储��2W�ݓU@@�j�������b�� M��)�ׇY.��ݞ/zHv:,��N�믎����� �us��]YV�w�z��6�2����ⷵՑk`���po%��6@@�r�
�l�����4B��Q ��b�tXu��'�?6�#-9xXE��""��m�"���P�hW� �I�3`�#\p� `��Y ��`�ͮ�]pw�RX+��-��شM,�/�V�ӭw$����l��q��� �^���/�����YX(��w�th�����p�;��b��md��, xomp�.��G�
���#=���q��.v�K�+�W�QhDE],xƑ������#8_�ܞLv�[������pty��l�k��}�qkED
൵�-v1]����e،����� to���e���avl�V@�P7Wɼ�@�V�i7�lt�R'�.���.Z�L�b0��">[���/�Bk����:���s'�ޟ�
V���Mnx}�
��]_�\���B��Pito��dY������sԑ1�� �ϦE�F$OV҈
�2�����s�N��i�^8BQQ_�V�� ���hJ	�K�vo����*2V��һ:%މ�h��̏�ꖋ�=D�ϝU�Ks�z=�� @�X�$D��KwD �1�P��F���I�c���u鱀���۫�:��.8~n �Y7�J X?���K�:�u1�*��jY/�h���3 �@nƴ8
�|��� `������>_�ޙ�A�x��Q �Tg���� �^?7��8"]�[-��K.�-��eh������R�z��1nlk%Q� �t�F���_s����3u��w��ީ�� l�b݇�N;@U�"�,�niYg�g�lw��we�+��{|H{�N���=��Ք	5��1<ND��F� ��o�P��\�!�]�������3���{���kn   `zx�߫dy��Ya��blb��V�r{��������m�̖�xo���L�PįL��c��w6:��i��W��zkew��[N���^>p9���M�U�>����*G���+��&h�Z�J#ܬ���Z�V��W��H:���,Iv#=D�rf ��T��2eR������2QI��E��ץe���:�*٘�{K7Z��L���ƋG���V�Y{�did>�����������P�,���zA��+[��f��r�i�yw�W�Z&�г=ZY$�VM�,LuN!��u�����w{���ֿU�L�[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://ch4ti5o7mq5jr"
path="res://.godot/imported/output_example.png-9f76c73b5c859fef08c6ef08794e0012.ctex"
metadata={
"vram_texture": false
}
 k���RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    script/source 	   _bundled    script           local://GDScript_q0mxg          local://PackedScene_yh6ds       	   GDScript          �  extends Node

#Run scene to run tests.
func _ready():
	
	##Print "something" to the main log channel
	Log.info("something")
	Log.info("testing values", {"bar":Vector3(1,2,3)})
	#Does not show since the default minimum log level for a given logstream is set to info, and debug < info.
	Log.dbg("Shouldn't show")
	Log.current_log_level = Log.LogLevel.DEBUG
	#Now it shows since we have set the level to debug
	Log.dbg("Should show")
	
	Log.log_message.connect(func(_level, _message):
		#print("Checking that the signal is working. Message: " + _message)
		pass
	)
	stack_test()
	#Create a new logstream that is independently controlled from main, muting every message below WARN. (LogStream.LogLevel is equal to Log.LogLevel since Log is a LogStream).
	var logger = LogStream.new("test logger", LogStream.LogLevel.WARN)
	logger.info("This shouldn't log")
	logger.warn("This should log")
	logger.err("test error")
	
	#create a null file object to test err_cond_methods on.
	var file = FileAccess.open("invalid file name", FileAccess.READ)
	logger.err_cond_not_ok(FileAccess.get_open_error(), "Testing err_cond_not_OK")
	logger.current_log_level = LogStream.LogLevel.FATAL
	logger.err_cond_null(file, "Does not print error since level < fatal")
	
	#Please go down 2 frames in the debug stack to get to this point, since the two top most is internal to the plugin.
	logger.err_cond_null(file, "Emits at fatal level since we pass fatal=true, brings up the debugger.", true)

func stack_test():
	Log.warn("test warning")
	
    PackedScene          	         names "         test    script    Node    	   variants                       node_count             nodes     	   ��������       ����                    conn_count              conns               node_paths              editable_instances              version             RSRC&GST2   �   �      ����               � �        d  RIFF\  WEBPVP8LP  /��1 ��(�$E5�a����X�����$G�6���cy$O�֑$U����?1�Ay������J�V+QZ� Z�Di���Rk��JD��(�V���Z��j��#"�c@�31� �!3� �c�g `2���}�3g^@μ��y�����8�[�׶mu[۶����k�E�E\r��%X(��������8m߮��K�d%����&�wD<�_H���Fl+0<�%C�˄�.��ێ��ӭP�Ԏ��2D��Z"�L�/�1DV؀�f�D�i]
��v���%�y�a�Dd����<^ ��"���+���4�D�֢^Ǣ|dz�]��g���Q>BG١����b��P������P%Q+H��� �"��8�����.�k�����yDo����
�Z�I1��^^Y@�F&2��n!���%`�������`!u��2V�^V�	Л�L�IN@8��H�H��f 0�,��wY8U$�&F�o%���M@��=������qdPˁa���wf�]� �]j
9�Af��Bj응a��mq}�S����S��H�dw�"�p�����KHlQξ��P%���Yvk���Л,!u��`R�`�CfL�dWD���!g�ǉ���HhǸB���#��Л<"�s�ŋ&�LC��L���LěǱS\!T=��}C~�[�S-;��ӛ"�[h
~��n\��Ҹ��,�)5dc����
���͘Sg�b�R����ޮ�T �V^Ĝ�9A�P�	M�B��ЛQ�[��<7�P����M`�=�9jB�ל'��:�C��32]�,��`�e�G� b��'^@� �IEz�� �XV�-��W�Ǽ���-F�?�B�]��D#�K�X�[�HU��{�(_ :]-�a5���7)_��9�ӂ�sM��dr��3��yRb3�G�Գ=��
`��4��Ϣ�:O1�C'�B���=����dO�!4@�����h�k�㘥7
OcmQx9Pqv�j<��5���T��ÕC����~���n�A���_��nŮ�����l���km�P�����v��:��j�a�G������f��4w7j!�ׄ��[D����*'�8�A�GH7	�b��7�tX�2����x���n4�7e��1qؑd�Q�r��+�G���i_�������
���6Co�F�_]l+	�`s<������ɎP�)	'u�<�l�Ȗϼn"}<:��xI8��
w����a�9�9���.�S��δ7򁍠u\D{@�=�7"�j� ���c���j�W%ㅹ�2~ұO̖�F�Y��U���"4��|��K��.5R/���2�&�u�50:*���> dJļ3��$X��AH��Cρ~fT�k��>�z�}���fW��0������Ys޵��B�43���:� E9(�UV66�j.��ơ"���csj�p�<=��ڐ�9`;i�����ͮ�I�gu��ՈKu�X��YŜT���Q�tNRQ%'�Z,h<¥��5�6����$�)�q&U�6PL��}x�sM]
��,o�R j���"c8�|����)'�"f�=P�3�Ơ���4�峲pl��oqE
�*fL�k(4[�_OO��YVгZa5���1��3DY�"l��5�
�sj�][�Q�y�����p�wC���<�F��S�3�ЕY��:�{lP�fM%#�F�x�;G�a���B#��SWו���cg.��oy�㰍��ȧFH���%��1��6�J;1�9R��&�����b9�_#ڌ�1�-��T褦��{6�J�%i����'��^ܙ���٢��=IМ��[���vش� ��)�<�l����c{78�AL�H���)N���(~�hc�ꢠ� �s#RV�U���� 8�9��_r��1)[�4��YIz
"�e�/�L���p�|q$�ǁw��`��um�����lq�$�?�ARB�d�h�̻A��c ����-�k6��(YD-������yף�/��2L�������[èE�f ��|��MVP��(ZBM UnYH���
5[Ǭ���66xݢk_@��KӘ��2���Zk��ק�gj��� A�����c��q+�TXWs��=�]��>�e�������1s;+�I��� �h'?�<�Ȩq� �_��np�B� u���5n;�������<h�Wv�(�ڜ9:���;,�_��#���@N��^of��k��`��"n�d��E'9��}�*�,u=-�fս������Z��2`���u=��z�`2�IWֽ����� ���a�KՌ�=���gیD:3�*c��I��u��} �0�g�Ψ���/;Ki�.�C�s%�ſ�d�����)C��U�)ڙ_�M�S���,�f_Ig����(���z�7�v��K�h3lQq��
�Ft8Q����{��9��G�x80����ؖ{����p�j<�j�	��w=%�
L��	�Ӆm���̄bRʸ�8
�;�m]L���YOu�u@)�]3���X�G��)�e�Q�zQ�m�{2��pXZ;an&kZq�jX�
.�rh.j��s�V��w�A&#t�ճ�����)$��g��w������ ���*�C&���^(����oM�I��r[�wC��; �:2�ZTD����_5�JԬ_���<�= .�QR��b�=з�=����GX?˚8[Ǵ��8bQј_3R^k��`���^a�ꁰ\n���N�a���]n7#�BRr�ӷ��}si�p~�E��
8oз� lK��=ʨ�5�*@Jf���)���ҽ��`�E x[�u�ܛ��qN�N`3Ό�5r��,UUJ���B��f������E�f-�Z�n�tk��?��~�C�K)ߕ���`.z#�@o&@I<to������)����F~���ǁ�4����
i�(��eȖgv�bi���Y_!�Q���خSu峓`+������Icٲ.�{�5����_'� g�Hc���}X��'�yg��t�Mn�q"��$���]���r w�3@$KHO��R:��W+����e;����QQ���]��&J�%{��Oe"��2�-�� Ⱥ�m�7Pg�e!x�eza۷p�-ћ2�̥�n��
�,��������6���W��� �S�]3���v�z)z�𽅐zx�R�:�9�����!��C����Y��al�~�������_|��_�\��_~y����>�����ھ~��o���7?�<����}x������_���}J\f�����f\��bI���{_]H|�&㛇�W�.�͕�[��x|�>�����_��ү��o�|zx��<,���g��~y�����������B|����_��Hﾺ೥�>^ǽ���5���ӻw+�>���E���G0O�1��_���>�{��}��v�o6�~Ᵽ���8��V�^���g|��a�G�G{@�[����Dd�es;��ЙY�y�+g󁴵���LKĿɾrP֪}0gv�+Kg��W8{u��])=�%kGmL��Ӵ���wY���Hgگ�Һ�p�+iC��M�У����..`��䒣G}a�[̴d/����uEO�{��XA�bO��ۭ��6���=�����כ�����)z���
�{Z8͘+�%��+&���'z�f��W.��;.R��ꞹ�.�?=�g
�(�ˠ����#��d����GO�^�39�{E���C����}�3]�[,��]�"�n��K����N3H���r�?�+3��z�jɞY�8Kԧt~&r��,���h����1,�!3=��S
(�s�Qts������L�}�h[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://cmo3o4p16nfcs"
path="res://.godot/imported/icon.png-487276ed1e3a0c39cad0279d744ee560.ctex"
metadata={
"vram_texture": false
}
 @���k���!mD��GST2   �   �      ����               � �        d  RIFF\  WEBPVP8LP  /��1 ��(�$E5�a����X�����$G�6���cy$O�֑$U����?1�Ay������J�V+QZ� Z�Di���Rk��JD��(�V���Z��j��#"�c@�31� �!3� �c�g `2���}�3g^@μ��y�����8�[�׶mu[۶����k�E�E\r��%X(��������8m߮��K�d%����&�wD<�_H���Fl+0<�%C�˄�.��ێ��ӭP�Ԏ��2D��Z"�L�/�1DV؀�f�D�i]
��v���%�y�a�Dd����<^ ��"���+���4�D�֢^Ǣ|dz�]��g���Q>BG١����b��P������P%Q+H��� �"��8�����.�k�����yDo����
�Z�I1��^^Y@�F&2��n!���%`�������`!u��2V�^V�	Л�L�IN@8��H�H��f 0�,��wY8U$�&F�o%���M@��=������qdPˁa���wf�]� �]j
9�Af��Bj응a��mq}�S����S��H�dw�"�p�����KHlQξ��P%���Yvk���Л,!u��`R�`�CfL�dWD���!g�ǉ���HhǸB���#��Л<"�s�ŋ&�LC��L���LěǱS\!T=��}C~�[�S-;��ӛ"�[h
~��n\��Ҹ��,�)5dc����
���͘Sg�b�R����ޮ�T �V^Ĝ�9A�P�	M�B��ЛQ�[��<7�P����M`�=�9jB�ל'��:�C��32]�,��`�e�G� b��'^@� �IEz�� �XV�-��W�Ǽ���-F�?�B�]��D#�K�X�[�HU��{�(_ :]-�a5���7)_��9�ӂ�sM��dr��3��yRb3�G�Գ=��
`��4��Ϣ�:O1�C'�B���=����dO�!4@�����h�k�㘥7
OcmQx9Pqv�j<��5���T��ÕC����~���n�A���_��nŮ�����l���km�P�����v��:��j�a�G������f��4w7j!�ׄ��[D����*'�8�A�GH7	�b��7�tX�2����x���n4�7e��1qؑd�Q�r��+�G���i_�������
���6Co�F�_]l+	�`s<������ɎP�)	'u�<�l�Ȗϼn"}<:��xI8��
w����a�9�9���.�S��δ7򁍠u\D{@�=�7"�j� ���c���j�W%ㅹ�2~ұO̖�F�Y��U���"4��|��K��.5R/���2�&�u�50:*���> dJļ3��$X��AH��Cρ~fT�k��>�z�}���fW��0������Ys޵��B�43���:� E9(�UV66�j.��ơ"���csj�p�<=��ڐ�9`;i�����ͮ�I�gu��ՈKu�X��YŜT���Q�tNRQ%'�Z,h<¥��5�6����$�)�q&U�6PL��}x�sM]
��,o�R j���"c8�|����)'�"f�=P�3�Ơ���4�峲pl��oqE
�*fL�k(4[�_OO��YVгZa5���1��3DY�"l��5�
�sj�][�Q�y�����p�wC���<�F��S�3�ЕY��:�{lP�fM%#�F�x�;G�a���B#��SWו���cg.��oy�㰍��ȧFH���%��1��6�J;1�9R��&�����b9�_#ڌ�1�-��T褦��{6�J�%i����'��^ܙ���٢��=IМ��[���vش� ��)�<�l����c{78�AL�H���)N���(~�hc�ꢠ� �s#RV�U���� 8�9��_r��1)[�4��YIz
"�e�/�L���p�|q$�ǁw��`��um�����lq�$�?�ARB�d�h�̻A��c ����-�k6��(YD-������yף�/��2L�������[èE�f ��|��MVP��(ZBM UnYH���
5[Ǭ���66xݢk_@��KӘ��2���Zk��ק�gj��� A�����c��q+�TXWs��=�]��>�e�������1s;+�I��� �h'?�<�Ȩq� �_��np�B� u���5n;�������<h�Wv�(�ڜ9:���;,�_��#���@N��^of��k��`��"n�d��E'9��}�*�,u=-�fս������Z��2`���u=��z�`2�IWֽ����� ���a�KՌ�=���gیD:3�*c��I��u��} �0�g�Ψ���/;Ki�.�C�s%�ſ�d�����)C��U�)ڙ_�M�S���,�f_Ig����(���z�7�v��K�h3lQq��
�Ft8Q����{��9��G�x80����ؖ{����p�j<�j�	��w=%�
L��	�Ӆm���̄bRʸ�8
�;�m]L���YOu�u@)�]3���X�G��)�e�Q�zQ�m�{2��pXZ;an&kZq�jX�
.�rh.j��s�V��w�A&#t�ճ�����)$��g��w������ ���*�C&���^(����oM�I��r[�wC��; �:2�ZTD����_5�JԬ_���<�= .�QR��b�=з�=����GX?˚8[Ǵ��8bQј_3R^k��`���^a�ꁰ\n���N�a���]n7#�BRr�ӷ��}si�p~�E��
8oз� lK��=ʨ�5�*@Jf���)���ҽ��`�E x[�u�ܛ��qN�N`3Ό�5r��,UUJ���B��f������E�f-�Z�n�tk��?��~�C�K)ߕ���`.z#�@o&@I<to������)����F~���ǁ�4����
i�(��eȖgv�bi���Y_!�Q���خSu峓`+������Icٲ.�{�5����_'� g�Hc���}X��'�yg��t�Mn�q"��$���]���r w�3@$KHO��R:��W+����e;����QQ���]��&J�%{��Oe"��2�-�� Ⱥ�m�7Pg�e!x�eza۷p�-ћ2�̥�n��
�,��������6���W��� �S�]3���v�z)z�𽅐zx�R�:�9�����!��C����Y��al�~�������_|��_�\��_~y����>�����ھ~��o���7?�<����}x������_���}J\f�����f\��bI���{_]H|�&㛇�W�.�͕�[��x|�>�����_��ү��o�|zx��<,���g��~y�����������B|����_��Hﾺ೥�>^ǽ���5���ӻw+�>���E���G0O�1��_���>�{��}��v�o6�~Ᵽ���8��V�^���g|��a�G�G{@�[����Dd�es;��ЙY�y�+g󁴵���LKĿɾrP֪}0gv�+Kg��W8{u��])=�%kGmL��Ӵ���wY���Hgگ�Һ�p�+iC��M�У����..`��䒣G}a�[̴d/����uEO�{��XA�bO��ۭ��6���=�����כ�����)z���
�{Z8͘+�%��+&���'z�f��W.��;.R��ꞹ�.�?=�g
�(�ˠ����#��d����GO�^�39�{E���C����}�3]�[,��]�"�n��K����N3H���r�?�+3��z�jɞY�8Kԧt~&r��,���h����1,�!3=��S
(�s�Qts������L�}��Y�[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://pbkh12q4kpbb"
path="res://.godot/imported/large_icon.png-1bba27ef5f1ea59c0d4c9d63d489ab94.ctex"
metadata={
"vram_texture": false
}
 ��)ȳ�ѽ[remap]

path="res://.godot/exported/133200997/export-17993b99417730f055893e9f1e3ec3d4-logtest.scn"
ɼ�8��K:�D��list=Array[Dictionary]([{
"base": &"Node",
"class": &"Config",
"icon": "",
"language": &"GDScript",
"path": "res://addons/logger/config.gd"
}, {
"base": &"RefCounted",
"class": &"JsonData",
"icon": "",
"language": &"GDScript",
"path": "res://addons/logger/json-data.gd"
}, {
"base": &"Node",
"class": &"LogStream",
"icon": "",
"language": &"GDScript",
"path": "res://addons/logger/log-stream.gd"
}])
�PNG

   IHDR   �   �   �X��  &VIDATx��_�]U}Ƿ�L�hB$������g�E|�v�',v|hշ�V�o��M��i���g��_dF��Q��QH���	($I�]��,��w�ߟ�����s�'sr���ܵ�^����Y{�s�r�UW�oS�Tz��T�@*�*�JE�
�R��T�@*�*�JE�
�R��T�@*�*�JE�
�R�T ;ޱ����-a+�}6��ϕ�yW�_�����<���ak-g����u�;̡#G�C/[k���g^l^y������B���h��a���~�1/c�=ic0�@��d{x���=��ʫ���U�Z��?�<l���c��㱰�&�.	[2<�lx[k���KN�ǯ��9���aK�w>���3�_��{,>�������	[2߾�@�����t�C��,�@z����
[kY�~Ns��v�-���^l���밵<��w_�d�9x(�>xَ����d~p�� ��ak-�K�"��:��򶷞�ܲwwؒy򹗛��ɰ��+vnk����d�z����|�y���ak-ֶ���1�Q�1���ױ��<#���_k��Ӈ�V?�ɐ&t��ͮz�-�a��(������40֔�|�O>��y�3Ö�gB��ľ��3�O���d�T�
�!������Iö��R�o�d�Н�>��������N�bY��TK�r���mg���Hs�7�q��BD*��RԂT��MFRa;e��X�yj�߇�YH�=s/��@� �����o�Y=�Ԇ�҂E	�?U�Y��:�R+�\j��֮�FV��?)�k5L���Hm̫��C��}�
���%�:	 M�i��E����?�q�hc*�H�g/���`n"��! E~�r�>OՇT;�Ũ�H6U�q�XI��t���^�����	��
O����VD3l���g�X���mX�E2V��xSEi�c0W�32iR�x��#Ж#�$Ж�[�����4��H&�1���C���Kn���i�����dn!��qϥfqH������Y�=� �}�ڐƸ�Tߕ�G�q�!�c}�Q��#�)�Ny�6��#}��C���������Ї41�(��.0k�'��0�%^k^��ûP ����@(�95�]0f�8��+��� ����%��44��0LKZ?���v�](Xj�`)#���)QJ��i��a�ͱiH9��v���RƔQu����x4�6J,��Xj����{
�������D�!�$���J�UdRd��`IN�چd쩨,��̵@0����CD��"�t��Z�jE�%%)ճ�E�d)��"	�چ�P�r`�ܖf.B�ػz�+��Ha;����[���4�r0He���X=��(Q�KQu�66�@��Ջ��zx�=�x2����Ӗ�^��e)5b���V\[
tZ䃧�}����1s!ro�g�s��#�C��`���!��`mGJI?K�!���=U��|I)'�Y�˩X�0[�>k�B!
uxzҪT���g ��j� ���
$�k-�%�[#�ɬ�#	u��T ՞�NX=�<�9 cf�V$���E؈WJӬ���V%�|k_$�Yt�&�'&�u���1M�X�<$xړ�4�Z�KFi�ښX�y
Id�⺋�慅�f���D0"rcIt��Aa�1�ڲ�4Z;��]i�H{-��#��ɤtq�X8�`,x�T�چI��d�
a���$i���[=�tlV�J}a�%t�b��"�Par��)O�&G���|����`Y��Vc鼅5B�iy׺��sJ�z���"Y��Sc~���dz7!j��}֜�b4j�!G,^�ư-h��ږ�/ka-��S!���Z�)�Q�qN(%Vm\K3��8����������+F��x@tO��!������f��1c>���C:i���
$���(�#b=#�E2��W��6���X���j�VJ��QH:.����*2�c07a�?>R�ƻ3I^$�h�<��bH��H�EP��g�QH����I�?,c�!BM�x~����[ ����`�>[���1 �iZ*��ڲ �5
i·�U�֖���YI&HI���ճw��j�c����iOk�z�C3lkt�<?s�@,H)�V@�)�j�\��5@3>`?���<���|�.�m���� �3��v��h=�B�̕}0ޖT�
D�t`�\�'�0Yxz�1�V�X�49-�>H��'-
Y<?Hb%U��Ԩ逗��$w��l{�G��3���`)z ^kdӄF��o�S�?��qYS�*�S�� j��	����ճO�+˖)/�<4���)-��,HE�5
i˻]�����>l5���g�xxL����a�0��ó�CZ``��	n�H���!"yY��5z�B(��b�،�d�ֺJ�B���Ȥ�\�E ��[��2��4xc&��#)���k/5��>x����J���c���9�yeR�x&xx".QIMl�qhux��R5�f��%՞y��|k;Z晥�KJ���6FLZ灴C��aж�^ kJ�ToY/�'K�у(�!E�ygi��b2%#k�8(RI�<X���ٞK���0B��� yk�p%ђ&3~��j�Yx��NQgH�L��y`_��K{�G��$8�� -h��Y�G@ʗ�Ѵv杅��ʈ�+�p��m^؟&�;㥭h�g�d��������8��`�Qj�9g���:r4��`��GB�%a0���� �8��"��]�gLZ�����+]�G��'����ͦ�O�g5[�|��?m��4!&A14#��qh������㝁v���{�K;���f�V��*��h}+��
�to����ȉ�[ā'��y{ڴ|�H�~J���9f�&�M:��I�lX��n�٫<��#�9�A��,i�����L��5h��c�Z߬�'2���6Z�J3�@�(Ͽ���S�O��<�&���-�B�8��R*�#��8J�(�ch�9�1E �✾�rXj��	��Q�<j&7epc�zyЌ�?�Z��#6�-�E�4���.f���X��a�t�2qڒkH��hu��x{"���Ў�2{ͨ��֚���M� zз�@0�����zC2���M����J9"��[��`����  �T��[�G�~�fa�we����#�9�����i�f(DTR"8�:58!��m��>ѷ\��.�\���-3A�>0
��x��OO�86Ǌ�Z�gL3:�F- �T�`>�4��øx��q����M������}�P��#[��7�2i�88Fk��R+Oa�AJ�� b�q%�h�iDnƟe}�j÷2�@0.'@��m'/-�w<�Q�Z@:A�ђ� /���K������Y�tm��!Z[��%�qMɤ�x�Ұ�BJ�ʳ� X�\��FH�,�Qh��ъEt��Jka Z[����4����s��������~��R�xh"�ړ��#6-z,*K+�a ��s^%����0����VZa��V{,2K%�,���{�A:�ђZ�0�8���[�h�9�Y�--2K!�_N����1|����Q4o��Exި��C��,�󀃊�6[�X���)`9���
�h�@q�T��RkDX�9��3���4�,q��j���[���4�Ψ%�����k0+iU.qX��s�A��@I����MR5�x��qҗ��|0�g�%�k�0�A�&�E:�����˧L��}yŁ�H�8���3��
mJ���0gn$��?��yD�+����<8�*M��R� -Ei���� m�
h���h��y��SJ-�g�K�Gi&�"���)5C�^J����T�5���<�p>x{	�sc�E� ���,�@���{1Q%���)��K�X��-�6�����G���R�	тo��>k�`�3!�����8(t���k�2n��JK1qDϱ��G	Z L.E ���4��}���1ވf���z8g�1Hx.'��;"s�Q@��AJ������i��L�����h҇�
�m/�*�F���L*�\�q�<d�G�@rK��x�q�hh�
c#E#�����D(��xh�(v�fnB����M�3�% ����gE�؅�R,��q,q�VDӮ'��~":+��>����Ƥa I��V��ܬ9� �S�z�06�|���kt`��>�S -�`7'{yp��(�>&�9��\a fj��F0�x<���n�
x���Z�����y�Pa�r�W��]͕�c.�څ�@��8<4C�9K���(���X�����k�r�^�K������6��>��� ���C�V������Z-�·q�L,�@0J��,R���h7;E��C��9mk��Mn�z*�3��$�Ef�Bxǃ<�RV� &~5᜕�x�.D.k1�>�q m	��k���Ē��o/��E�MaLX͌7J�{X�� c�H��)rE!Z�	�SC��z��͛� Ԗ^�z�㲂�!]��-F�9.>�i[X޷8�*&1`�<� "�"��g��s�hD��0��kk��0����>���g|K0�!����T��R����T��`#\����(��^�F��>	��%al��t%��!46�@�l��Z����	��`�r<X���C�xu��e�)�.YaA����+y�Ad��qn:�4u�ǀ�Τ�\
o���9o��I���{Rrjڦ�
�W��tYj�LƂCL^I�(έX��I���1زZ����Ҷ�Ff���0�U �H���E���`q���y�6\���[9X����Ú��@S	#R�D��Q:RD��Зܔ
���jq�v�<�ŪNhj�@ ��w������e1R��c��P#��+��+�65Dn��<�b�� �Xxaΰ�� V�<u�W�W���j�S���1V�8�� J�H+���?�'�.��B���������xmj��a �uH�`���S`N�ϱ�0�P���A��%:p���IBΊ�&�ܖKW��'��e̌6��eG��k�a?%.�i�cn�]��`aR�tO�L�/�rr�n&�£{aq @R��;�"��bC
�T/F�ȝ0���w�.+o�k�q�RYyk��oҨEeC	�	����4
CŐ�@JE�lI3�T�3��@��Ϲx���|扥���߼4�bC&a�w��B�l�v!�zt�*��ԭ���~&��.z/q܉�c��b)B�����Q C�y
�K�@��g�Jx�At�I�"#�^�.3��8��{D��D�X!J09L�Ϭ�D�W�K�`��oC<�T�@�DBk�+��K��@�.�g���R��0Q�L�ڔ�V��Q�z�r�#DȊ����\��9���(r/"�iAd����g΄h0Ic\���5 �ٻz�ɓ�������~����OAd��od�� a�� ��gD1��0axj�KB�����ܔ
��\���D�6̓�dfaw���g�2�R��{�	k���vX�x���qy�U�5�����[���%ǹ
dH]f���tj�8��[C�;��-��Dr���X0�U a��?��="�ǘ���	�+�˅�b�Vq��z�?@�ԍ(�q�儠
$&g�{D e�<�Q(�����8<u��*�L�d�S"�+�*F:����0V�{FH��e?O��L�X,��E:?�˖~�b��Qq_�a�駅ɞVmr��w-��c��zطw9׳���x�+�c���ar��Ѹ9*�v�Q*~+�@��s��;B:E�1�Xr�
"�'��x���	 �!+o]�
�3�c2�@r
�� /F��#������U<���@� K�Ʊ9����\�3U ��@�`xj̓� Rp�
�9�B�c<����U�z�)Wx�į^ "�Ő	� K	ce��u�'zi�AC�A���9��`C
Q�G��� ��*U��đ� �zR+j,�)1D��1���dC�I����y"
@�"�?�)͋kP<�OVC�ֲ|QN�8h�j���hȘo	�#!E:N�V L˅��G	�(.Y)%@��c�ha�ꅳ�Y@���ǔ�Nq�c}AX��.���4C��1i� 'ǻ��+}���BQ.�ht㵗�<���s�d��3�ڥAU gV9�Ī�w2,`�ܣƐ&��ۛ�c� y{ā�Y����"9��C��x[�9" ���� <��C$��ɼ�a��2�s��p�Z�xm�j���p����h�+��R�A�,y�h��57C��7��{be5�~iF�8�mI����%���丼hcQ�I2O`x�G0��)T�a Fھ���r�@�H��޸��7�k�*O��F�.U #��cL3Q�ǘP�b4^a`Dx�v�4D�Ih�i��EX#*1C�)��MSLx�r��`��E9˛x־O��V�86�ڂf�D-��
9�U��%>�5R�	�	`4S	"B꒓J�%j��.��kS����h#!E���#��\?���U �[��4�L�;�~�NnI��D�a ��@R�dJ�}����=<�V��մ�u���Q9�b2�)���\
�# 7I���1���<B�G�sl�@e�߾�@�K{�̥��xZ��h#%�A
����)�T xK�lo��y@
���cVo��H9>Fm+�L���S�>�����|�`R�x��<�j�»ԄY?�M��OA-}�-Ch0^"Q*�Q����
����
�����8JBzu���aKcL����)��"��h�u�'��
[>�#m�D��T���HiQ��zX�F2�[��mZ���RF����	F��sa#Q�Ko�+��>1�<#��~�����V�--eR�Y�} z�P*e���V8����$�ybC	1�:qdʈ��Z�^�m�w>���m�R�`-���Rqn�B��=<� \
}Ip]p>�/K�S
k���"&�GIрI�H��l�?0�o�u l�c-��%�)zpL��J���)����1ēI�u<`�="��FH�Ԉ�Hyl�O� �C��DR_�;�ִ��D��Y�*��K�\��c�����/P=��4k=v� �عm�At���1}��-�$����)�q��.O��S��� ����F�eϱ��R:b��Rjd�$Tk���K��6�m�H��9������mD*�>~�%�"QCJkH�8~V�R��ZHmXE�-�Z�|����rlK-�y�"�oXų�S�m5i�3�_��Ѽv�6��"���4��F���^i6�@�"����sE�7�Pj�}aR*��-g�K�����8�Ę�XۊT�o�H��0�����ak-V���*i�9��.ц��S!]� �`=��F:�1Xz�X����m-h���jL���"�چd�֕4��G*zXǵ�4�c�p��Q���Cxf���k�v�@�^W�8�@8��*�u� �L��tFj��)
��/]�q�����l;<�7KQ?��d�V/%���]�����_�?,m@�"��4Wc0�@��#F<�e��Ll1Li��ZKI'�mH� 愹�A��1�T Vc�0�@�y{	���c������+��RH����ʥ��j�RJa1n)�!ݴ�R��/1��+�F�*'�QX�����c!9k)�c�I��Q�#y���xh���g�J��휓��+�2n�(4��,uii	Kj0<�`xh��XHp|<�bR�T*�FH�"PR�T�T*U y��j�{��u��}�����"SR�O�|Ss�M7�����M7��+�LHA�@��*���d����5W_�l޼9��4O<�Ds�}���4�^sM�����}������=��4�=�|s���U)AHA�����|���֛y<��;�6{n���p�_�j��=�����V�U ����l��kR;v����}~����_�U e�)�U 9���@s��5��;��ᆏ�ߜ�'w��|��;�VH�������n['!�o�=)W�
�,U �
��o��!<��s�_|�sa�$�6�����a�Ϳ"�^u���I��+_nVVV�)KHA�F)��ݗnoVO�/ٷ�G�?}�M�]b���8��ۛH��*��T��m���K۠I����_	['�����ۿ4+�/^Y����@�RR��C���X�b��;"�'��b*�r����jؒ�)KHA������_���|��"A �!�հ�����j"Z�PR�*��h	K�,��h�`�aՊD�F������+;�����@�RR�@�T�Tk�qñ��6��z���C�iC�a+��������+e��H�H������� (Τ��=����pr�^jR�*�1Pħ��Uy�@��@�&?�����~���
d����P��rUơ
�R��T�@*��ř�x�J�$�">s˙��#G_M~R
>i����c:�&�����ϥ����ľ���|͇V�T���xp,G�o�×��&���������{K�.��u��Mg�޼r��滉�L��^����������:����P����p��E�4|���E[g�����9�ÇW/l.%B4�:������g(�O��=��A9is����B{"������?#8>�oF��{�c(|{U�k]� �=�M�����O����ľI�/D$�}��5" M���1���{��C��r�[��ϼD�l������-c�xG�b̈*���͸��q⛼x��i��El�N����3v׿og��3xOxO�گq���2v��׀���TL.& ���#<[wb!�$�����ǁ�?#���o���3N{�;7�@����f�v�.��@���Ldl��`߱/Ld4���M�/Č��&B��w?��Z���o�����z����п����w�q��]޼%��_�}���wAx1��ǉ��i����o����}�?+�ϙ���_^C������q��]<��yx�TL.&�/�g ��W^=�r0��fȝ�,Otg�fx)�m�ퟙX&C��6�0��������V��Z��c�0�k7m�I�'�֦�Z�_�X����W|����G|?}8;D.~f����;>�k�C���v���S2�@0z�)���A��~fp�0�܆��0L.�*Vw`�?��8��g�y�/����Q�u���#��&5�{3���M_�$ �B��^Ď��Kƿ�^�m%bZB�x�n�����~5 ���<3Kc�&����WN�R�ȼ0��>�����������w������D�8�}���d�����_c1�@� D�$w%�bP�m�� �°����8���h0]�a�1.�H!��wߋ ������7}�����!��i��`��ע`������w7���þ>��w�Ƃ��}1���A2D��y������Ϳ��d��28>hy�5��߳�x���;K��`R�����%g�1V�[{H��ϋ�b x����km�)5���I���<��n��{���ћ�x|���.SK�U֏#�J%�*�JE�
�R��T�@*�*�JE�� �7hZo�*�    IEND�B`��   {�T���I   res://images/output_example.png��X�Yx   res://tests/logtest.tscnB�Fp�YN   res://icon.png��%!��   res://large_icon.png1�ECFG      application/config/name         godot-logger   application/run/main_scene          res://tests/logtest.tscn   application/config/features$   "         4.1    Forward Plus       application/config/icon         res://icon.png     autoload/Log(         *res://addons/logger/logger.gd     editor_plugins/enabled,   "         res://addons/logger/plugin.cfg  M������y�řAI(