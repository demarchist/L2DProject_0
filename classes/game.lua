--[[------------------------------------------------
	Game Class
--]]------------------------------------------------

Game = {}

function Game:new()
	require('classes.actor')
	humpCamera = require('libraries.hump.camera')

	local object = {
		actors = {}
	}

	object.cam = humpCamera(0,0,1,0)
	object.selectBox = {0,0,0,0,0}

	love.physics.setMeter(1) --need to give some serious thought to proper scale
	object.world = love.physics.newWorld(0,0,true)

	table.insert(object.actors,Actor:new("Hero", object.world, 100, -100))
	table.insert(object.actors,Actor:new("Monster", object.world, -50, 50))
	--object.actors[1]:setObjective(100,100)
	--object.actors[2]:setObjective(150,50)

	object.debug = "Ho"
	
	setmetatable(object, { __index = Game })  -- Inheritance

	return(object)
end

function Game:update(dt)
	self.world:update(dt)

	for i = 1, # self.actors do
		self.actors[i]:update()
	end

	if(self.selectBox[1] == 1) then
		if love.graphics.hasFocus() then
			self.selectBox[4] = love.mouse.getX()
			self.selectBox[5] = love.mouse.getY()
		end
	end
end

function Game:drawWorld()
	self.cam:attach()

	for i = 1, # self.actors do
		self.actors[i]:draw()
	end
	self.cam:detach()

	-- draw a selection box
	love.graphics.setColor(255,255,255)
	if(self.selectBox[1] == 1) then
		love.graphics.rectangle("line", self.selectBox[2], self.selectBox[3], self.selectBox[4]  - self.selectBox[2], self.selectBox[5] - self.selectBox[3])
	end

	local topLeftX, topLeftY = self.cam:worldCoords(self.selectBox[2], self.selectBox[3])
	local bottomRightX, bottomRightY = self.cam:worldCoords(self.selectBox[4], self.selectBox[5])
	local debugText = self.debug .. " - [" .. tostring(self.selectBox[1]) .. ", " .. tostring(topLeftX) .. ", " .. tostring(topLeftY) .. ", " .. tostring(bottomRightX) .. ", " .. tostring(bottomRightY) .. "]"

	love.graphics.print(debugText, (love.graphics.getWidth() / 2), love.graphics.getHeight() - 100,0,1,1,0,0,0,0)
	--love.graphics.print(tostring(self.selectBox[1]) .. ", " .. tostring(self.selectBox[2]) .. ", " .. tostring(self.selectBox[3]) .. ", " .. tostring(self.selectBox[4]) .. ", " .. tostring(self.selectBox[5]), love.graphics.getWidth()/2, love.graphics.getHeight() - 100,0,1,1,0,0,0,0)
	
end

function Game:mousepressed(x, y, button)
	if(button == "l") then
		self.selectBox[1] = 1
		self.selectBox[2] = x
		self.selectBox[3] = y
	end
end

function Game:mousereleased(x, y, button)
	if(button == "l") then
		self.selectBox[1] = 0
		self.selectBox[4] = x
		self.selectBox[5] = y

		local topLeftX, topLeftY = self.cam:worldCoords(self.selectBox[2], self.selectBox[3])
		local bottomRightX, bottomRightY = self.cam:worldCoords(self.selectBox[4], self.selectBox[5])
		self.world:queryBoundingBox(topLeftX, topLeftY, bottomRightX, bottomRightY, self.bbQueryCallback)
	end
end

function Game:bbQueryCallback(lFixture)
	self.debug = "Hey"
	if lFixture ~= nil then
		local lActor = lFixture:getUserData()
		if lActor ~= nil then
			lActor:setSelected(true)
		end
	end
	return(true)
end
