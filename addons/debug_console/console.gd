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
extends PanelContainer

@export var width = 500
@export var height = 500
@export var text_size = 15
@export var text_color : Color = Color(0, 1, 0.1843137294054)
@export var console_color : Color = Color(0.19607843458652, 0.19607843458652, 0.19607843458652, 0.80392158031464)
@export var console_style_box := StyleBoxFlat.new()
@export var scripts_folder = "res://addons/debug_console/scripts/"
@export var reload = false

const MAX_SHOWN_LINES = 40
const MAX_HISTORY = 20

var showing = false
var anchored_bottom = false
var anchored_right = false
var previous_commands: Array = []
var history : Array = []
var history_index := -1
var console_commands = {
	"set" : set_property_command,
	"clear" : clear_command,
	"echo" : echo_command,
	"list" : list_command,
	"anchor" : anchor_command,
	"reset" : reset_command,
	"help" : help_command,
}
var help_text = {
	"set" : "sets a property for the console, valid properties are width, height, text (textsize), dimension, color, background. 
			Usage: set <property> <value1> <value2> ... ",
	"clear" : "clears command history. Usage: clear",
	"echo" : "repeats text back to you (mainly was used for debugging). Usage: echo <text>",
	"list" : "lists console commands and user scripts. Usage: list",
	"anchor" : "changes where the console is anchored. valid anchor locations are top_left (tl), top_right (tr), bottom_right, bottom_left
			Usage: anchor <anchor location> ",
	"reset" : "resets all properties in the console. Usage: reset",
	"help" : "displays help and usage for a command. Usage: help <commnad> ",
}


func _init():
	if not (EngineDebugger.is_active() || OS.is_debug_build()):
		queue_free()
	if not InputMap.has_action("open_debug_console"):
		InputMap.add_action("open_debug_console")
		var event := InputEventKey.new()
		event.keycode = KEY_F3
		InputMap.action_add_event("open_debug_console",event)

func _ready():
	hide()
	add_theme_stylebox_override("panel",console_style_box)
	console_style_box.bg_color = console_color
	set_properties()
	#failsafe
	#if not EngineDebugger.is_active():
	#	queue_free()

func _process(_delta):
	if Engine.is_editor_hint() and reload:
		set_properties()

func set_properties():
	size = Vector2(width,height)
	$VBoxContainer/ScrollContainer/RichTextLabel.add_theme_color_override("default_color",text_color)
	$VBoxContainer/ScrollContainer/RichTextLabel.add_theme_font_size_override("normal_font_size",text_size)

func show_console():
	$VBoxContainer/LineEdit.grab_focus()
	show()

func hide_console():
	$VBoxContainer/LineEdit.clear()
	history_index = -1
	hide()

func clear_commands():
	$VBoxContainer/ScrollContainer/RichTextLabel.clear()
	$VBoxContainer/ScrollContainer/RichTextLabel.text = ""
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

func fetch_history(index):
	$VBoxContainer/LineEdit.text = history[history_index]
	$VBoxContainer/LineEdit.caret_column = $VBoxContainer/LineEdit.text.length() - 1

func set_property_command(args : Array) -> String:
	if args.size() < 3:
		return "Usage: set <property> <value>"
	match args[1]:
		"text":
			text_size = float(args[2])
		"height":
			height = float(args[2])
			if anchored_bottom:
				position.y -= height - size.y
		"width":
			width = float(args[2])
			if anchored_right:
				position.x -= width - size.x 
		"dimension":
			if args.size() < 4:
				return "Usage: set dimension <width> <height>"
			width = float(args[2])
			height = float(args[3])
			if anchored_right:
				position.x -= width - size.x 
			if anchored_bottom:
				position.y -= height - size.y
			set_properties()
			return "set dimension to: " + args[2] +  ", " + args[3]
		"color":
			if args.size() < 5:
				return "Usage: set color <r> <g> <b>"
			text_color = Color(float(args[2]),float(args[3]),float(args[4]))
			set_properties()
			return "set color: " + args[2] + ", " + args[3] + ", " + args[4]
		"background":
			if args.size() < 5:
				return "Usage: set background <r> <g> <b> (<a>)"
			console_style_box.bg_color = Color(float(args[2]),float(args[3]),float(args[4]))
			if args.size() == 6 :
				console_style_box.bg_color.a = float(args[5])
			set_properties()
			return "set background: " + args[2] + ", " + args[3] + ", " + args[4]
		_:
			return "Invalid property: " + args[1] + ". valid properties: text, height, width"
	set_properties()
	return "set property: " + args[1] + " to: " + str(args[2])

