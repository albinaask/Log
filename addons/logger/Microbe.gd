extends RefCounted

##Micro-benchmarking tool that can be used to time how long a section of code takes. Note that a method call in GDScript takes time!
#TODO: account for this in the calculation of timing...
class_name Microbe

var _name :String
var _started := false
var _print:bool
var _last_time := 0
var _start_time:int

func _init(name : String) -> void:
	_name = name

func start():
	if _started:
		printerr("Microbe session '" + _name + "' already started, must be finished before restarted.")
		return
	else:
		print("Microbe session '" + _name + "' started.")
		_started = true
		_last_time = Time.get_ticks_usec()
		_start_time = _last_time

func finish_sub_step(step_name:String):
	if _started:
		print("Microbe step '" + step_name + "' finished. Took: " + str(Time.get_ticks_usec() - _last_time) + "us.")
		_last_time = Time.get_ticks_usec()
	else:
		print("Microbe session not started.")

func finish():
	_started = false
	print("Microbe session " + _name + " finished. Took: " + str(Time.get_ticks_usec() - _start_time) + "us total.")
