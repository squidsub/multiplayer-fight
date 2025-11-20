extends Node

const PORT = 7777
const MAX_PLAYERS = 100

var red_team_players: Array = []
var blue_team_players: Array = []

var red_guy_scene = preload("res://Scenes/RedGuy.tscn")
var blue_guy_scene = preload("res://Scenes/BlueGuy.tscn")

var red_spawn_position: Vector2
var blue_spawn_position: Vector2
var world: Node2D
var players_container: Node2D
var multiplayer_spawner: MultiplayerSpawner

# Player names
var local_player_name: String = "Player"
var player_names: Dictionary = {}  # peer_id -> name

func _ready():
	world = get_tree().current_scene
	players_container = world.get_node("Players")
	multiplayer_spawner = world.get_node("MultiplayerSpawner")
	find_spawn_markers()

func find_spawn_markers():
	var red_marker = world.get_node_or_null("RedPlayerSpawn")
	var blue_marker = world.get_node_or_null("BluePlayerSpawn")
	
	if red_marker:
		red_spawn_position = red_marker.global_position
	else:
		red_spawn_position = Vector2(300, 350)
	
	if blue_marker:
		blue_spawn_position = blue_marker.global_position
	else:
		blue_spawn_position = Vector2(500, 350)

func start_server():
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	
	var error = peer.create_server(PORT)
	if error != OK:
		push_error("Failed to start server: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	print("Server started on port ", PORT)

func join_server(address: String):
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	
	var ws_url = ""
	if OS.has_feature("web"):
		ws_url = "wss://" + address
		print("🌐 Browser - Connecting to: " + ws_url)
	else:
		ws_url = "ws://" + address + ":" + str(PORT)
		print("🖥️ Desktop - Connecting to: " + ws_url)
	
	var error = peer.create_client(ws_url)
	if error != OK:
		push_error("❌ Failed to connect: " + str(error))
		return
	
	print("✅ WebSocket client created, connecting...")
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_player_connected(id: int):
	print("🔌 Player connected: ID ", id)
	# Don't spawn yet - wait for player to send their name first
	print("   → Waiting for player name...")

func _on_player_disconnected(id: int):
	red_team_players.erase(id)
	blue_team_players.erase(id)
	
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()

func _on_connected_to_server():
	print("✅ Connected to server!")
	# Send our name to the server
	register_player_name.rpc_id(1, multiplayer.get_unique_id(), local_player_name)

func _on_connection_failed():
	push_error("❌ Connection to server failed!")

func assign_team() -> String:
	if red_team_players.size() <= blue_team_players.size():
		return "red"
	else:
		return "blue"

@rpc("any_peer", "call_local", "reliable")
func register_player_name(id: int, player_name: String):
	print("📝 Received name for player ", id, ": ", player_name)
	player_names[id] = player_name
	
	# If we're the server, spawn the player now
	if multiplayer.is_server():
		var team = assign_team()
		print("   → Assigned to team: ", team)
		spawn_player.rpc(id, team, player_name)
		print("   → RPC spawn_player sent to all clients")

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int, team: String, player_name: String):
	print("   → spawn_player RPC received for ID: ", id, " Team: ", team, " Name: ", player_name)
	player_names[id] = player_name
	
	var player_scene: PackedScene
	var spawn_pos: Vector2
	
	if team == "red":
		player_scene = red_guy_scene
		spawn_pos = red_spawn_position
		if multiplayer.is_server():
			red_team_players.append(id)
		print("   → Creating RED player")
	else:
		player_scene = blue_guy_scene
		spawn_pos = blue_spawn_position
		if multiplayer.is_server():
			blue_team_players.append(id)
		print("   → Creating BLUE player")
	
	# Instantiate the player
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = spawn_pos
	
	# Set authority - this will work on all clients
	player.set_multiplayer_authority(id)
	print("   → Set authority to ", id, " | My peer ID: ", multiplayer.get_unique_id())
	
	# Add to Players container
	players_container.add_child(player)
	print("   → Player added at: ", spawn_pos)
	print("   → Authority check: ", player.get_multiplayer_authority(), " | is_authority: ", player.is_multiplayer_authority())
	
	# Set player name label - use call_deferred to ensure _ready() has been called first
	if player.has_method("set_player_name"):
		player.call_deferred("set_player_name", player_name)
		print("   → Name will be set to: ", player_name)
