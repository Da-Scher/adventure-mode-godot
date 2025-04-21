extends Node
class_name InventoryClass

signal inventory_updated

# Inventory stores InventoryItem resources as keys and their quantities as values
var inventory: Array = []  # each item is {item: InventoryItem, quantity: int}


const MAX_STACKS = 25

func add_item(item_resource: InventoryItem, quantity: int = 1):
	var remaining = quantity

	# Step 1: Try to fill existing stacks
	for stack in inventory:
		if stack.item == item_resource and stack.quantity < item_resource.max_stack:
			var space = item_resource.max_stack - stack.quantity
			var to_add = min(space, remaining)
			stack.quantity += to_add
			remaining -= to_add
			if remaining <= 0:
				inventory_updated.emit()
				return

	# Step 2: Add new stacks if needed
	while remaining > 0:
		if inventory.size() >= MAX_STACKS:
			print("Inventory full! Could not add all items.")
			break
		var to_add = min(item_resource.max_stack, remaining)
		inventory.append({ "item": item_resource, "quantity": to_add })
		remaining -= to_add

	inventory_updated.emit()



func remove_stack(stack_to_remove: Dictionary):
	for i in inventory.size():
		if inventory[i] == stack_to_remove:
			inventory.remove_at(i)
			inventory_updated.emit()
			return
