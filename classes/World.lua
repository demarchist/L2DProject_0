local lp = require'love.physics'

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
			table.insert(self.map_graph, {x = x, y = y})
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


	for _, pt in ipairs(self.map_graph) do
		path_graph[pt.x] = path_graph[pt.x] or {}
		path_graph[pt.x][pt.y] = path_graph[pt.x][pt.y] or 0
	end

	for _, pt in ipairs(self.map_graph) do
		local function ray_cb()
			path_graph[pt.y][pt.x] = 1
			return 0
		end

		physics:rayCast(pt.x, pt.y, pt.x+radius, pt.y       , ray_cb)
		physics:rayCast(pt.x, pt.y, pt.x,        pt.y+radius, ray_cb)
		physics:rayCast(pt.x, pt.y, pt.x-radius, pt.y       , ray_cb)
		physics:rayCast(pt.x, pt.y, pt.x,        pt.y-radius, ray_cb)
	end

	self.pathers[radius] = require'libraries.Jumper.init'(path_graph, 0, true, 'EUCLIDIAN')


	return self.pathers[radius]
end


function World:path ( x1, y1, x2, y2, radius )
	radius = radius or 1

	local floor = math.floor
	local pather = self.pathers[radius] or self:update_pathing(radius)


	return pather:getPath(floor(x1), floor(y1), floor(x2), floor(y2))
end


function World:update ( dt )
	self.physics:update(dt)
end
