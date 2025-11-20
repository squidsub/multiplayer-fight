extends Node

@export var server_address: String = "localhost"
@export var is_server: bool = false

var network_manager: Node

func _ready():
	var is_web = OS.has_feature("web")
	print("🎮 Game Launcher Ready - is_web:", is_web)
	
	if is_web:
		is_server = false
		var url_params = get_url_params()
		if url_params.has("server"):
			server_address = url_params["server"]
	else:
		var args = OS.get_cmdline_args()
		for arg in args:
			if arg == "--server" or arg == "-s":
				is_server = true
			elif arg.begins_with("--address="):
				server_address = arg.replace("--address=", "")
	
	print("📡 Server Address:", server_address)
	print("🖥️ Is Server:", is_server)
	
	network_manager = load("res://Scripts/network_manager.gd").new()
	network_manager.name = "NetworkManager"
	add_child(network_manager)
	
	await get_tree().create_timer(0.5).timeout
	
	if is_server:
		print("🚀 Starting as SERVER")
		network_manager.start_server()
	else:
		print("🎯 Starting as CLIENT - Connecting to:", server_address)
		
		# Show name input UI for client
		var name_input_scene = load("res://Scenes/name_input_ui.tscn")
		var name_input_ui = name_input_scene.instantiate()
		get_tree().root.add_child(name_input_ui)
		
		# Wait for name submission
		var player_name = await name_input_ui.name_submitted
		print("👤 Player Name:", player_name)
		
		network_manager.local_player_name = player_name
		network_manager.join_server(server_address)

func get_url_params() -> Dictionary:
	var params = {}
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("window.location.search", true)
		if url and url.length() > 1:
			url = url.substr(1)
			for param in url.split("&"):
				var kv = param.split("=")
				if kv.size() == 2:
					params[kv[0]] = kv[1]
	return params
