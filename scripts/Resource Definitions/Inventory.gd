extends Resource
class_name Inventory

# Dictionary to store inventory items
var inventory: Dictionary = {}

# Signal for updating UI when inventory changes
signal inventory_updated

# Add an item to the inventory
func add_item(item_name: String, quantity: int = 1):
	if item_name in inventory:
		inventory[item_name] += quantity
	else:
		inventory[item_name] = quantity
	
	inventory_updated.emit()  # Notify UI
	print("Added: ", quantity, "x ", item_name)

# Remove an item
func remove_item(item_name: String, quantity: int = 1):
	if item_name in inventory:
		inventory[item_name] -= quantity
		if inventory[item_name] <= 0:
			inventory.erase(item_name)

	inventory_updated.emit()  # Notify UI
	print("Removed: ", quantity, "x ", item_name)

# Check if an item exists
func has_item(item_name: String) -> bool:
	return inventory.get(item_name, 0) > 0

# Get item quantity
func get_quantity(item_name: String) -> int:
	return inventory.get(item_name, 0)

# Save inventory to file
func save_inventory():
	var file = FileAccess.open("user://inventory.save", FileAccess.WRITE)
	file.store_var(inventory)
	print("Inventory saved.")

# Load inventory from file
func load_inventory():
	if FileAccess.file_exists("user://inventory.save"):
		var file = FileAccess.open("user://inventory.save", FileAccess.READ)
		inventory = file.get_var()
		inventory_updated.emit()
		print("Inventory loaded.")

## Clear the inventory
func clear_inventory():
	inventory.clear()
	inventory_updated.emit()

## Transfer an item to another inventory
func transfer_item(item_name: String, quantity: int, target_inventory: Inventory):
	if has_item(item_name) and get_quantity(item_name) >= quantity:
		remove_item(item_name, quantity)
		target_inventory.add_item(item_name, quantity)
# Get all items in the inventory
func get_items() -> Dictionary:
	return inventory
