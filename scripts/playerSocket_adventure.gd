extends Node
# What is thrall and socket model?
# Thrall means something controlled, but is also Warchief of the Horde.
# A socket plugs into a thrall and controls it. Player or AI
# Thralls take same inputs, attack, desired move direction, etc
# Easily swap socket type, ex player switch to another character
# or someone comes over the network and controlls something
# Made by KaletheQuick

@export var thrall : CharacterBody3D # the thing to be controlled 
@export var player_prefix = "p1_" # used for local multiplayer

@export var enemies : Array[Actor]
# var locked_target : Actor

var primary_thrall = true

@export var mainCam : Camera3D 
@export var ganty_thing : Node3D
@export var vignette : Control
@export var title_card : Control



var dot : Node3D # debug

# Input checks for dodge vs sprint
# Soulslike = Dodge and sprint are same button. Tap or hold for difference
var dodge_sprint_threshold = 0.2
var ds_timer = 0.0

# variables for z targeting
var look_lock = false

@export var target_locker : PackedScene

@export var headsUpDisplay : Control

# Signal for when a player attacks
signal signal_attack(action : String)

signal broadcast_action(packet : PackedByteArray)

signal broadcast_movement(packet : PackedByteArray)

signal broadcast_target(packet : PackedByteArray)

# acreas and interactable things

func _ready():
	dobox(Vector3i(2,3,5))
	pass # Replace with function body.
	
	dot = target_locker.instantiate()
	get_tree().root.add_child.call_deferred(dot)
	dot.name = "~dot~"


	# Test maping for linux SDL PowerA controller, 
	# I've had a lot of problems with them, all 
	# kernel mappings and other applications work,
	# But not Godot :< 
	# The mapping that is recognised:
	#var mapstring = "03000000d62000000240000001010000,PowerA Xbox One Spectra Infinity,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux,"
	# Modified mapping for new GUID:
	var mapstrings = [
		"03000000d62000003220000001010000,PowerA Xbox One Spectra Infinity White,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux,",
		"050000004d59475420436f6e74726f00,MYGT Bluetooth,a:b0,b:b1,back:b10,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b6,leftstick:b13,lefttrigger:a5,leftx:a0,lefty:a1,rightshoulder:b7,rightstick:b14,righttrigger:a4,rightx:a2,righty:a3,start:b11,x:b3,y:b4,platform:Linux,"
	]
	for mapstring in mapstrings:
		Input.add_joy_mapping(mapstring, true)
	# Test to see if mapping works
#	for x in Input.get_connected_joypads():
#		print("Controller: %s\n%s\nInfo:\n%s" % [Input.get_joy_name(x), Input.get_joy_guid(x), Input.get_joy_info(x)])


# Called every frame. 'delta' is the elapsed time since the previous frame.
@export var deb_action = ""
@export var deb_act = false
func _process(_delta):
	if thrall == null:
		return
	if deb_act:
		deb_act = false
		if deb_action != "":
			thrall.action_q.append(deb_action)
			#deb_action = ""
	#print(delta)
	find_interactable_objects()

	# NOTE - Demo purposes only

func _physics_process(delta: float) -> void:
	if thrall == null:
		return
	_collect_inputs(delta)

func create_action_pack(action: String):
	# Todo, consider a safety check for acceptable actions
	# custom_packet:
	# id, time, action. Separated by semi-colons.
	var id = multiplayer.get_unique_id()
	var t1 = Time.get_unix_time_from_system()
	# if thrall controlled by host player, then the packet data go to other players.
	if multiplayer.is_server():
		var action_data = {"PEER": id, "TIME1": t1, "TIME2": t1, "ACTION": action}
		var packet = var_to_bytes(action_data)
		broadcast_action.emit(packet)
	# otherwise, send data to server.
	else:
		var action_data = {"PEER": id, "TIME": t1, "ACTION": action}
		var packet = var_to_bytes(action_data)
		send_action_packet_to_server(packet)

func create_movement_pack(desired_movement : Vector3, target : CharacterBody3D = null):
	# TODO: get the calculation for desired_turn from the _get_inputs function.
	var calculate_turn_transform = null
	if thrall.lock_targ != null:
		calculate_turn_transform = Vector2(( thrall.global_basis.inverse() * (thrall.global_position - thrall.lock_targ.global_position).normalized()).x,-( thrall.global_basis.inverse() * -desired_movement).z)
	else:
		calculate_turn_transform = Vector2(( thrall.global_basis.inverse() * -desired_movement).x,-( thrall.global_basis.inverse() * -desired_movement).z)
	var id = multiplayer.get_unique_id()
	var movement_data = {"PEER": id, "MOVEMENT": desired_movement, "ROTATE": calculate_turn_transform}
	var packet = var_to_bytes(movement_data)
	if multiplayer.is_server():
		broadcast_movement.emit(packet)
	else:
		rpc_id(1, "recieve_movement_packet", packet)

