--[[------------------------------------------------
	Actor Class
--]]------------------------------------------------

require('classes.Class')
require('classes.Vector')

World = Class("World", nil, {
	name         = "_unnamed_world",
	physicsWorld = nil,
	mapGraph = {}
})

function World:new ( init )
	local world = init or {}
	
	World.super.new(self, world)

	return world:init()
end

function World:init ()

	self.physicsWorld = love.physics.newWorld(0,0,true)
	love.physics.setMeter(1) --This may be the default value

	for x = -100, 100, 1 do for y = -100, 100, 1 do table.insert(self.mapGraph, Vector:new({x = x, y = y})) end end

	self.envBody = love.physics.newBody(self.physicsWorld, 0, 0, 'static')
	self.envShape = love.physics.newChainShape( false, -15,-15, -15,-10, 3,-10, 3,10, 10,10, 10,30, -10,30, -10,10, -3,10, -3,-4, -21,-4, -21,-15)
	self.envFixture = love.physics.newFixture(self.envBody, self.envShape, 1)

	return(self)
end

function World:update(dt)
	self.physicsWorld:update(dt)
end

function World:findPath(start, goal)
	--a unit or something would call this to get a path to a goal
end
