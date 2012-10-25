--[[------------------------------------------------
	Game Class
--]]------------------------------------------------

require 'classes.Class'
require 'classes.World'
require 'classes.Actor'
require 'classes.Camera'


Game = Class("Game", nil, {
	actors = {},
	world = nil,
	cam = nil
})

function Game:new ( init )
	local game = init or {}

	Game.super.new(self, game)

	return game:init()
end

function Game:init ()

	self.world = World:new({name = "World_01"})

	self.cam = Camera:new({world = self.world, pxPerUnit = 10})
	self.cam:setTargetCoordinates(0,0)

	table.insert(self.actors, Actor:new({name = "Hero", world = self.world, loc = {x = 20, y = 20}}))
	table.insert(self.actors, Actor:new({name = "Monster", world = self.world, loc = {x = -20, y = -20}}))

	return self
end

function Game:update(dt)
	self.world:update(dt)

	for k, lActor in pairs(self.actors) do
		lActor:update()
	end

	self.cam:update(dt)
end

function Game:drawWorld()
	self.cam:render()
end

function Game:mousepressed(x, y, button)
	-- https://love2d.org/wiki/MouseConstant
	self.cam:mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
	self.cam:mousereleased(x, y, button)
end

function Game:keypressed(key, unicode)
	-- https://love2d.org/wiki/KeyConstant
	if(key == 'b') then
	elseif key == 'a' then
	elseif key == 'up' then
		self.cam:setTargetCoordinates(self.cam.targetCoordinates.x, self.cam.targetCoordinates.y + 10)
	elseif key == 'down' then
		self.cam:setTargetCoordinates(self.cam.targetCoordinates.x, self.cam.targetCoordinates.y - 10)
	elseif key == 'left' then
		self.cam:setTargetCoordinates(self.cam.targetCoordinates.x - 10, self.cam.targetCoordinates.y)
	elseif key == 'right' then
		self.cam:setTargetCoordinates(self.cam.targetCoordinates.x + 10, self.cam.targetCoordinates.y)
	elseif key == 'escape' then
		love.event.push("quit")   -- actually causes the app to quit
	end
end

function Game:keyreleased(key, unicode)
end