func create_lock_pack(entity : StringName):
	if entity.is_empty():
		return
	var id = multiplayer.get_unique_id()
	var target_data = {"PEER": id, "TARGET": entity}
	var packet = var_to_bytes(target_data)
	if multiplayer.is_server():
		broadcast_target.emit(packet)
	else:
		rpc_id(1, "recieve_target_packet", packet)

# Server only function
@rpc("unreliable", "any_peer")
func recieve_movement_packet(p : PackedByteArray):
	broadcast_movement.emit(p)

@rpc("unreliable", "any_peer")
func recieve_target_packet(p : PackedByteArray):
	broadcast_target.emit(p)

@rpc("unreliable", "authority")
func client_action(packet: PackedByteArray):
	var message = bytes_to_var(packet)
	PeerGlobal.log_message("client_action(packet : PackedByteArray) --\npacket PackedByteArray:     " + str(packet) + "\nDecoded Message Dictionary: " + str(message))
	var multiplayer_manager = get_parent().get_parent().get_node("Multplayer Manager")
	var peer_nodes = multiplayer_manager.get_children()
	for peer in peer_nodes:
		if str(message['PEER']) == peer.name:
			peer.enque_action(message['ACTION'])
			return
	print("pt_map entry " + str(message['PEER']) + " does not exist.")
	pass

@rpc("unreliable", "authority")
func client_movement(p : PackedByteArray):
	var message : Dictionary = bytes_to_var(p)
	var mm = get_parent().get_parent().get_node("Multplayer Manager")
	var peer_nodes = mm.get_children()
	#PeerGlobal.log_message("message: " + str(message))
	for peer in peer_nodes:
		if str(message['PEER']) == peer.name:
			peer.handle_movement(message['MOVEMENT'])
			peer.desired_turn = message['ROTATE'].x

@rpc("unreliable", "authority")
func client_target(p : PackedByteArray):
	var message : Dictionary = bytes_to_var(p)
	var mm = get_parent().get_parent().get_node("Multplayer Manager")
	var peer_nodes = mm.get_children()
	for peer in peer_nodes:
		if str(message['PEER']) == peer.name:
			print(str(message))
			var enemies_list = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies_list:
				if enemy.name == message['TARGET']:
					peer.lock_targ = enemy
					peer.combat_mode = true
					peer.combat_relax_timer = 3.0
					return
			peer.lock_targ = null
			peer.combat_mode = false
			peer.combat_relax_timer = 0

@rpc("unreliable", "any_peer")
func recieve_action_message(packet: PackedByteArray):
	# TODO: Consider sanity checks here
	var message = bytes_to_var(packet)
	print("recieve_action_message(packet : PackedByteArray)")
	print("packet PackedByteArray:        " + str(packet) )
	print("message Dictionary:            " + str(message))
	var t1 = message["TIME"]
	var t2 = Time.get_unix_time_from_system()
	var id = message["PEER"]
	var act = message["ACTION"]
	var bounce_message = {"PEER": id, "TIME1": t1, "TIME2": t2, "ACTION": act}
	var bounce_packet = var_to_bytes(bounce_message)
	print("bounce_message Dictionary:     " + str(bounce_message))
	print("bounce_packet PackedByteArray: " + str(bounce_packet) )
	broadcast_action.emit(bounce_packet)

#rpc are from client -> server -> client
@rpc("unreliable")
func send_action_packet_to_server(packet: PackedByteArray):
	print("send_action_packet_to_server") 
	print("packet PackedByteArray " + str(packet))
	rpc_id(1, "recieve_action_message", packet)

func _collect_inputs(delta):
	# pass 
	# TODO - Collect player input
	# 2    - Change to relevant stuff
	# 3    - Pass forward desired inputs to thrall 

	var input_dir = Input.get_vector(player_prefix + "move_left", player_prefix + "move_right", player_prefix + "move_dn", player_prefix + "move_up")
	# Figuring out relative movement
	var mv_z = -mainCam.global_transform.basis.z
	mv_z.y = 0
	mv_z = mv_z.normalized()
	mv_z = mv_z * input_dir.y
	var mv_x = mainCam.global_transform.basis.x
	mv_x.y = 0
	mv_x = mv_x.normalized()
	mv_x = mv_x * input_dir.x
	var go_dir : Vector3 = (mv_x + mv_z)
	
	go_dir.y = Input.get_axis(player_prefix + "crouch", player_prefix + "jump")
	
	# SECTION - Dodge and sprinting
	if Input.is_action_just_released(player_prefix + "dodge"):
		if ds_timer <= dodge_sprint_threshold:
			print(str(multiplayer.get_unique_id()) + " dodge!")
	if Input.is_action_pressed(player_prefix + "dodge"):
		ds_timer += delta
		if ds_timer > dodge_sprint_threshold:
			thrall.sprint = true
			#thrall.dodge = true
	elif Input.is_action_just_released(player_prefix + "dodge") && ds_timer < dodge_sprint_threshold:
		create_action_pack("dodge")
		thrall.enque_action("dodge")
