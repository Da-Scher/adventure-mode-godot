extends Node

# pt_map : Dictionary() -- peer-thrall map that associates key peer to their thrall value
# (key) peer : Int
# (value) thrall : Node (actor) 
var pt_map := Dictionary()

func track_player_node(peer_id, player_node):
	pt_map[peer_id] = {"NODE": player_node, "NAME": player_node.name}
	
func get_player_node(peer_id):
	return pt_map[peer_id]
	
@rpc("reliable") # this rpc needs to be reliable because their needs to be a guaranteed agreement about who controls what.
func who_is_that(new_peer_message : PackedByteArray):
	# TODO: Find out if this isn't atomic.
	pass

# Helper functions that only help me and others as developers.

# log_print(String) -- custom debug print utility.
# Arguments: 
# msg : String -- the string message to be displayed.
# Return: void function.
func log_message(msg: String) -> void:
	var pid = OS.get_process_id()
	var stack = get_stack()
	var caller_info = stack[1] if stack.size() > 1 else {"line": -1, "function": "unknown"}
	print("Process: %d, File: %s, Line: %d, Function: %s → %s" % [
		pid,
		get_script().resource_path,
		caller_info.line,
		caller_info.function,
		msg
	])
