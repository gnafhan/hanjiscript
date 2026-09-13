local require = ...

local TargetSelector = require("automation.TargetSelector")

local Planner = {}
Planner.__index = Planner

local function playerPosition()
	local ok, result = pcall(function()
		local players = game:GetService("Players")
		local player = players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and root.Position or nil
	end)
	return ok and result or nil
end

local function targetInfo(entity, distance)
	if not entity then
		return nil
	end

	return {
		name = entity.name,
		path = entity.path,
		className = entity.className,
		id = entity.id,
		distance = distance,
	}
end

function Planner.new(context)
	return setmetatable({
		context = context,
		selector = TargetSelector.new(context),
	}, Planner)
end

function Planner:_inventoryCount()
	local sensor = self.context and self.context.inventorySensor
	if sensor and type(sensor.getCount) == "function" then
		return sensor:getCount()
	end
	return 0
end

function Planner:_inventoryCapacity()
	local config = self.context and self.context.config
	return config and config:get("automation.inventoryCapacity", 20) or 20
end

function Planner:propose(state, currentTarget)
	local position = playerPosition()

	if state == "find_item" then
		local entity, candidate = self.selector:nearest("collectible", position, { limit = 12 })
		if not entity then
			return {
				state = state,
				action = "wait",
				reason = "No classified collectible is available in the current WorldModel.",
			}
		end

		return {
			state = state,
			signal = "target_found",
			action = "select target",
			target = targetInfo(entity, candidate and candidate.distance),
			reason = "Nearest classified collectible candidate is ready for review.",
		}
	end

	if state == "move_to_item" then
		return {
			state = state,
			signal = "arrived",
			action = "confirm arrival",
			target = targetInfo(currentTarget),
			reason = currentTarget and "Dry-run navigation reached the selected target." or "Select a target before confirming arrival.",
		}
	end

	if state == "pickup" then
		return {
			state = state,
			signal = "completed",
			action = "confirm pickup",
			target = targetInfo(currentTarget),
			reason = "Confirm the observed interaction and world delta before advancing.",
		}
	end

	if state == "check_inventory" then
		local count = self:_inventoryCount()
		local capacity = self:_inventoryCapacity()
		local full = count >= capacity
		return {
			state = state,
			signal = full and "inventory_full" or "inventory_available",
			action = full and "route to seller" or "continue collecting",
			inventory = { count = count, capacity = capacity },
			reason = full
				and ("Inventory is full (%d/%d); a seller is required."):format(count, capacity)
				or ("Inventory has room (%d/%d); continue collecting."):format(count, capacity),
		}
	end

	if state == "move_to_seller" then
		local entity, candidate = self.selector:nearest("seller", position, { limit = 12 })
		return {
			state = state,
			signal = entity and "arrived" or nil,
			action = entity and "confirm seller arrival" or "wait",
			target = targetInfo(entity, candidate and candidate.distance),
			reason = entity and "Classified seller candidate is ready for review." or "No seller candidate was classified in the current WorldModel.",
		}
	end

	if state == "sell" then
		return {
			state = state,
			signal = "completed",
			action = "confirm sale",
			target = targetInfo(currentTarget),
			reason = "Confirm the inventory/currency delta before starting another collection cycle.",
		}
	end

	return { state = state, action = "wait", reason = "No planner rule exists for this workflow state." }
end

return Planner
