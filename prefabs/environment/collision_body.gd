extends StaticBody3D

func chop_tree():
	get_parent().chop_tree()  # Forward the call to the actual tree.gd script
