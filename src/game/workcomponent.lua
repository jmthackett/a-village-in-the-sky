local class = require "lib.middleclass"

local ResourceComponent = require "src.game.resourcecomponent"

local WorkComponent = class("WorkComponent")

WorkComponent.static.UNEMPLOYED = 0
WorkComponent.static.WOODCUTTER = 1
WorkComponent.static.MINER = 2
WorkComponent.static.BLACKSMITH = 3
WorkComponent.static.FARMER = 4
WorkComponent.static.BAKER = 5
WorkComponent.static.BUILDER = 6

WorkComponent.static.RESOURCE_TO_WORK = {
	[ResourceComponent.WOOD] = WorkComponent.WOODCUTTER,
	[ResourceComponent.IRON] = WorkComponent.MINER,
	[ResourceComponent.TOOL] = WorkComponent.BLACKSMITH,
	[ResourceComponent.GRAIN] = WorkComponent.FARMER,
	[ResourceComponent.BREAD] = WorkComponent.BAKER,
}

WorkComponent.static.WORK_NAME = {
	[WorkComponent.UNEMPLOYED] = "unemployed",
	[WorkComponent.WOODCUTTER] = "woodcutter",
	[WorkComponent.MINER] = "miner",
	[WorkComponent.BLACKSMITH] = "blacksmith",
	[WorkComponent.FARMER] = "farmer",
	[WorkComponent.BAKER] = "baker",
	[WorkComponent.BUILDER] = "builder"
}

-- TODO: These could be automatically generated from sprite information,
--       or slice information?
WorkComponent.static.WORK_PLACES = {
	[WorkComponent.WOODCUTTER] = {
		{ rotation = 90, ogi = -2, ogj = 0 },
		{ rotation = 270, ogi = 0, ogj = -2 }
	},
	[WorkComponent.MINER] = {
		{ rotation = 90, ogi = -2, ogj = 0 },
		{ rotation = 270, ogi = 0, ogj = -2 }
	},
}

function WorkComponent:initialize(workType)
	self.type = workType
	self.completion = 0.0
	self.workers = setmetatable({}, { __mode = 'v' })
end

function WorkComponent:getType()
	return self.type
end

function WorkComponent:getTypeName()
	return WorkComponent.WORK_NAME[self.type]
end

function WorkComponent:getWorkGrids()
	return WorkComponent.WORK_PLACES[self.type]
end

function WorkComponent:assign(villager)
	table.insert(self.workers, villager)
end

function WorkComponent:unassign(villager)
	for k,v in ipairs(self.workers) do
		if v == villager then
			table.remove(self.workers, k)
			return
		end
	end
end

function WorkComponent:getAssignedVillagers()
	return self.workers
end

function WorkComponent:increaseCompletion(value)
	self.completion = self.completion + value
end

function WorkComponent:isComplete()
	return self.completion >= 100.0
end

return WorkComponent
