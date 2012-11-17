local lp = require'love.physics'
local lg = require'love.graphics'
local color = require'include.color'

require'classes.Class'
require'classes.World'
require'classes.Vector'


Body = Class("Body", nil, {
	lp          = {         -- Love physics properties and userdata objects.
		body    = nil,
		shape   = nil,
		fixture = nil,
		type    = 'static',
	},
	zone        = nil,      -- Must be a Zone object with a World superzone.
	position    = {         -- Relative to 'zone'.
		loc    = Vector(),
		angle  = 0,
	},
	density     = 25.5,     -- kg/m^2
	restitution = 0.9,

	-- Read-only.
	world        = nil,     -- World containing the physics context in which this body exists.
})



--[[
-- ===  METHOD  ========================================================================
--    Signature:  Body:init ( ) -> table
--  Description:  Apply default properties to a Body object.
--      Returns:  Self (Body object).
-- =====================================================================================
--]]
function Body:init ( )
	-- Store associated World zone parent for convenience.
	self.world = self.zone
	while self.world and not self.world:is_a(World) do
		self.world = self.world.parent
	end

	if not self.world then
		print("Error: a body must exist within a Zone heirarchy below a World object.")
		return
	end


	local body = self.lp.body or lp.newBody(self.world.physics, nil, nil, self.lp.type)
	local shape = self.lp.shape or lp.newCircleShape(1)
	local fixture = self.lp.fixture or lp.newFixture(body, shape, 1)

	fixture:setUserData(self)
	fixture:setRestitution(self.restitution)
	fixture:setDensity(self.density)

	self.lp.body = body
	self.lp.shape = shape
	self.lp.fixture = fixture


	self.position = { _self = self, loc = { _self = self } }
	setmetatable(self.position.loc, {
		__index = function ( table, key )
			local self = table._self
			local lp_body = self.lp.body
			local w_loc = Vector(lp_body:getX(), lp_body:getY())
			local loc = w_loc:transform(self.world, self.zone)

			return key == 'object' and loc or loc[key]
		end,

		__newindex = function ( table, key, value )
			local self = table._self
			local lp_body = self.lp.body
			local w_loc = Vector(lp_body:getX(), lp_body:getY())
			local loc = w_loc:transform(self.world, self.zone)

			loc[key] = value

			w_loc = loc:transform(self.zone, self.world)

			lp_body:setX(w_loc.x)
			lp_body:setY(w_loc.y)
		end
	})

	setmetatable(self.position, {
		__index = function ( table, key )
			return key == 'angle' and table._self.lp.body:getAngle() or nil
		end,

		__newindex = function ( table, key, value )  -- FIXME
			if key == 'angle' then table._self.lp.body:setAngle(value) end

			table[key] = value
		end
	})


	local w_loc = self.position.loc.object:transform(self.zone, self.world)

	body:setX(w_loc.x)
	body:setY(w_loc.y)


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
	local z = self.zone

	lg.push()

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
	self:draw_start()

	self.draw_funcs[self.lp.shape:getType()](self.lp.shape, self.position.loc, self.position.angle)

	-- Velocity vector.
	local velocity = Vector(self.lp.body:getLinearVelocity())

	if velocity:mag() > 0 then
		local loc = self.position.loc

		lg.setColor(color.FERN_GREEN); lg.setLine(1, 'smooth')

		velocity = velocity:transform(self.world, self.zone)
		lg.line(loc.x, loc.y, loc.x + velocity.x, loc.y + velocity.y)
		--Maybe a nice little arrowhead?
	end

	self:draw_end()
end


-- Table of drawing functions.
Body.draw_funcs = {

	circle = function(shape, loc, angle)
		local r = shape:getRadius()

		lg.setColor(color.TAN); lg.setLine(2, 'smooth')
		lg.circle('line', loc.x, loc.y, r, 50)
		lg.line(loc.x, loc.y, loc.x + r * math.cos(angle), loc.y - r * math.sin(angle))
	end,


	polygon = function(shape, loc, angle)
	end,


	edge = function(shape)
		local a = Vector()
		local b = Vector()

		lg.setColor(color.DARK_GRAY); lg.setLine(2, 'smooth')

		a.x, a.y, b.x, b.y = shape:getPoints()
		a:transform(self.world, self.zone)
		b:transform(self.world, self.zone)

		lg.line(a.x, a.y, b.x, b.y)
	end,


	chain = function(shape)
		lg.setColor(color.DARK_GRAY); lg.setLine(4, 'smooth')

		local a = Vector.transform(shape:getPoint(1), self.world, self.zone)
		for i = 2, shape:getVertexCount() do
			local b = Vector.transform(shape:getPoint(i), self.world, self.zone)

			lg.line(a.x, a.y, b.x, b.y)

			a = b
		end
	end

}
