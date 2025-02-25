extends Node

const SCRIPT_NAME : String = "Multiplayer_Manager.gd"

const PLAYER_SCENE = preload("res://prefabs/actor.tscn")
const PORT = 8080
var enet_peer = ENetMultiplayerPeer.new()
var nop= WebSocketMultiplayerPeer.new()

@export var server_menu : Control
@export var cam_gant : Node3D 
@export var cam_actu : Camera3D
@export var ip_input : LineEdit
@export var outfit_control : Control

var player_socket : Node

# player-thrall map: one-to-one mapping of player id to a thrall.
# Operationally, it is an array of dictionaries. Basically treating 
# this like an array of json entries.
@export var pt_map := Dictionary()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_socket = get_parent().get_node("Player Sockets/p1_psock_adventure")
	player_socket.connect("broadcast_action", Callable(self, "attempt_to_broadcast_client_actions_to_clients")
, 0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#get_ping.rpc_id()
	pass

func _on_butt_host_pressed() -> void:
	if OS.get_name() == "Web":
		PeerGlobal.log_message("Web build detected, quick, change everything about networking so it all breaks, quickly everyone!")
		_start_local_only()
	server_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)

	add_player(multiplayer.get_unique_id())
	server_menu.visible = false

func _on_butt_connect_pressed() -> void:
	var server_ip = ip_input.text
	# TODO Validate ip
	server_menu.hide()
	enet_peer.create_client(server_ip, PORT)
	multiplayer.multiplayer_peer = enet_peer
	server_menu.visible = false

func _start_local_only():	
	server_menu.hide()
	var new_player = PLAYER_SCENE.instantiate()
	#new_player.name = "Thrall Local Player"
	#add_child(new_player)
	PeerGlobal.log_message("New player: Local only")
	PeerGlobal.log_message("We is us!")
	get_parent().find_child("Player Sockets").find_child("p1_psock_adventure").enthrall_new_thrall(new_player)
	cam_gant.thrall = new_player
	cam_gant.cam.target_current = new_player
	cam_gant.freeze = false
	cam_gant.cam.freeze = false
	#new_player.visible = true
	#new_player.process_mode = Node.PROCESS_MODE_INHERIT
	PeerGlobal.log_message("Iz noed? " + str(new_player.find_child("DresserUpper")))
	outfit_control.dress_up_controller = new_player.find_child("DresserUpper")



func add_player(peer_id):
	var new_player = PLAYER_SCENE.instantiate()
	new_player.name = str(peer_id)
	add_child(new_player)
	#var peer_count = multiplayer.get_peers().size()
	pt_map[peer_id] = {"NODE": new_player, "NAME": new_player.name, "POSITION": new_player.position}
	PeerGlobal.log_message("New player: " + str(peer_id) + "; pt_map[" + str(peer_id) + "] = " + str(pt_map[peer_id]))
	new_player.set_multiplayer_authority(peer_id)
	if peer_id == multiplayer.get_unique_id():
		PeerGlobal.log_message("We is us!")
		get_parent().find_child("Player Sockets").find_child("p1_psock_adventure").enthrall_new_thrall(new_player)
		cam_gant.thrall = new_player
		cam_gant.cam.target_current = new_player
		cam_gant.freeze = false
		cam_gant.cam.freeze = false
		PeerGlobal.log_message("Iz noed? " + str(new_player.find_child("DresserUpper")))
		outfit_control.dress_up_controller = new_player.find_child("DresserUpper")
	else:
		PeerGlobal.log_message("interloper")

# Packets that account for the time it took to reach the server.
@rpc("unreliable", "any_peer")
func attempt_to_broadcast_client_actions_to_clients(packet: PackedByteArray):
	var message = bytes_to_var(packet)
	PeerGlobal.log_message("packet PackedByteArray: " + str(packet) )
	PeerGlobal.log_message("message Dictionary:     " + str(message))
	player_socket.rpc("client_action", packet, pt_map[message["PEER"]])
