extends Node3D

@export var wood_item: InventoryItem  
@export var wood_quantity: int = 1


func _ready():
	$tree_base.rotate_y(randi() % 360)
	$tree_second.rotate_y(randi() % 360)
	$tree_top.rotate_y(randi() % 360)

# Call this when the player "chops" the tree
func chop_tree():
	if wood_item:
		Inventory.add_item(wood_item, wood_quantity)
		print("Added wood directly to inventory!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
