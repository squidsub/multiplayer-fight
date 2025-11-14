extends Node

# This script handles the game launch logic
# Supports browser, desktop, and dedicated server deployment

@export var server_address: String = "localhost"  # Default server IP for clients
@export var is_server: bool = false  # Set to true for the dedicated server

var network_manager: Node
var is_web: bool = false

func _ready():
	# Detect if running in browser
	is_web = OS.has_feature("web")
	
	# In browser, never run as server (always client)
	if is_web:
		is_server = false
		# Try to get server address from URL parameters
		if OS.has_feature("web"):
			var url_params = get_url_params()
			if url_params.has("server"):
				server_address = url_params["server"]
	
	# Parse command-line arguments (for dedicated server)
	if not is_web:
		var args = OS.get_cmdline_args()
		var cmd_is_server = false
		var cmd_server_address = server_address
		
		for arg in args:
			if arg == "--server" or arg == "-s":
				cmd_is_server = true
				print("🖥️ SERVER MODE: Enabled via command-line")
			elif arg.begins_with("--address="):
				cmd_server_address = arg.replace("--address=", "")
				print("🌐 SERVER ADDRESS: ", cmd_server_address)
			elif arg.begins_with("-a="):
				cmd_server_address = arg.replace("-a=", "")
				print("🌐 SERVER ADDRESS: ", cmd_server_address)
		
		# Command-line args override exported variables
		if cmd_is_server:
			is_server = true
		if cmd_server_address != server_address:
			server_address = cmd_server_address
	
	# Load config file if it exists (for easy server address configuration)
	load_config()
	
	# Create network manager
	network_manager = load("res://Scripts/network_manager.gd").new()
	network_manager.name = "NetworkManager"
	add_child(network_manager)
	
	# Small delay to ensure everything is loaded
	await get_tree().create_timer(0.5).timeout
	
	if is_server:
		start_as_server()
	else:
		start_as_client()

func get_url_params() -> Dictionary:
	var params = {}
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("window.location.search", true)
		if url and url.length() > 1:
			url = url.substr(1)  # Remove '?'
			for param in url.split("&"):
				var kv = param.split("=")
				if kv.size() == 2:
					params[kv[0]] = kv[1]
	return params

func load_config():
	# For web builds, config is embedded or passed via URL
	if is_web:
		return
	
	# Try to load server_config.txt for easy configuration
	var config_path = "user://server_config.txt"
	
	# Also check next to executable
	if not FileAccess.file_exists(config_path):
		config_path = "res://server_config.txt"
	
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var content = file.get_as_text().strip_edges()
			if content.length() > 0 and not content.begins_with("#"):
				server_address = content
				print("📄 Loaded server address from config: ", server_address)
			file.close()

func start_as_server():
	print("🚀 Starting as DEDICATED SERVER")
	network_manager.start_server()

func start_as_client():
	print("🎮 Starting as CLIENT - Connecting to: ", server_address)
	network_manager.join_server(server_address)
