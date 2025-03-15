extends GutTest

var actor # actor to test animations
var mtl # multiplayer test level

# function that instantiates the actor node.
func instantiate_player_actor_test():
	mtl = load("res://scenes/main_scene.tscn").instantiate()
	actor = load("res://prefabs/actor.tscn").instantiate()
	add_child(mtl)
	add_child(actor)

# deletes the actor node instance
func remove_actor():
	actor.queue_free()
	mtl.queue_free()
	actor = null
	mtl = null

# The following two white box tests stress test the calculate_animation_offset
# function which is responsible for determining when to start the animation of 
# the actor.

#func calculate_animation_offset(transit_time : float, animation_time_limit : float) -> float:
#	var mm = get_parent().get_parent().get_node("Multplayer Manager")
#	var tl : float
#	var t3 = Time.get_unix_time_from_system()
#	if transit_time < 0:
#		# potential debouncing technique
#		return -1 # don't play the animation
#	else:
#		# normal case
#		tl = t3 - transit_time
#	# If the connection is soooo slow then the animation should not play
#	if tl >= animation_time_limit:
#		# in fact, that connection should be removed.
#		mm.high_latency_removal.rpc_id(1, multiplayer.get_unique_id())
#		return -1 # don't play the animation
#	return tl

# White box test
# This test checks that the branch which handles successful rollback calculation is working
func test_rollback_calculation_produces_a_number_greater_than_zero():
	var mm = null
	# Assert 1: Assert that the normal case should be greater than or equal to 0 
	instantiate_player_actor_test()
	var ps = mtl.get_node("Player Sockets").get_node("p1_psock_adventure")
	# Assert 1
	var transit = Time.get_unix_time_from_system()
	await get_tree().create_timer(1.0).timeout
	assert_gte(ps.calculate_animation_offset(transit, 30), 0) # Case 1, the normal case which is a positive non-zero time difference
	remove_actor()

# White box test
# This test checks that the rollback calculation returns a -1 (error) when the transit time exceeds the total animation length
func test_rollback_calculation_produces_negative_one_when_transit_time_exceeds_animation_duration():
	# Assert 2: Assert that a transit time that exceeds the animations length should return -1 (avoid playing the animation)
	instantiate_player_actor_test()
	var ps = mtl.get_node("Player Sockets").get_node("p1_psock_adventure")
	# Assert 2
	var transit = Time.get_unix_time_from_system()
	await get_tree().create_timer(1.0).timeout # one second delay
	assert_eq(ps.calculate_animation_offset(transit, 0), -1) # Case 3, another "bad" case which should not play animation
	remove_actor()

# Black box test
# This test checks that an error case in rollback calculation means that the peer is removed from the game
func test_rollback_calculation_signals_player_removal_on_failure():
	# Assert 3: Assert that the actor is freed when the transit time is too high.
	var server_mtl = load("res://scenes/main_scene.tscn").instantiate()
	var client_mtl = load("res://scenes/main_scene.tscn").instantiate()
	add_child(server_mtl)
	add_child(client_mtl)
	var peer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer

	server_mtl.set_multiplayer_authority(1)
	server_mtl.get_node("Multplayer Manager")._on_butt_host_pressed()
	
	server_mtl.get_node("Multplayer Manager").high_latency_removal(2) # A slightly unlikely case, but i'm just testing the interaction between ps and mm.
	# Assert 3
	assert_freed(server_mtl.get_node("Multplayer Manager/2"), "client game") # after a latency issue, the actor who reports should be expunged

# Black box test
# This test checks that the server never volunteers to remove itself from the 
# game if it is called on to do so because of high latency
func test_high_latency_removal_never_removes_server():
	# Assert 4: Assert that the server will never free itself when the transit time is too high.
	var server_mtl = load("res://scenes/main_scene.tscn").instantiate()
	add_child(server_mtl)
	var peer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer

	server_mtl.set_multiplayer_authority(1)
	server_mtl.get_node("Multplayer Manager")._on_butt_host_pressed()
	var server_ps = server_mtl.get_node("Player Sockets/p1_psock_adventure")

	
	server_ps.calculate_animation_offset(0, -1) # A slightly unlikely case, but i'm just testing the interaction between ps and mm.
	# Assert 4
	assert_not_freed(server_mtl.get_node("Multplayer Manager/1"), "server game") # after a latency issue, the actor who reports should be expunged

# The following three white box tests on set_delay and set_delay_color which
# work in conjunction to change the color of a symbol that shows roughly how
# much latency should be expected from a player.

#func set_delay(dt : float):
#	delay = dt
#	set_delay_color()
#
#func set_delay_color():
#	if delay < 100:
#		emit_signal("name_tag_color", 0x7BB662)
#	elif delay >= 100 and delay < 200:
#		emit_signal("name_tag_color", 0xFFD301)
#	else:
#		emit_signal("name_tag_color", 0xE03C32)

# White box test
# When the function set_delay is called with a value between 0 and 99, the 
# name_tag_color signal with green hex value must be emitted
func test_delay_symbol_color_green():
	# Assert 5: Assert that a delay between 0 and 99 emits a green name tag signal
	instantiate_player_actor_test()
	watch_signals(actor)
	actor.set_delay(0.020) # pass a hardcoded delay of 20 ms on actor
	# Assert 5
	assert_signal_emitted_with_parameters(actor, "name_tag_color", [0x7BB662]) # green color should be passed
	remove_actor()

# White box test
# When the function set_delay is called with a value between 100 and 199, the 
# name_tag_color signal with yellow hex value must be emitted
func test_delay_symbol_color_yellow():
	# Assert 6: Assert that a delay between 100 and 199 emits a yellow name tag signal
	instantiate_player_actor_test()
	watch_signals(actor)
	actor.set_delay(0.120) # pass a hardcoded delay of 220 ms on actor
	# Assert 6
	assert_signal_emitted_with_parameters(actor, "name_tag_color", [0xFFD301]) # yellow color should be passed
	remove_actor()

# White box test
# When the function set_delay is called with any other value, the name_tag_color
# signal with red hex value must be emitted
func test_delay_symbol_color_red():
	# Assert 7: Assert that any other delay emits a red name tag signal
	instantiate_player_actor_test()
	watch_signals(actor)
	actor.set_delay(0.220) # pass a hardcoded delay of 220 ms on actor
	# Assert 7
	assert_signal_emitted_with_parameters(actor, "name_tag_color", [0xE03C32]) # red color should be passed
	remove_actor()

# For this integration test, a remote procedure call makes a change to the 
# server actor node ("Multplayer Manager/1") of type CharacterBody3D after 
# being called from "Multiplayer Manager" of type Node

# Integration test
# When ping is called, the server updates the value of the local instance of 
# the actor with name "peer id". 
func test_update_player_delay_and_name_tag_color_update():
	var server_mtl = load("res://scenes/main_scene.tscn").instantiate()
	add_child(server_mtl)
	var peer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer

	server_mtl.set_multiplayer_authority(1)
	server_mtl.get_node("Multplayer Manager")._on_butt_host_pressed()
	var server_ps = server_mtl.get_node("Player Sockets/p1_psock_adventure")
	watch_signals(server_mtl.get_node("Multplayer Manager/1"))
	var t1 = Time.get_unix_time_from_system()
	#await get_tree().create_timer(0.01).timeout
	server_ps.ping(t1, 1) # A slightly unlikely case, but i'm just testing the interaction between ps and mm.
	# Assert 8
	assert_signal_emitted_with_parameters(server_mtl.get_node("Multplayer Manager/1"), "name_tag_color", [0x7BB662]) # after a latency issue, the actor who reports should be expunged
