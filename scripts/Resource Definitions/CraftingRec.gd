extends Resource
class_name CraftingRecipe

@export var result: Dictionary  # Format: {"item": String, "quantity": int}
@export var ingredients: Array[Dictionary]  # Format: [{"item": String, "quantity": int}]