#		thrall.dodge = true
	else:
		thrall.sprint = false
		thrall.dodge = false
		ds_timer = 0

	
	if Input.is_action_just_released(player_prefix + "use_item"):
		create_action_pack("spell")
		thrall.enque_action("spell")
	
	# Tell the world your intended move
	create_movement_pack(go_dir)
	thrall.handle_movement(go_dir)
	if Input.is_action_pressed(player_prefix + "event_action"): 
		# NOTE - In ER holding ^ this would bring up a quick item D-pad menu, and also do hand switching. 
		# So this area could be refactored to more smoothly do that.
		input_hand_switching()
	else:
		if Input.get_action_strength("p1_block") > 0.5:
			if is_instance_valid(thrall.l_wep) && is_instance_valid(thrall.r_wep):
				create_action_pack("attack_power")
				thrall.enque_action("attack_power")
			else:
				create_action_pack("block")
				thrall.enque_action("block")
				if Input.is_action_just_released(player_prefix + "item_right_next"):
					create_action_pack("block")
					thrall.enque_action("blocked_attack")
		if Input.get_action_strength("p1_attack_light") > 0.5:
			create_action_pack("attack_light")
			thrall.enque_action("attack_light")
			# Signal that player attacks
			var action = "attack_light"
			signal_attack.emit(action)
		if Input.get_action_strength("p1_attack_heavy") > 0.5:
			create_action_pack("attack_heavy")
			thrall.enque_action("attack_heavy")
			# Signal that player attacks
			var action = "attack_heavy"
			signal_attack.emit(action)
		if Input.get_action_strength("p1_parry") > 0.5:
			create_action_pack("attack_art")
			thrall.enque_action("attack_art")
		# Black Box Unit Test
		# Tests for users performing action while dead.
		# On input of light attack or heavy attack, if the
		# user is dead then the error message will be printed.
		if Input.get_action_strength("p1_attack_light") > 0.5 or Input.get_action_strength("p1_attack_heavy") > 0.5:
			print("Performed attack action")
		if(Input.get_action_strength("p1_attack_light") > 0.5 or Input.get_action_strength("p1_attack_heavy") > 0.5) and thrall.character.health_current <= 0:
			assert(thrall.character.health_current != null)
			print("Cannot perform action, you are dead.")
	
	
	dot.global_position = thrall.global_position + go_dir

	# SECTION - Camera and lock on stuff
	if Input.is_action_just_pressed(player_prefix + "look_lock"):
		var potential_enemies = get_tree().get_nodes_in_group("enemies")
		enemies.clear()
		for enemy in potential_enemies:
			if enemy is Actor:
				enemies.append(enemy)
		look_lock = !look_lock
		if look_lock:
			print("look lock")
			# FIXME - thrall logic in socket
			thrall.combat_mode = true
			thrall.combat_relax_timer = 3.0
			# Find target closest to center forward of screen.
			var winner = null
			var win_dot = 10.0
			for enemy in enemies:
				# easy out checks 
				if enemy.alive == false:
					continue
				if thrall.global_position.distance_to(enemy.global_position) > 20:
					continue
				# cull front half of camera? wait, vector math? here?
				var my_dot = mainCam.global_basis.z.dot((enemy.global_position - mainCam.global_position).normalized())
				if my_dot < win_dot:
					winner = enemy
					win_dot = my_dot
			if winner != null:
				thrall.lock_targ = winner
				create_lock_pack(winner.name)
			else:
				thrall.lock_targ = null
				look_lock = false
				ganty_thing.look_at(thrall.global_position + (thrall.global_basis.z * 50))

		else:
			print("look unlock")
			create_lock_pack("")

	if look_lock:
		if thrall.lock_targ.alive == false:
			look_lock = false
			thrall.lock_targ = null
		else:
			mainCam.target_curr = thrall.lock_targ.global_position + Vector3(0,2,0)
			dot.global_position = thrall.lock_targ.global_position + Vector3(0,2,0)
			dot.visible = true
			
			dot.look_at(mainCam.global_position)
			dot.get_node("TargetReticle").rotate_z(delta) 
			dot.scale = Vector3.ONE + (Vector3.ONE * ((1 + (sin(Time.get_unix_time_from_system() * 12)*0.5))) * 0.5 )

			#TODO - put this look vector somewhere else? idk
			var transformed_move_dir =  Vector2(( thrall.global_basis.inverse() * (thrall.global_position - thrall.lock_targ.global_position).normalized()).x,-( thrall.global_basis.inverse() * -go_dir).z)
			thrall.desired_turn = transformed_move_dir.x
			thrall.lock_targ_pos = thrall.lock_targ.global_position
			#print(transformed_move_dir.x)
	else:
		dot.visible = false
		mainCam.target_curr = Vector3.ZERO
		#TODO - put this look vector somewhere else? idk
		var transformed_move_dir =  Vector2(( thrall.global_basis.inverse() * -go_dir).x,-( thrall.global_basis.inverse() * -go_dir).z)
		thrall.desired_turn = transformed_move_dir.x
		thrall.lock_targ_pos = Vector3.ZERO
		thrall.lock_targ = null
		create_lock_pack("")
		

