local lp = require'love.physics'

require'classes.Class'
require'classes.Vector'


World = Class("World", nil, {
	name         = "_unnamed_world",
	physicsWorld = nil,
	mapGraph     = {},
})


function World:new ( init )
	local world = init or {}

	World.super.new(self, world)

	return world:init()
end


local env_shape = {
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
	-21, -15,
}

function World:init ( )
	self.physicsWorld = lp.newWorld()
	lp.setMeter(1)


	for x = -100, 100, 1 do for y = -100, 100, 1 do table.insert(self.mapGraph, Vector(x, y)) end end


	self.envBody = lp.newBody(self.physicsWorld, 0, 0, 'static')
	self.envShape = lp.newChainShape(false, unpack(env_shape))
	self.envFixture = lp.newFixture(self.envBody, self.envShape, 1)


	self.pathGraph = {}
	self:updatePathing()


	return self
end


function World:updatePathing ( radius )
	local pathGraph = self.pathGraph
	radius = radius or 1

	for _, pt in ipairs(self.mapGraph) do
		pathGraph[pt.x] = pathGraph[pt.x] or {}
		pathGraph[pt.x][pt.y] = pathGraph[pt.x][pt.y] or 0
	end

	for _, pt in ipairs(self.mapGraph) do
		local function ray_cb()
			pathGraph[pt.y][pt.x] = 1
			return 0
		end

		local world = self.physicsWorld
		world:rayCast(pt.x, pt.y, pt.x+radius, pt.y       , ray_cb)
		world:rayCast(pt.x, pt.y, pt.x,        pt.y+radius, ray_cb)
		world:rayCast(pt.x, pt.y, pt.x-radius, pt.y       , ray_cb)
		world:rayCast(pt.x, pt.y, pt.x,        pt.y-radius, ray_cb)
	end

	self.pather = require('libraries.Jumper.init')(pathGraph, 0)
end


function World:path ( x1, y1, x2, y2 )
	local floor = math.floor

	if self.pather then
		return self.pather:getPath(floor(x1), floor(y1), floor(x2), floor(y2))
	end
end


function World:update ( dt )
	self.physicsWorld:update(dt)
end
