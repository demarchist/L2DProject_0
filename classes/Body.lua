local lp = require'love.physics'
local lg = require'love.graphics'
local color = require'include.color'

require'classes.Class'
require'classes.World'
require'classes.Zone'
require'classes.Transform'


Body = Class("Body", Zone, {
	lp          = {          -- Love physics properties and userdata objects.
		body    = nil,
		shape   = nil,
		fixture = nil,
		type    = 'static',
	},
	density     = 25.5,      -- kg/m^2
	restitution = 0.9,

	-- Read-only.
	world       = nil,      -- World containing the physics context in which this body exists.
})



--[[
-- ===  METHOD  ========================================================================
--    Signature:  Body:init ( ) -> table
--  Description:  Apply default properties to and set meta-tables for a Body object.
--      Returns:  Self (Body object).
-- =====================================================================================
--]]
function Body:init ( )
	-- Store associated World zone parent for convenience.
	self.world = self.parent
	while self.world and not is_a(self.world, World) do
		self.world = self.world.parent
	end

	if not self.world then
		error("Body:init() error [a body must exist within a Zone heirarchy below a World object].", 1)
		return
	end


	-- Pseudo-table to obtain common world-relative properties.
	self._w = {}
	setmetatable(self._w, {
		__index = function ( table, key )
			return key == 'x'   and body:getX()
			    or key == 'y'   and body:getY()
			    or key == 'rot' and body:getAngle()
			    or key == 'loc' and Vector(body:getX(), body:getY(), self.world)
			    or table[key]
		end
	})


	-- Create associated Love2D physics objects.
	local body = self.lp.body or lp.newBody(self.world.physics, nil, nil, self.lp.type)
	local shape = self.lp.shape or lp.newCircleShape(1)
	local fixture = self.lp.fixture or lp.newFixture(body, shape, 1)

	fixture:setUserData(self)
	fixture:setRestitution(self.restitution)
	fixture:setDensity(self.density)

	self.lp.body = body
	self.lp.shape = shape
	self.lp.fixture = fixture


	-- Meta-methods to synchronize with the associated Love2D physics body.
	local init_transform = self.transform
	self.transform = Transform2D{ zone = self.parent }

	local mt = getmetatable(self.transform.loc)
	local _index = mt.__index
	local _newindex = mt.__newindex

	mt.__index = function ( table, key )
		if key == 'x' or key == 'y' then
			return Vector(self._w.loc):transform(self.parent)[key]
		end

		return type(_index) == 'table' and _index[key]
		    or type(_index) == 'function' and _index(table, key)
		    or table[key]
	end

	mt.__newindex = function ( table, key, value )
		if key == 'x' or key == 'y' then
			local w_loc = self._w.loc
			local loc = w_loc:transform(self.parent)

			loc[key] = value

			w_loc = loc:transform(self.world)

			lp_body:setX(w_loc.x)
			lp_body:setY(w_loc.y)

		elseif type(_newindex) == 'function' then
			_newindex(table, key, value)

		else
			table[key] = value
		end
	end


	mt = getmetatable(self.transform)
	_index = mt.__index
	_newindex = mt.__newindex

	mt.__index = function ( table, key )
		if key == 'rot' then
			return self._w.angle  -- FIXME: Apply transformations.
		end

		if key == 'loc' then
			return self._w.loc:transform(self.parent)
		end

		return type(_index) == 'function' and _index(table, key)
		    or type(_index) == 'table' and _index[key]
		    or table[key]
	end

	mt.__newindex = function ( table, key, value )
		if key == 'rot' then
			body:setAngle(value)  -- FIXME: Apply transformations.

		elseif key == 'loc' then
			for k, v in ipairs(value) do
				table.trans[k] = v
			end

		elseif _newindex then
			_newindex(table, key, value)

		else
			table[key] = value
		end
	end


	-- Re-apply initial transform parameters via meta-methods.
	for k, v in ipairs(init_transform) do
		self.transform[k] = v
	end


	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Body:draw_start ( ) -> nil
--  Description:  Apply transformations to allow drawing to be done in local zone
--                coordinates.
-- =====================================================================================
--]]
function Body:draw_start ( )
	self.parent:push()
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Body:draw_end ( ) -> nil
--  Description:  Remove transformations performed by Body:draw_start().
-- =====================================================================================
--]]
function Body:draw_end ( )
	lg.pop()
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Body:draw ( ) -> nil
--  Description:  Draw a basic form for this body.
--        Notes:  If overriding, be sure to call Body:draw_start() and Body:draw_end(),
--                as appropriate.
-- =====================================================================================
--]]
function Body:draw ( )
	self:draw_start() do

		self.draw_funcs[self.lp.shape:getType()](self)


		-- Velocity vector.
		local velocity = Vector(self.lp.body:getLinearVelocity())

		if velocity:mag() > 0 then
			local loc = self.transform.loc

			velocity = velocity:transform(self.world, self.parent)

			lg.setColor(color.FERN_GREEN); lg.setLine(1, 'smooth')
			lg.line(loc.x, loc.y, loc.x + velocity.x, loc.y + velocity.y)
			--Maybe a nice little arrowhead?
		end

	end self:draw_end()
end


-- Table of drawing functions.  Subclasses can override individual shape types, if desired.
Body.draw_funcs = {

	circle = function ( self )
		local x, y, rot = self.transform.trans.x, self.transform.trans.y, self.transform.rot
		local r = self.lp.shape:getRadius()

		lg.setColor(color.TAN); lg.setLine(2, 'smooth')
		lg.circle('line', x, y, r, 50)
		lg.line(x, y, x + r * math.cos(rot), y - r * math.sin(rot))
	end,


	polygon = function ( self )
	end,


	edge = function ( self )
		local a, b = Vector{ zone = self.world }, Vector{ zone = self.world }

		lg.setColor(color.DARK_GRAY); lg.setLine(2, 'smooth')

		a.x, a.y, b.x, b.y = self.lp.shape:getPoints()
		a:transform(self.parent)
		b:transform(self.parent)

		lg.line(a.x, a.y, b.x, b.y)
	end,


	chain = function ( self )
		local shape = self.lp.shape

		lg.setColor(color.DARK_GRAY); lg.setLine(4, 'smooth')

		local a = Vector.transform({shape:getPoint(1)}, self.world, self.parent)
		for i = 2, shape:getVertexCount() do
			local b = Vector.transform({shape:getPoint(i)}, self.world, self.parent)

			lg.line(a.x, a.y, b.x, b.y)

			a = b
		end
	end,

}
