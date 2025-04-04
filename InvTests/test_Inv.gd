extends "res://addons/gut/test.gd"

# Preload necessary scripts
var CraftingLogic = preload("res://scripts/Resource Definitions/CraftingLogic.gd")  # Update the path if needed
var Inventory = preload("res://scripts/Resource Definitions/Inventory.gd")  # Update the path if needed
var InventoryItem = preload("res://scripts/Resource Definitions/InventoryItem.gd")  # Update the path if needed

# Black-box unit test: Test adding and removing items
func test_add_and_remove_items_black_box():
	var inventory = Inventory.new()

	# Test adding an item
	inventory.add_item("Sword", 1)
	assert_true(inventory.has_item("Sword"), "Inventory should have Sword")  # Assert 1
	assert_eq(inventory.get_quantity("Sword"), 1, "Sword quantity should be 1")  # Assert 2

	# Test adding the same item to stack
	inventory.add_item("Sword", 2)
	assert_eq(inventory.get_quantity("Sword"), 3, "Sword quantity should be 3 after stacking")  # Assert 3

	# Test removing items
	inventory.remove_item("Sword", 2)
	assert_eq(inventory.get_quantity("Sword"), 1, "Sword quantity should be 1 after removal")  # Assert 4
	inventory.remove_item("Sword", 1)
	assert_false(inventory.has_item("Sword"), "Sword should be removed from inventory")  # Assert 5

# White-box unit test: Test inventory saving and loading
func test_save_and_load_inventory_white_box():
	var inventory = Inventory.new()

	# Add items and save inventory
	inventory.add_item("Potion", 5)
	inventory.add_item("Gold", 100)
	inventory.save_inventory()

	# Clear inventory and load from file
	inventory.clear_inventory()
	assert_eq(inventory.get_items().size(), 0, "Inventory should be empty after clearing")  # Assert 6
	inventory.load_inventory()
	assert_true(inventory.has_item("Potion"), "Potion should be loaded from file")  # Assert 7
	assert_eq(inventory.get_quantity("Potion"), 5, "Potion quantity should be 5 after loading")  # Assert 8
	assert_true(inventory.has_item("Gold"), "Gold should be loaded from file")  # Assert 9
	assert_eq(inventory.get_quantity("Gold"), 100, "Gold quantity should be 100 after loading")  # Assert 10

# Integration test: Test crafting system with inventory
func test_crafting_integration():
	var inventory = Inventory.new()
	var crafting_logic = CraftingLogic.new()  # Now properly declared
	var recipe = {"result": {"item": "Sword", "quantity": 1}, "ingredients": [{"item": "Iron", "quantity": 2}]}

	# Test crafting with insufficient ingredients
	inventory.add_item("Iron", 1)
	crafting_logic.craft_item(inventory, recipe)
	assert_false(inventory.has_item("Sword"), "Sword should not be crafted without enough Iron")  # Assert 11
	assert_eq(inventory.get_quantity("Iron"), 1, "Iron should not be consumed if crafting fails")  # Assert 12

	# Test crafting with sufficient ingredients
	inventory.add_item("Iron", 1)
	crafting_logic.craft_item(inventory, recipe)
	assert_true(inventory.has_item("Sword"), "Sword should be crafted")  # Assert 13
	assert_eq(inventory.get_quantity("Iron"), 0, "Iron should be consumed after crafting")  # Assert 14
