@tool
extends EditorPlugin



func _enable_plugin():
	
	
	#make sure log-stream is loaded to prevent godot error.
	preload("res://addons/logger/log-stream.gd")
	add_autoload_singleton("Log", "res://addons/logger/logger.gd")


func _disable_plugin():
	remove_autoload_singleton("Log")
