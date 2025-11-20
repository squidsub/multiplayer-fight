extends CharacterBody2D

# RedGuy Movement parameters
@export var speed: float = 100.0
@export var run_speed: float = 225.0
@export var jump_velocity: float = -350.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var climb_speed: float = 60.0

# RedGuy Health
@export var max_health: int = 100
var health: int = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var name_label: Label = null

# Ladder variables
var is_climbing: bool = false
var can_climb: bool = false
var ladder_tilemap: TileMapLayer = null

# Combat variables
var is_punching: bool = false

func _enter_tree():
	print("   → RedGuy _enter_tree: Authority is ", get_multiplayer_authority())

func _ready():
	var my_id = multiplayer.get_unique_id()
	var my_authority = get_multiplayer_authority()
	var is_auth = is_multiplayer_authority()
	
	print("   → RedGuy _ready: name=", name, " | my_peer_id=", my_id, " | node_authority=", my_authority, " | is_authority=", is_auth)
	
	call_deferred("find_ladder_tilemap")
	set_physics_process(true)
	
	# Set default animation
	animated_sprite.play("idle")
	print("   → RedGuy _ready: Animation set to idle")
	
	# Only enable camera for the player we control
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.enabled = is_auth
		print("   → RedGuy _ready: Camera enabled=", camera.enabled, " for is_authority=", is_auth)
	else:
		print("   → RedGuy _ready: Camera NOT FOUND!")
	
	# Create name label
	create_name_label()
	
	# Request our name from the network manager
	call_deferred("request_player_name")
	
	# Debug: print world info
	var root = get_tree().current_scene
	print("   → RedGuy _ready: Scene root is: ", root.name if root else "NULL")

func request_player_name():
	# Get the NetworkManager and request this player's name
	var network_manager = get_node_or_null("/root/GameLauncher/NetworkManager")
	if network_manager and network_manager.has("player_names"):
		var player_id = int(name)  # Our node name is the player ID
		if network_manager.player_names.has(player_id):
			var player_name = network_manager.player_names[player_id]
			set_player_name(player_name)
			print("   → RedGuy requested name: ", player_name)


func find_ladder_tilemap():
	# Search for all TileMapLayer nodes in the scene
	var root = get_tree().current_scene
	if root:
		find_tilemap_recursive(root)

func find_tilemap_recursive(node: Node):
	# Check all TileMapLayer nodes
	if node is TileMapLayer:
		# Check if this tilemap has children that are also TileMapLayer
		for child in node.get_children():
			if child is TileMapLayer:
				# This is the ladder layer (nested tilemap)
				ladder_tilemap = child
				return
	
	# Recursively search children
	for child in node.get_children():
		find_tilemap_recursive(child)

func check_ladder_collision():
	if not ladder_tilemap:
		can_climb = false
		return
	
	# Get the player's position in tilemap coordinates
	var tile_pos = ladder_tilemap.local_to_map(global_position)
	
	# Check if there's a ladder tile at this position
	var tile_data = ladder_tilemap.get_cell_atlas_coords(tile_pos)
	
	# Ladder is at atlas coords (0, 1)
	# Check if the tile exists (get_cell_atlas_coords returns Vector2i(-1, -1) if no tile)
	if tile_data != Vector2i(-1, -1) and tile_data == Vector2i(0, 1):
		can_climb = true
	else:
		can_climb = false
		# Exit climbing mode if we move off the ladder
		if is_climbing:
			is_climbing = false

