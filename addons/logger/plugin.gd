@tool
extends EditorPlugin



func _enter_tree():
	
	
	#make sure log-stream is loaded to prevent godot error.
	preload("res://addons/logger/log-stream.gd")
	add_autoload_singleton("Log", "res://addons/logger/logger.gd")


func _exit_tree():
	remove_autoload_singleton("Log")
