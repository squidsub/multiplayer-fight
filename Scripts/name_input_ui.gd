extends Control

signal name_submitted(player_name: String)

@onready var name_input: LineEdit = $Panel/VBoxContainer/NameInput
@onready var start_button: Button = $Panel/VBoxContainer/StartButton

func _ready():
	# Center the panel
	$Panel.position = Vector2(
		get_viewport_rect().size.x / 2 - $Panel.size.x / 2,
		get_viewport_rect().size.y / 2 - $Panel.size.y / 2
	)
	
	# Connect signals
	start_button.pressed.connect(_on_start_button_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	
	# Focus the input field
	name_input.grab_focus()
	
	# Set max length
	name_input.max_length = 15

func _on_start_button_pressed():
	_submit_name()

func _on_name_submitted(_text: String):
	_submit_name()

func _submit_name():
	var player_name = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Player"
	
	# Emit signal with the name
	name_submitted.emit(player_name)
	
	# Hide this UI
	queue_free()

