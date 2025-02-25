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
	PeerGlobal.log_message("Added: ", quantity, "x ", item_name)

# Remove an item
func remove_item(item_name: String, quantity: int = 1):
	if item_name in inventory:
		inventory[item_name] -= quantity
		if inventory[item_name] <= 0:
			inventory.erase(item_name)

	inventory_updated.emit()  # Notify UI
	PeerGlobal.log_message("Removed: ", quantity, "x ", item_name)

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
	PeerGlobal.log_message("Inventory saved.")

# Load inventory from file
func load_inventory():
	if FileAccess.file_exists("user://inventory.save"):
		var file = FileAccess.open("user://inventory.save", FileAccess.READ)
		inventory = file.get_var()
		inventory_updated.emit()
		PeerGlobal.log_message("Inventory loaded.")
