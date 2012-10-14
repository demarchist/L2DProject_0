--[[------------------------------------------------
	Game Class
--]]------------------------------------------------

Game = {}

function Game:new()
	require('classes.actor')
	require('classes.camera')

	local object = {
		actors = {}
	}

	love.physics.setMeter(1) --This may be the default value
	object.world = love.physics.newWorld(0,0,true)

	object.cam = Camera:new({world = object.world, pxPerUnit = 10})
	object.cam:setTargetCoordinates(80,80)

	table.insert(object.actors,Actor:new({name = "Hero", world = object.world, x = 100, y = 100}))
	table.insert(object.actors,Actor:new({name = "Monster", world = object.world, x = -50, y = 50}))
	
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
	self.cam:mousepressed(x, y, button)
end

function Game:mousereleased(x, y, button)
	self.cam:mousereleased(x, y, button)
end

function Game:keypressed(key, unicode)
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
