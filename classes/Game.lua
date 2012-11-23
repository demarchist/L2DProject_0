local lp = require'love.physics'
local lg = require'love.graphics'
local color = require'include.color'

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
	local s_size = Vector(lg.getMode())
	local p_size = Vector(2, 2)
	local c_size = Vector(60, 60)
	local w_size = Vector(200, 200)


	-- Camera.
	local c_xform = Transform2D {
	}
	self.cam = Camera{ name = "camera", size = c_size, transform = c_xform }


	-- World.
	local w_xform = Transform2D {
	}
	self.world = World{ name = "world", parent = self.cam, size = w_size, transform = w_xform }


	self.cam.world = self.world


	-- Projection.
	local p_xform = Transform2D {
		scale = Vector(2/c_size.x, 2/c_size.y),
	}
	self.proj = Zone{ name = "projection", parent = self.cam, size = p_size, transform = p_xform }


	-- Screen.
	local s_xform = Transform2D {
		scale = Vector(2/s_size.x, 2/s_size.y),
		loc   = Vector(-p_size/2, -p_size/2)
	}
	self.screen = Zone{ name = "screen", parent = self.proj, size = s_size, transform = s_xform }



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

	if false then
		self.cam:render()
	end

	lg.setColor(128, 128, 128, 128)
	self.world:push()
	for _, p in ipairs(self.world.map_graph) do
		lg.circle('fill', p.x, p.y, 1)
	end
	self.world:pop()

	self.screen:push() do
		lg.setColor(255, 255, 0, 64)
		lg.rectangle('fill', 0.5, 0.5, 100, 100)

		self.proj:push() do
			lg.setColor(255, 0, 0, 64)
			lg.rectangle('fill', 0.5, 0.5, 100, 100)

			self.cam:push() do
				lg.setColor(0, 255, 0, 64)
				lg.rectangle('fill', 0.5, 0.5, 100, 100)
			end self.cam:pop()
		end self.proj:pop()
	end self.screen:pop()
end


function Game:mousepressed ( x, y, button )
	self.cam:mousepressed(Vector(x, y):transform(self.screen, self.cam), button)


	local pick = Vector(x, y, self.screen)
	print("Screen:", pick)
	print("NDC:", pick:transform(self.proj, nil, true))
	print("Camera:", pick:transform(self.cam, nil, true))
	print("World:", pick:transform(self.world, nil, true))
	print()
end


function Game:mousereleased ( x, y, button )
	self.cam:mousereleased(Vector(x, y):transform(self.screen, self.cam), button)
end


function Game:keypressed ( key, unicode )
	local world_loc = self.world.transform.loc
	-- https://love2d.org/wiki/KeyConstant
	if key == 'b' then
	elseif key == 'a' then
	elseif key == 'up' then
		world_loc.y = world_loc.y + 10
	elseif key == 'down' then
		world_loc.y = world_loc.y - 10
	elseif key == 'left' then
		world_loc.x = world_loc.x + 10
	elseif key == 'right' then
		world_loc.x = world_loc.x - 10
	elseif key == 'escape' then
		love.event.push('quit')   -- actually causes the app to quit
	end
end


function Game:keyreleased ( key, unicode )
end
