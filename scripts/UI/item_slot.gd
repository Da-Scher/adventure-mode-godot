extends Control

var stack
var hovered := false
var tooltip_manager

@onready var icon = $TextureRect
@onready var label = $Label

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if stack and stack.item:
		icon.texture = stack.item.icon
		label.text = str(stack.quantity)
	else:
		icon.texture = null
		label.text = ""

func _on_mouse_entered():
	hovered = true
	if tooltip_manager and stack:
		tooltip_manager.show_tooltip(stack)

func _on_mouse_exited():
	hovered = false
	if tooltip_manager:
		tooltip_manager.hide_tooltip()

func _process(_delta):
	if hovered and Input.is_action_just_pressed("drop_item") and stack:
		Inventory.remove_stack(stack)
