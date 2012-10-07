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

	--[[
	local topLeftX, topLeftY = self.cam:worldCoords(self.selectBox[2], self.selectBox[3])
	local bottomRightX, bottomRightY = self.cam:worldCoords(self.selectBox[4], self.selectBox[5])
	local debugText = "[" .. tostring(self.selectBox[1]) .. ", " .. tostring(topLeftX) .. ", " .. tostring(topLeftY) .. ", " .. tostring(bottomRightX) .. ", " .. tostring(bottomRightY) .. "]"
	love.graphics.print(debugText, (love.graphics.getWidth() / 2), love.graphics.getHeight() - 100,0,1,1,0,0,0,0)
	]]
	
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

		for i = 1, # self.actors do
			self.actors[i]:setSelected(false)
		end

		local topLeftX, topLeftY = self.cam:worldCoords(math.min(self.selectBox[2], self.selectBox[4]), math.min(self.selectBox[3],self.selectBox[5]))
		local bottomRightX, bottomRightY = self.cam:worldCoords(math.max(self.selectBox[2], self.selectBox[4]), math.max(self.selectBox[3],self.selectBox[5]))

		self.world:queryBoundingBox(topLeftX, topLeftY, bottomRightX, bottomRightY, self.bbQueryCallback)
	elseif(button == "r") then
		for i = 1, # self.actors do
			if(self.actors[i]:getSelected() == true) then
				local worldX, worldY = self.cam:worldCoords(x, y)
				self.actors[i]:setObjective(worldX, worldY)
			end
		end
	end
end

function Game.bbQueryCallback(lFixture)
	if lFixture ~= nil then
		--print(lFixture, ' - ', type(lFixture))
		local lActor = lFixture:getUserData()
		if lActor ~= nil then
			--print(lActor, ' - ', type(lActor))
			--print(lActor.selected)
			lActor:setSelected(true)
			--print(lActor.selected)
		end
	end
	return(true)
end
