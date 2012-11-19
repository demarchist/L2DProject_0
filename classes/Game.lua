local lp = require'love.physics'
local lg = require'love.graphics'

require'classes.Class'
require'classes.Unit'
require'classes.World'
require'classes.Camera'


local path_debug = false  -- Set 'true' to draw the path map on-screen.


Game = Class("Game", nil, {
	units       = {},
	environment = {},
	screen      = nil,
	world       = nil,
	cam         = nil
})


function Game:init ( )
	local width, height = lg.getMode()


	-- Screen.
	local s_size = { w = width, h = height }
	self.screen = Zone{ name = "screen", size = s_size }
	print("Screen:")
	print(self.screen.transform.matrix)


	-- World.
	local w_size = { w = 200, h = 200 }
	local w_xform = Transform2D {
		loc = Vector(w_size.w/2, w_size.h/2),
	}
	self.world = World{ name = "world", parent = self.screen, size = w_size, transform = w_xform }
	print("World:")
	print(self.world.transform.matrix)


	-- Camera.
	local c_size = { w = 2, h = 2 }
	local c_scale = Vector(c_size.w / s_size.w, c_size.h / s_size.h)
	local c_xform = Transform2D{ loc = Vector(c_size.w/2, c_size.h/2), scale = c_scale }
	self.cam = Camera{ name = "camera", parent = self.world, size = c_size, transform = c_xform }
	print("Camera:")
	print(self.cam.transform.matrix)



	-- Actors.
	self.units = {}
	self.environment = {}


	table.insert(self.environment, Body {
		parent = self.world,
		lp     = {
			shape = lp.newChainShape(false,
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
				-21, -15),
		}
	})


	local hero_xform = Transform2D{ loc = Vector(20, 20) }
	table.insert(self.units, Unit{ name = "Hero", parent = self.world, transform = hero_xform })

	local monster_xform = Transform2D{ loc = Vector(-20, -20) }
	table.insert(self.units, Unit{ name = "Monster", parent = self.world, transform = monster_xform })


	self.world:update_pathing(1)


	return self
end


function Game:update ( dt )
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
			local point = p:transform(self.cam)

			if not grid:isWalkableAt(point.x, point.y) then
				love.graphics.circle('fill', point.x, point.y, 5)
			end
		end

		love.graphics.setCanvas()
	end

	love.graphics.draw(self.path_canvas)
end


function Game:drawWorld ( )
	if path_debug then
		self:draw_path_map()
	end

	self.cam:render()
end


function Game:mousepressed ( x, y, button )
	self.cam:mousepressed(Vector(x, y):transform(self.screen, self.cam), button)


	local pick = Vector(x, y, self.screen)
	print("Screen:", pick)
	print("Camera:", pick:transform(self.cam))
	print("World:", pick:transform(self.world))
	print()
end


function Game:mousereleased ( x, y, button )
	self.cam:mousereleased(Vector(x, y):transform(self.screen, self.cam), button)
end


function Game:keypressed ( key, unicode )
	local cam_center = self.cam.transform.loc
	-- https://love2d.org/wiki/KeyConstant
	if(key == 'b') then
	elseif key == 'a' then
	elseif key == 'up' then
		cam_center.y = cam_center.y + 10
	elseif key == 'down' then
		cam_center.y = cam_center.y - 10
	elseif key == 'left' then
		cam_center.x = cam_center.x - 10
	elseif key == 'right' then
		cam_center.x = cam_center.x + 10
	elseif key == 'escape' then
		love.event.push('quit')   -- actually causes the app to quit
	end
end


function Game:keyreleased ( key, unicode )
end
