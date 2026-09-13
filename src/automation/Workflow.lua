local Workflow = {}
Workflow.collectAndSell = {
	id = "collect-and-sell", version = 1, initial = "find_item",
	description = "Collect classified items until inventory is full, then route to a seller.",
	states = {
		find_item = { label = "Find item", on = { target_found = "move_to_item" } },
		move_to_item = { label = "Move to item", on = { arrived = "pickup" } },
		pickup = { label = "Pick up", on = { completed = "check_inventory" } },
		check_inventory = { label = "Check inventory", on = { inventory_full = "move_to_seller", inventory_available = "find_item" } },
		move_to_seller = { label = "Move to seller", on = { arrived = "sell" } },
		sell = { label = "Sell", on = { completed = "find_item" } },
	},
}
return Workflow
