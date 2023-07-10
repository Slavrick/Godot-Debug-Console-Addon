#This is a debug console that can be used in any game.
#
#Includes functionality:
#	Only appear in debug builds, removes itself in releases
#	lightweight, can be open and closed
#	commmands to resize clear etc.
#	can read scripts from a folder, allowing you to add any debug functions you want
#
#How to use:
#	edit the properties(export vars) how you would like
#	set the scripts_folder variable to where you place debug scripts and only debug scripts.
#	map an input for opening the debug console called "open_debug_console"
#	create debug scripts and place them in the folder.
#
#Debug Script usage:
#	Create a debug script with static function "deploy" that takes two arguments.
#	The first argument is an array of what you typed, split by spaces.
#	The second argument is the root node.(needed since you cant call get_tree().get_root() from the 
#		static function)
#	the return must be a string which is displayed to the console.
#	place the script in the directory specified by the variable 'scripts_folder'
#	call the script by typing its name. ex. "sethealth.gd" would be called as "sethealth" in the 
#		debug console.


@tool
extends Control

@export var width = 500
@export var height = 500
@export var text_size = 15
@export var text_color : Color = Color(0, 1, 0.1843137294054)
@export var console_color : Color = Color(0.19607843458652, 0.19607843458652, 0.19607843458652, 0.80392158031464)
@export var scripts_folder = "res://"

const MAX_SHOWN_LINES = 40
const MAX_HISTORY = 20

var showing = false
var previous_commands: Array = []
var history : Array = []
var history_index := -1
var console_commands = {
	"set" : set_property_command,
	"clear" : clear_command,
	"echo" : echo_command,
	"list" : list_command
}

func _ready():
	set_properties()

func _process(delta):
	if Engine.is_editor_hint():
		set_properties()

func set_properties():
	$ConsoleBackground.color = console_color
	$ConsoleBackground.size = Vector2(width,height)
	$ScrollContainer.custom_minimum_size = Vector2(width,height)
	$ScrollContainer.size = Vector2(width,height)
	$ScrollContainer/VBoxContainer.custom_minimum_size =  Vector2(width,1000)
	$ScrollContainer/VBoxContainer.size =  Vector2(width,1000)
	$TextEdit.custom_minimum_size = Vector2(width,40)
	$TextEdit.size = Vector2(width,40)
	$TextEdit.position.y = height
	$ScrollContainer/VBoxContainer/RichTextLabel.custom_minimum_size = Vector2(width,1000)
	$ScrollContainer/VBoxContainer/RichTextLabel.add_theme_color_override("default_color",text_color)
	$ScrollContainer/VBoxContainer/RichTextLabel.add_theme_font_size_override("normal_font_size",text_size)

func show_console():
	show()

func hide_console():
	$TextEdit.clear()
	history_index = -1
	hide()

func clear_commands():
	$ScrollContainer/VBoxContainer/RichTextLabel.clear()
	$ScrollContainer/VBoxContainer/RichTextLabel.text = ""
	previous_commands.clear()
	set_console_text()

func deploy_command(text : String):
	add_to_history(text)
	var args = text.split(" ",false)
	if args.size() == 0:
		return
	var script_path = scripts_folder + args[0] + ".gd"
	var echo : String
	if console_commands.has(args[0]):
		echo = console_commands[args[0]].call(args)
	elif not ResourceLoader.exists(script_path):
		echo = "command not found: " + script_path
	else:
		var command_script = load(script_path).new()
		echo = command_script.deploy(args, get_tree().get_root())
	previous_commands.append(text)
	append_console_text()
	previous_commands.append(echo)
	append_console_text()

func add_to_history(text):
	history.append(text)
	if history.size() > MAX_HISTORY:
		history.remove_at(0)

func set_property_command(args : Array) -> String:
	if args.size() < 3:
		return "Usage: set <property> <value>"
	match args[1]:
		"text":
			text_size = float(args[2])
		"height":
			height = float(args[2])
		"width":
			width = float(args[2])
		_:
			return "Invalid property: " + args[1] + ". valid properties: text, height, width"
	set_properties()
	return "set property: " + args[1] + " to: " + str(args[2])

func clear_command(args) -> String:
	clear_commands()
	return "cleared"

func echo_command(args) -> String:
	if args.size() < 2:
		return ""
	return args[1]

func list_command(args) -> String:
	var command_list = ""
	for key in console_commands.keys():
		command_list += key + ", "
	var files := []
	var dir := DirAccess.open(scripts_folder)
	for string in dir.get_files():
		if string.contains(".gd"):
			command_list += string.substr( 0, string.length() - 3 ) + ", "
	return command_list

func set_console_text():
	$ScrollContainer/VBoxContainer/RichTextLabel.clear()
	for line in previous_commands:
		$ScrollContainer/VBoxContainer/RichTextLabel.text += line + "\n"

func append_console_text():
	var line = previous_commands[previous_commands.size() - 1]
	$ScrollContainer/VBoxContainer/RichTextLabel.text += line + "\n"

func _input(event):
	if event.is_action_pressed("open_debug_console"):
		if not showing:
			show_console()
			showing = true
		else:
			hide_console()
			showing = false
	if not showing:
		return
	if event.is_action_pressed("ui_down"):
		if history_index == -1 or history_index >= history.size():
			return
		history_index += 1
		if history_index == history.size():
			$TextEdit.clear()
			history_index = -1
		else:
			$TextEdit.text = history[history_index]
	if event.is_action_pressed("ui_up"):
		if history_index == -1 and history.size() > 0:
			history_index = history.size()
			history_index -= 1
			$TextEdit.text = history[history_index]
		elif history_index > 0:
			history_index -= 1
			$TextEdit.text = history[history_index]

func _on_text_edit_text_changed():
	var text = $TextEdit.text
	if text.length() > 0 and text[text.length() - 1] == "\n" :
		deploy_command(text.substr(0,text.length()-1))
		$TextEdit.clear()
		history_index = -1
	elif text.length() > 0 and text[text.length() - 1] == "~":
		history_index = -1
		hide_console()
		$TextEdit.clear()