func _physics_process(delta):
	# Only process input for the local player (the one we control)
	if not is_multiplayer_authority():
		return
	
	# Handle punch input
	if Input.is_key_pressed(KEY_F) and not is_punching and not is_climbing:
		punch()
	
	# Check if we're on a ladder tile
	check_ladder_collision()
	
	# Enter climbing mode if on ladder and pressing W
	if can_climb and Input.is_key_pressed(KEY_W) and not is_climbing:
		is_climbing = true
		velocity.y = 0  # Stop any falling momentum
	
	# Handle ladder climbing
	if is_climbing:
		# Disable gravity on ladder
		velocity.y = 0
		
		# Vertical movement on ladder
		if Input.is_key_pressed(KEY_W):
			velocity.y = -climb_speed
		elif Input.is_key_pressed(KEY_S):
			velocity.y = climb_speed
		
		# Horizontal movement on ladder (can still move left/right to exit)
		var direction = 0
		if Input.is_key_pressed(KEY_A):
			direction = -1
		elif Input.is_key_pressed(KEY_D):
			direction = 1
		
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
		
		# Update animations for climbing
		update_animation_climbing(velocity.y != 0)
		
		# Exit climbing if we move off the ladder or press Space to jump off
		if not can_climb or Input.is_key_pressed(KEY_SPACE):
			is_climbing = false
		
	else:
		# Normal movement (not on ladder)
		# Add gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Handle jump (W key or Space) - but not if we're about to climb
		if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE)) and is_on_floor() and not can_climb:
			velocity.y = jump_velocity
		elif Input.is_key_pressed(KEY_SPACE) and is_on_floor() and can_climb:
			# Allow jumping even when near ladder if Space is pressed
			velocity.y = jump_velocity
		
		# Get input direction (A and D keys)
		var direction = 0
		if Input.is_key_pressed(KEY_A):
			direction = -1
		elif Input.is_key_pressed(KEY_D):
			direction = 1
		
		# Check if shift is pressed for running
		var is_running = Input.is_key_pressed(KEY_SHIFT)
		var current_speed = run_speed if is_running else speed
		
		# If punching, move at 1/3 speed
		if is_punching:
			current_speed = speed / 3.0
		
		# Apply horizontal movement with acceleration/friction
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
		
		# Update animations (but keep punch animation if punching)
		if is_punching:
			update_animation_punching(direction)
		else:
			update_animation(direction, is_running)
	
	# Move the character
	move_and_slide()
	
	# Sync position to other clients
	if is_multiplayer_authority():
		sync_state.rpc(position, velocity, animated_sprite.animation, animated_sprite.flip_h)

func update_animation(direction, is_running):
	# Flip sprite based on direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play appropriate animation
	if is_on_floor():
		if direction != 0:
			# Use run animation when sprinting, walk otherwise
			if is_running:
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
			animated_sprite.speed_scale = 1.0
		else:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0
	else:
		# Play jump animation when in the air
		if animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
		animated_sprite.speed_scale = 1.0

func update_animation_climbing(is_moving: bool):
	# Play climb animation
	if animated_sprite.sprite_frames.has_animation("climb"):
		animated_sprite.play("climb")
		# Pause animation if not moving
		if is_moving:
			animated_sprite.speed_scale = 1.0
		else:
			animated_sprite.speed_scale = 0.0

func punch():
	is_punching = true
	
	# Play punch animation if it exists
	if animated_sprite.sprite_frames.has_animation("punch"):
		# Get the punch animation and check if it's looping
		var sprite_frames = animated_sprite.sprite_frames
		var was_looping = sprite_frames.get_animation_loop("punch")
		
		# Temporarily disable looping for punch
		sprite_frames.set_animation_loop("punch", false)
		
		animated_sprite.play("punch")
		# Wait for animation to finish
		await animated_sprite.animation_finished
		
		# Restore original loop setting
		sprite_frames.set_animation_loop("punch", was_looping)
	else:
		# If no punch animation, just wait a short time
		await get_tree().create_timer(0.4).timeout
	
	is_punching = false

func update_animation_punching(direction):
	# Flip sprite based on direction while punching
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Make sure punch animation is playing (but don't restart it)
	if animated_sprite.sprite_frames.has_animation("punch"):
		if animated_sprite.animation != "punch" or not animated_sprite.is_playing():
			animated_sprite.play("punch")

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		health = 0
		die()

func die():
	# Handle death - reset health for now
	health = max_health

# Sync player state to all other clients
@rpc("any_peer", "unreliable")
func sync_state(new_pos: Vector2, new_vel: Vector2, anim: String, flip: bool):
	# Don't update if this is the local player (we control it)
	if is_multiplayer_authority():
		return
	
	# Update position and velocity
	position = new_pos
	velocity = new_vel
	
	# Update animation
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
	animated_sprite.flip_h = flip

func create_name_label():
	# Create a label to show player name
	name_label = Label.new()
	name_label.text = "Player"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-50, -45)  # Above player's head, better positioned
	name_label.custom_minimum_size = Vector2(100, 20)  # Give it width for centering
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.z_index = 100
	add_child(name_label)

func set_player_name(player_name: String):
	# Create label if it doesn't exist yet
	if not name_label:
		create_name_label()
	
	if name_label:
		name_label.text = player_name
		print("   → Set player name label to: ", player_name)
	else:
		print("   → ERROR: Could not create name label!")