func clear_command( _args ) -> String:
	clear_commands()
	return "cleared"

func echo_command(args) -> String:
	if args.size() < 2:
		return ""
	return args[1]

func list_command(_args) -> String:
	var command_list = ""
	for key in console_commands.keys():
		command_list += key + ", "
	var dir := DirAccess.open(scripts_folder)
	if dir == null:
		return command_list
	for string in dir.get_files():
		if string.contains(".gd"):
			command_list += string.substr( 0, string.length() - 3 ) + ", "
	
	return command_list.substr(0,command_list.length()-2)

func anchor_command(args):
	if args.size() == 1:
		return "Usage: anchor <ANCHOR LOCATION>"
	match args[1]:
		"tl":
			anchored_right = false
			anchored_bottom = false
			set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			set_properties()
			return "Anchored Top Left"
		"top_left":
			anchored_right = false
			anchored_bottom = false
			set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			set_properties()
			return "Anchored Top Left"
		"tr":
			anchored_right = true
			anchored_bottom = false
			set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			set_properties()
			position.x -= width - get_minimum_size().x
			return "Anchored Top Right"
		"top_right":
			anchored_right = true
			anchored_bottom = false
			set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			set_properties()
			position.x -= width - get_minimum_size().x
			return "Anchored Top Right"
		"bottom_left":
			anchored_right = false
			anchored_bottom = true
			set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			set_properties()
			position.y -= height - get_minimum_size().y
			return "Anchored Bottom left"
		"bottom_right":
			anchored_right = true
			anchored_bottom = true
			set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			set_properties()
			var dimension = Vector2(width,height)
			position -= dimension - get_minimum_size()
			return "Anchored Bottom right"
		_:
			return "invalid anchor location, use: center (c), top_left (tl), top_right (tr), bottom_left, bottom_right"

func reset_command(_args):
	width = 500
	height = 500
	text_size = 15
	var reset_anchor_args : Array = ["" , "tl"]
	anchor_command(reset_anchor_args)
	console_style_box.bg_color = Color(0.19607843458652, 0.19607843458652, 0.19607843458652, 0.80392158031464)
	text_color = Color(0, 1, 0.1843137294054)
	clear_commands()
	set_properties()
	return "Reset properties"

func help_command( args ):
	if args.size() < 2:
		return "Usage: help <command>"
	var command_to_help = args[1]
	if help_text.has(command_to_help):
		return help_text[command_to_help]
	var script_path = scripts_folder + command_to_help + ".gd"
	if ResourceLoader.exists(script_path):
		var command_script = load(script_path).new()
		return command_script.help()
	return "could not find command: " + command_to_help

func set_console_text():
	$VBoxContainer/ScrollContainer/RichTextLabel.clear()
	for line in previous_commands:
		$VBoxContainer/ScrollContainer/RichTextLabel.text += line + "\n"

func append_console_text():
	var line = previous_commands[previous_commands.size() - 1]
	$VBoxContainer/ScrollContainer/RichTextLabel.text += line + "\n"

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
			$VBoxContainer/LineEdit.clear()
			history_index = -1
			return
		fetch_history(history_index)
	if event.is_action_pressed("ui_up"):
		if history_index == -1 and history.size() > 0:
			history_index = history.size()
			history_index -= 1
			fetch_history(history_index)
		elif history_index > 0:
			history_index -= 1
			fetch_history(history_index)

func _on_line_edit_text_submitted(new_text):
	if new_text.length() == 0:
		return
	deploy_command(new_text)
	$VBoxContainer/LineEdit.clear()
	history_index = -1
