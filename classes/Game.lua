local lp = love.physics

require'classes.Class'
require'classes.World'
require'classes.Unit'
require'classes.Camera'


local path_debug = false  -- Set 'true' to draw the path map on-screen.


Game = Class("Game", nil, {
	units = {},
	world = nil,
	cam   = nil
})


function Game:init ()
	self.world = World:new({
		name = "World_01",
		size = { w = 200, h = 200 },
	})


	self.envBody = lp.newBody(self.world.physics, 0, 0, 'static')
	self.envShape = lp.newChainShape(false,
		-15, -15,
		-15, -10,
		  3, -10,
		  3,  10,
		 10,  10,
		 10,  30,
		-10,  30,
		-10,  10,
		 -3,  10,
		 -3,  -4,
		-21,  -4,
		-21, -15
	)
	self.envFixture = lp.newFixture(self.envBody, self.envShape, 1)

	self.world:update_pathing(1)


	self.cam = Camera:new({world = self.world, pxPerUnit = 10})
	self.cam:setTargetCoordinates(0,0)


	table.insert(self.units, Unit:new({name = "Hero", zone = self.world, loc = {x = 20, y = 20}}))
	table.insert(self.units, Unit:new({name = "Monster", zone = self.world, loc = {x = -20, y = -20}}))

	return self
end


function Game:update(dt)
	self.world:update(dt)

	for _, unit in pairs(self.units) do
		unit:update(dt)
	end

	self.cam:update(dt)
end


function Game:draw_path_map ( radius )
	radius = radius or 1

	local pather = self.world.pathers[radius]


	if not self.path_canvas or self.path_canvas_radius ~= radius then
		local grid = self.world.pathers[radius]:getGrid()

		self.path_canvas_radius = radius
		self.path_canvas = love.graphics.newCanvas()

		love.graphics.setCanvas(self.path_canvas)
		love.graphics.setColor(color.FIRE_ENGINE_RED)

		for _, p in ipairs(self.world.map_graph) do
			local point = self.cam:worldPosToCameraPos(p.x, p.y)

			if not grid:isWalkableAt(p.x, p.y) then
				love.graphics.circle('fill', point.x, point.y, 5)
			end
		end

		love.graphics.setCanvas()
	end

	love.graphics.draw(self.path_canvas)
end


function Game:drawWorld()
	if path_debug then
		self:draw_path_map()
	end

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
