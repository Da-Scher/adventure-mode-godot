extends Resource
class_name InventoryItem

## Display of this item in inventory
@export var icon : Texture2D 

## Item instanced on drop and given reference to this resource for pickup
@export var drop_scene : PackedScene  # Renamed from `drop_item` to `drop_scene`

## Options for the item's inventory behaviour
@export_group("Flags")
@export var stackable = true
@export var fungible = false
@export var volumetric = false

## Check if the item can be stacked
func can_stack() -> bool:
	return stackable

## Drop the item
func drop_item() -> Node:
	if drop_scene:  # Updated to use `drop_scene`
		return drop_scene.instantiate()
	return null
