extends Node

# Network settings
const PORT = 7777
const MAX_PLAYERS = 100

# Team tracking
var red_team_players: Array = []
var blue_team_players: Array = []

# Player scenes
var red_guy_scene = preload("res://Scenes/RedGuy.tscn")
var blue_guy_scene = preload("res://Scenes/BlueGuy.tscn")

# Spawn positions
var red_spawn_position: Vector2
var blue_spawn_position: Vector2

# Reference to world
var world: Node2D

# Track if we're running in browser
var is_web: bool = false

func _ready():
	# Detect if running in browser
	is_web = OS.has_feature("web")
	
	# Get world reference
	world = get_tree().current_scene
	
	# Find spawn markers
	find_spawn_markers()

func find_spawn_markers():
	# Look for markers named RedPlayerSpawn and BluePlayerSpawn
	var red_marker = world.get_node_or_null("RedPlayerSpawn")
	var blue_marker = world.get_node_or_null("BluePlayerSpawn")
	
	# Set spawn positions from markers or use defaults
	if red_marker:
		red_spawn_position = red_marker.global_position
	else:
		red_spawn_position = Vector2(300, 350)
	
	if blue_marker:
		blue_spawn_position = blue_marker.global_position
	else:
		blue_spawn_position = Vector2(500, 350)

func start_server():
	# WebSocket server for browser compatibility
	var peer = WebSocketMultiplayerPeer.new()
	
	# Set supported protocols before creating server
	peer.supported_protocols = ["ludus"]
	
	var error = peer.create_server(PORT)
	
	if error != OK:
		push_error("Failed to start WebSocket server: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Connect signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Spawn a player for the server itself (ID = 1)
	var team = assign_team()
	spawn_player(1, team)

func join_server(address: String):
	# Use WebSocket for browser compatibility
	var peer = WebSocketMultiplayerPeer.new()
	
	# Set supported protocols before connecting
	peer.supported_protocols = ["ludus"]
	
	# Format WebSocket URL
	var ws_url = "ws://" + address + ":" + str(PORT)
	
	# For web builds, check if we need wss:// (secure WebSocket)
	if is_web and address.contains("amazonaws.com"):
		ws_url = "wss://" + address + ":" + str(PORT)
	
	var error = peer.create_client(ws_url)
	
	if error != OK:
		push_error("Failed to connect to WebSocket server: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Connect signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_player_connected(id: int):
	# Assign team based on player count
	var team = assign_team()
	
	# Spawn player on server
	spawn_player(id, team)
	
	# Tell the client which team they're on
	rpc_id(id, "set_team", team)

func _on_player_disconnected(id: int):
	# Remove from team tracking
	red_team_players.erase(id)
	blue_team_players.erase(id)
	
	# Remove their player node
	var player = world.get_node_or_null(str(id))
	if player:
		player.queue_free()

func _on_connected_to_server():
	pass # Connected successfully

func _on_connection_failed():
	push_error("Failed to connect to server")

func assign_team() -> String:
	# Assign to team with fewer players
	if red_team_players.size() <= blue_team_players.size():
		return "red"
	else:
		return "blue"

@rpc("authority", "call_local")
func set_team(team: String):
	pass # Team assigned

func spawn_player(id: int, team: String):
	var player: CharacterBody2D
	var spawn_pos: Vector2
	
	# Create appropriate player based on team
	if team == "red":
		player = red_guy_scene.instantiate()
		spawn_pos = red_spawn_position
		red_team_players.append(id)
	else:
		player = blue_guy_scene.instantiate()
		spawn_pos = blue_spawn_position
		blue_team_players.append(id)
	
	# Set player properties
	player.name = str(id)
	player.position = spawn_pos
	
	# Set network authority
	player.set_multiplayer_authority(id)
	
	# Add to world
	world.add_child(player)
