extends Panel

var follow_mouse := true

func show_info(stack):
	if not stack or not stack.item:
		visible = false
		return

	$Label.text = "%s\n\n%s" % [stack.item.item_name, stack.item.description]
	visible = true

func _process(_delta):
	if follow_mouse:
		global_position = get_global_mouse_position() + Vector2(16, 16)
