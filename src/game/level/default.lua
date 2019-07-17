local lovetoys = require "lib.lovetoys.lovetoys"

local Level = require "src.game.level"

local BuildingComponent = require "src.game.buildingcomponent"
local GroundComponent = require "src.game.groundcomponent"
local InteractiveComponent = require "src.game.interactivecomponent"
local PositionComponent = require "src.game.positioncomponent"
local ResourceComponent = require "src.game.resourcecomponent"
local SpriteComponent = require "src.game.spritecomponent"
local TileComponent = require "src.game.tilecomponent"

local InfoPanel = require "src.game.gui.infopanel"

local blueprint = require "src.game.blueprint"
local spriteSheet = require "src.game.spritesheet"

local DefaultLevel = Level:subclass("DefaultLevel")

function DefaultLevel:initiate(engine, map, gui)
	Level.initiate(self, engine, map, gui)

	do -- Initial tile.
		local tile = lovetoys.Entity()
		tile:add(TileComponent(TileComponent.GRASS, 0, 0))
		tile:add(SpriteComponent(spriteSheet:getSprite("grass-tile"), -map.halfTileWidth))
		engine:addEntity(tile)
		map:addTile(TileComponent.GRASS, 0, 0)
	end

	do -- Initial runestone.
		local runestone = blueprint:createRunestone()
		local x, y, minGrid, maxGrid = map:addObject(runestone, 0, 0)
		runestone:get("SpriteComponent"):setDrawPosition(x, y)
		runestone:add(PositionComponent(minGrid, maxGrid, 0, 0))
		InteractiveComponent:makeInteractive(runestone, x, y)
		engine:addEntity(runestone)
	end

	local startingResources = {
		[ResourceComponent.WOOD] = 30,
		[ResourceComponent.IRON] = 6,
		[ResourceComponent.TOOL] = 12,
		[ResourceComponent.BREAD] = 6
	}

	-- Split so that we can assign the children to the adults.
	local startingVillagers = {
		{ -- Adults
			maleVillagers = 2,
			femaleVillagers = 2
		},
		{ -- Children
			maleChild = 1,
			femaleChild = 1
		}
	}
	local startingPositions = {
		{ 11, 2 },
		{ 12, 6 },
		{ 12, 10 },
		{ 9, 12 },
		{ 5, 12 },
		{ 2, 11 }
		--{ 8, 4 }
	}

	for type,num in pairs(startingResources) do
		while num > 0 do
			local resource = blueprint:createResourcePile(type, math.min(3, num))
			resource:add(PositionComponent(map:getFreeGrid(0, 0, type), nil, 0, 0))
			map:addResource(resource, resource:get("PositionComponent"):getGrid())
			engine:addEntity(resource)

			num = num - resource:get("ResourceComponent"):getResourceAmount()
		end
	end

	local females = {}
	for _,tbl in ipairs(startingVillagers) do
		for type,num in pairs(tbl) do
			for _=1,num do
				local isMale = type:match("^male")
				local isChild = type:match("Child$")
				local mother

				if isChild then
					mother = table.remove(females)
				end

				local villager = blueprint:createVillager(mother, nil,
				                                          isMale and "male" or "female",
				                                          isChild and 5 or 20)

				if not isMale and not isChild then
					table.insert(females, villager)
				end

				local gi, gj = unpack(table.remove(startingPositions) or {})
				local grid
				if not gi or not gj then
					grid = map:getFreeGrid(0, 0, "villager")
					gi, gj = grid.gi, grid.gj
				else
					grid = map:getGrid(gi, gj)
				end

				villager:add(PositionComponent(grid, nil, 0, 0))
				villager:add(GroundComponent(map:gridToGroundCoords(gi + 0.5, gj + 0.5)))

				engine:addEntity(villager)
			end
		end
	end

	self.objectives = {
		{
			text = "Place a grass tile",
			pre = function()
				self.gui:setHint(InfoPanel.CONTENT.PLACE_TERRAIN, TileComponent.GRASS)
			end,
			cond = function()
				for ti,tj,type in self.map:eachTile() do
					if type == TileComponent.GRASS and (ti ~= 0 or tj ~= 0) then
						return true
					end
				end
			end
		},
		{
			text = "Place a dwelling",
			pre = function()
				self.gui:setHint(InfoPanel.CONTENT.PLACE_BUILDING, BuildingComponent.DWELLING)
			end,
			cond = function()
				for _,entity in pairs(self.engine:getEntitiesWithComponent("ConstructionComponent")) do
					if entity:get("ConstructionComponent"):getType() == BuildingComponent.DWELLING then
						return true
					end
				end
			end
		},
		{
			text = "Assign a villager to build the dwelling",
			pre = function()
				self.gui:setHint(nil)
			end,
			cond = function()
				for _,entity in pairs(self.engine:getEntitiesWithComponent("ConstructionComponent")) do
					if entity:get("AssignmentComponent"):getNumAssignees() > 0 then
						return true
					end
				end
			end
		}
	}
end

function Level:getResources(tileType)
	if tileType == TileComponent.GRASS then
		-- TODO: Would be nice with some trees, but not the early levels
		return 0, 0 --return math.max(0, math.floor((love.math.random(9) - 5) / 2)), 0
	elseif tileType == TileComponent.FOREST then
		return love.math.random(2, 6), 0
	elseif tileType == TileComponent.MOUNTAIN then
		return math.max(0, love.math.random(5) - 4), love.math.random(2, 4)
	end
end

return DefaultLevel
