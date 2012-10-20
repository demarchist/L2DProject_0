--[[------------------------------------------------
	Actor Class
--]]------------------------------------------------

require('classes.Class')
require('classes.Vector')

World = Class("World")

function World:new ( init )
	local world = init or {}

	world.name = init.name
	
	World.super.new(self, world)

	return world:init()
end

function World:init ()

	love.physics.setMeter(1) --This may be the default value
	self.physicsWorld = love.physics.newWorld(0,0,true)

	self.mapGraph = {}
	for x = -100, 100, 1 do for y = -100, 100, 1 do table.insert(self.mapGraph, Vector:new({x = x, y = y})) end end
	--self:findPath(Vector:new({x = 1, y = 1}),Vector:new({x = 5, y = 5}))


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

function World.bbQueryCallback(lFixture)
	if lFixture ~= nil then
		--table.insert(self.queryFixtures,lFixture)
		table.insert(game.cam.queryFixtures, lFixture) --I dunno about this
	end
	return(true)
end

function World.worldRayCastCallback(fixture, x, y, xn, yn, fraction)
    local hit = {}
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.xn, hit.yn = xn, yn
    hit.fraction = fraction

    table.insert(Ray.hitList, hit)

    return 1 -- Continues with ray cast through all shapes.
end
