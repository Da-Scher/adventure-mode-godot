extends Resource
class_name InventoryItem

## Display of this item in inventory
@export var item_name: String = "Unnamed Item"
@export var description: String = "No description."
@export var icon: Texture2D 
@export var max_stack: int = 10

## Item instanced on drop and given reference to this resource for pickup
@export var drop_scene: PackedScene

## Options for the item's inventory behaviour
@export_group("Flags")
@export var stackable: bool = true
@export var fungible: bool = false
@export var volumetric: bool = false

## Check if the item can be stacked
func can_stack() -> bool:
	return stackable

## Drop the item
func drop_item() -> Node:
	if drop_scene:
		return drop_scene.instantiate()
	return null
