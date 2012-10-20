--[[------------------------------------------------
	Game Class
--]]------------------------------------------------

Game = {}

function Game:new()
	require('classes.World')
	require('classes.Actor')
	require('classes.Camera')

	local object = {
		actors = {}
	}

	object.world = World:new({name = "World_01"})

	object.cam = Camera:new({world = object.world, pxPerUnit = 10})
	object.cam:setTargetCoordinates(0,0)

	table.insert(object.actors,Actor:new({name = "Hero", world = object.world, x = 20, y = 20}))
	table.insert(object.actors,Actor:new({name = "Monster", world = object.world, x = -20, y = -20}))

	setmetatable(object, { __index = Game })  -- Inheritance

	return(object)
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
