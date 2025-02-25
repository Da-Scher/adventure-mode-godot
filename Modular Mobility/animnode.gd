extends AnimationNodeAnimation

@export var speed_multiplier = 1.0

func _ready() -> void:
	PeerGlobal.log_message("FUL")
	add_input("funko")

