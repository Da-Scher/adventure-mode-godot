extends Control


# Called when the node enters the scene tree for the first time.
var is_open = false

func _ready():
	close()

func _process(_delta):
	if Input.is_action_just_pressed("p1_open_inventory"):
		print ("p1_open_inventory")
		if is_open:
			close()
		else:
			open()

func open():
	self.visible = true
	is_open = true

func close():
	visible = false
	is_open = false
