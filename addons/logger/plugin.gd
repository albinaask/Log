@tool
extends EditorPlugin

const Settings := preload("./settings.gd")

var loadSingletonPlugin = {
	"Log" : "res://addons/logger/logger.gd",
}

func _enter_tree():
	_ensure_setting_exists(Settings.LOG_MESSAGE_FORMAT_KEY, Settings.LOG_MESSAGE_FORMAT_DEFAULT_VALUE)
	_ensure_setting_exists(Settings.USE_UTC_TIME_FORMAT_KEY, Settings.USE_UTC_TIME_FORMAT_DEFAULT_VALUE)
	_ensure_setting_exists(Settings.BREAK_ON_ERROR_KEY, Settings.BREAK_ON_ERROR_DEFAULT_VALUE)

	for names in loadSingletonPlugin.keys():
		add_autoload_singleton(names, loadSingletonPlugin[names])


func _exit_tree():
	for names in loadSingletonPlugin.keys():
		remove_autoload_singleton(names)


func _ensure_setting_exists(setting: String, default_value) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, default_value)
		ProjectSettings.set_initial_value(setting, default_value)

		if ProjectSettings.has_method("set_as_basic"): # 4.0 backward compatibility
			ProjectSettings.call("set_as_basic", setting, true)