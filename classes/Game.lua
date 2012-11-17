local lp = require'love.physics'
local lg = require'love.graphics'


require'classes.Class'
require'classes.World'
require'classes.Unit'
require'classes.Camera'


local path_debug = false  -- Set 'true' to draw the path map on-screen.


Game = Class("Game", nil, {
	units       = {},
	environment = {},
	screen      = nil,
	world       = nil,
	cam         = nil
})


function Game:init ()
	local width, height = lg.getMode()

	self.screen = Zone{ name = "screen", size = { w = width, h = height } }
	self.world = World{ name = "world", parent = self.screen, size = { w = 200, h = 200 } }
	self.cam = Camera{ name = "camera", parent = self.world, size = { w = 2, h = 2 } }

	self.world.scale = { x = self.world.size.w / self.screen.size.w, y = self.world.size.h / self.screen.size.h }

	self.units = {}
	self.environment = {}


	local body_lp = {
		body = lp.newBody(self.world.physics, 0, 0, 'static'),
		shape = lp.newChainShape(
			false,
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
		),
	}
	body_lp.fixture = lp.newFixture(body_lp.body, body_lp.shape, 1)

	table.insert(self.environment, Body {
		zone = self.world,
		lp   = body_lp,
	})


	table.insert(self.units, Unit{ name = "Hero", zone = self.world, position = { loc = {x = 20, y = 20} } })
	table.insert(self.units, Unit{ name = "Monster", zone = self.world, position = { loc = {x = -20, y = -20} } })


	self.world:update_pathing(1)


	return self
end


function Game:update(dt)
	self.world:update(dt)

	for _, unit in pairs(self.units) do
		unit:update(dt)
	end

	self.cam:update(dt, Vector(love.mouse.getX(), love.mouse.getY()):transform(self.screen, self.cam))
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
			local point = p:transform(self.world, self.cam)

			if not grid:isWalkableAt(point.x, point.y) then
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
	self.cam:mousepressed(Vector(x, y):transform(self.screen, self.cam), button)
end


function Game:mousereleased(x, y, button)
	self.cam:mousereleased(Vector(x, y):transform(self.screen, self.cam), button)
end


function Game:keypressed(key, unicode)
	-- https://love2d.org/wiki/KeyConstant
	if(key == 'b') then
	elseif key == 'a' then
	elseif key == 'up' then
		self.cam.center.y = self.cam.center.y + 10
	elseif key == 'down' then
		self.cam.center.y = self.cam.center.y - 10
	elseif key == 'left' then
		self.cam.center.x = self.cam.center.x - 10
	elseif key == 'right' then
		self.cam.center.x = self.cam.center.x + 10
	elseif key == 'escape' then
		love.event.push("quit")   -- actually causes the app to quit
	end
end


function Game:keyreleased(key, unicode)
end
