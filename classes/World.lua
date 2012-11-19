local lp = require'love.physics'
local lg = require'love.graphics'
local Jumper = require'libraries.Jumper.init'


require'classes.Class'
require'classes.Vector'
require'classes.Zone'


World = Class("World", Zone, {
	physics = nil,
	pathers = nil,
})


function World:init ( )
	self.physics = lp.newWorld()
	lp.setMeter(1)


	self.map_graph = {}
	for x = -math.floor(self.size.w/2), math.floor(self.size.w/2), 1 do
		for y = -math.floor(self.size.h/2), math.floor(self.size.h/2), 1 do
			table.insert(self.map_graph, Vector(x, y, self))
		end
	end


	self.pathers = {}
	self.path_graphs = {}


	return self
end


function World:update_pathing ( radius )
	radius = radius or 1

	self.path_graphs[radius] = self.path_graphs[radius] or {}

	local path_graph = self.path_graphs[radius]
	local physics = self.physics


	for _, p in ipairs(self.map_graph) do
		path_graph[p.x] = path_graph[p.x] or {}
		path_graph[p.x][p.y] = path_graph[p.x][p.y] or 0
	end

	for _, p in ipairs(self.map_graph) do
		local function ray_cb()
			path_graph[p.y][p.x] = 1
			return 0
		end

		physics:rayCast(p.x, p.y, p.x+radius, p.y       , ray_cb)
		physics:rayCast(p.x, p.y, p.x,        p.y+radius, ray_cb)
		physics:rayCast(p.x, p.y, p.x-radius, p.y       , ray_cb)
		physics:rayCast(p.x, p.y, p.x,        p.y-radius, ray_cb)
	end

	self.pathers[radius] = Jumper(path_graph, 0, true, 'EUCLIDIAN')


	return self.pathers[radius]
end


function World:path ( p1, p2, radius )
	local pather = self.pathers[radius or 1] or self:update_pathing(radius or 1)
	local floor = math.floor
	local path = pather:getPath(floor(p1.x), floor(p1.y), floor(p2.x), floor(p2.y))

	for i, p in ipairs(path) do
		path[i] = Vector(p.x, p.y, self)
	end
end


function World:update ( dt )
	self.physics:update(dt)
end
