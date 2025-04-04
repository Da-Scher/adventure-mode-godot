extends Node
class_name CraftingLogic

signal crafting_success(item_name: String)
signal crafting_failed(reason: String)

## Check if the player has the required ingredients
func has_ingredients(inventory: Inventory, recipe: Dictionary) -> bool:
	for ingredient in recipe.ingredients:
		if not inventory.has_item(ingredient.item) or inventory.get_quantity(ingredient.item) < ingredient.quantity:
			return false
	return true

## Craft an item
func craft_item(inventory: Inventory, recipe: Dictionary):
	if has_ingredients(inventory, recipe):
		for ingredient in recipe.ingredients:
			inventory.remove_item(ingredient.item, ingredient.quantity)
		inventory.add_item(recipe.result.item, recipe.result.quantity)
		crafting_success.emit(recipe.result.item)
	else:
		crafting_failed.emit("Not enough ingredients")