@export var action_prompt : Control
func find_interactable_objects():
	pass 
	# TODO - Sphere cast or ray cast for items. 
	# TODO - Reevaluate object interaction for more generic use

	# Phys ray
	var space_state = thrall.get_world_3d().direct_space_state
	var origin = thrall.global_position + Vector3.UP
	var end = origin + (thrall.global_basis.z * 2)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var col_result = space_state.intersect_ray(query)

	#Phys Sphere
	var sphere = SphereShape3D.new()
	sphere.radius = 2
	var q_shape = PhysicsShapeQueryParameters3D.new()
	q_shape.shape = sphere
	q_shape.transform.origin = thrall.global_position + Vector3(0,1,0)
	q_shape.collide_with_areas = true
	q_shape.collide_with_bodies = false
	col_result = space_state.intersect_shape(q_shape)

	#if is_instance_valid(col_result):
	#print(col_result.size())
	for result in col_result:
		if "collider" in result.keys():
			if result["collider"] is Harvestable:
				var crop = result["collider"] as Harvestable
				if crop.collected == true:
					continue
				action_prompt.show_prompt(crop.harvest_name)
				if Input.is_action_just_pressed(player_prefix + "event_action") and crop.collected == false:
					crop.my_pickup_logic()
					thrall.item_get.emit("fruit")
				return
			else:
				action_prompt.hide_prompt()
	return




func dobox(box : Vector3i):
	for x in range(box.x):
		for y in range(box.y):
			for z in range(box.z):
				#print("pos:(", x, ",", y, ",", z, ")")
				pass


func enthrall_new_thrall(new_thrall : Actor):
	thrall = new_thrall
	headsUpDisplay.inspect_new_thrall(thrall)


func input_hand_switching():
	if Input.is_action_just_pressed(player_prefix + "attack_light"):
		print("Toggle right hand")
		if thrall.hand_state == Actor.HandState.ONE_HAND:
			thrall.hand_state = Actor.HandState.TWO_HAND
		else:
			thrall.hand_state = Actor.HandState.ONE_HAND
	elif Input.is_action_just_pressed(player_prefix + "block"):
		thrall.hand_state = Actor.HandState.UNARMED # hack for a test
		print("Toggle left hand")
		
@rpc("reliable", "authority")
func update_ping():
	for peer in get_parent().get_parent().get_node("Multplayer Manager").get_children():
		rpc_id(int(peer.name), "report_delay")

@rpc("reliable", "authority")
func ping(t1, peer):
	var multiplayer_manager = get_parent().get_parent().get_node("Multplayer Manager")
	var peer_nodes = multiplayer_manager.get_children()
	for p in peer_nodes:
		if p.name == str(peer):
			var dt = Time.get_unix_time_from_system() - t1
			p.set_delay(dt) # set delay for peers on server

@rpc("reliable", "any_peer", "call_remote")
func report_delay():
	rpc_id(1, "ping", Time.get_unix_time_from_system(), multiplayer.get_unique_id())

func calculate_animation_offset(transit_time : float, animation_time_limit : float) -> float:
	var mm = get_parent().get_parent().get_node("Multplayer Manager")
	var tl : float
	var t3 = Time.get_unix_time_from_system()
	if transit_time < 0:
		# potential debouncing technique
		return -1 # don't play the animation
	else:
		# normal case
		tl = t3 - transit_time
	# If the connection is soooo slow then the animation should not play
	if tl >= animation_time_limit:
		mm.high_latency_removal.rpc_id(1, multiplayer.get_unique_id())
		return -1 # don't play the animation
	return tl
