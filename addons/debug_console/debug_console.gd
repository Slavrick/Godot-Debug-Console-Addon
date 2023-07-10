@tool
extends EditorPlugin

func _enter_tree() -> void:
	if EngineDebugger.is_active():
		add_autoload_singleton("ConsoleMenu", "res://addons/debug_console/debug_console.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("ConsoleMenu")
