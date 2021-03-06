local lp = require'love.physics'

require'classes.Class'
require'classes.Vector'


Actor = Class("Actor", nil, {
	name         = "_unnamed_actor",
	body         = nil,
	world        = nil,
	max_velocity = 3,      -- m/s
	max_accel    = 2,      -- m/s^2
	selected     = false,
	force        = Vector(),
	path         = { step = 0, moves = {} },


	-- Read-only.
	deflection   = 0,      -- Radians.  Difference between current and desired headings.


	-- The following are input as values on construction,
	-- but must be retrieved as function calls (e.g. actor.loc.x()).
	angle        = 0,
	loc          = { x = 0, y = 0 },  -- World coordinates.
})



--[[
====================================================================================
  Class utility.
====================================================================================
--]]

--[[
-- ===  CONSTRUCTOR  ===================================================================
--    Signature:  Actor:new ( [init] ) -> table
--  Description:  Instantiate a new actor object.
--   Parameters:  init : [table] : object containing initial parameters
--      Returns:  New Actor object table (in 'init', if provided).
-- =====================================================================================
--]]
function Actor:new ( init )
	local actor = init or {}

	Actor.super.new(self, actor)

	return actor:init()
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:init ( ) -> table
--  Description:  Apply default properties to an Actor object and create its sub-tables.
--      Returns:  Self (Actor object).
-- =====================================================================================
--]]
function Actor:init ( )
	if self.world and self.world.physicsWorld then
		self.body = lp.newBody(self.world.physicsWorld, nil, nil, 'dynamic')

		if type(self.loc.x) == 'number' then
			self.body:setX(self.loc.x)
		end
		self.loc.x = function() return self.body:getX() end

		if type(self.loc.y) == 'number' then
			self.body:setY(self.loc.y)
		end
		self.loc.y = function() return self.body:getY() end

		if type(self.angle) == 'number' then
			self.body:setAngle(self.angle)
		end
		self.angle = function() return self.body:getAngle() end

		self.body:isFixedRotation(false)


		local shape = lp.newCircleShape(1)

		local fixture = lp.newFixture(self.body, shape, 1)
		fixture:setUserData(self)
		fixture:setRestitution(0.9)
		fixture:setDensity(25.5)  -- kg/m^2
	end


	self.path  = { step = 0, moves = {} }
	self.force = Vector()


	return self
end



--[[
====================================================================================
  Pathing and maneuvering.
====================================================================================
--]]

--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:current_move ( ) -> table|nil
--  Description:  Obtain this actor's current movement command.
--      Returns:  Movement description object or nil if the move list is empty.
-- =====================================================================================
--]]
function Actor:current_move ( )
	return self.path.moves[self.path.step]
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:append_move ( move ) -> nil
--  Description:  Add a move to the end of this actor's move list.
--   Parameters:  move : [table|nil] : movement description object
-- =====================================================================================
--]]
function Actor:append_move ( move )
	table.insert(self.path.moves, move)

	if self.path.step == 0 then self.path.step = 1 end
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:set_moves ( [moves] ) -> nil
--  Description:  Replace this actor's move list with the given moves.
--   Parameters:  move : [table|nil] : movement description object or a list of such
--                                     objects
--         Note:  To clear the move list, pass no moves.
-- =====================================================================================
--]]
function Actor:set_moves ( moves )
	self.path.moves = moves and moves.type and {moves} or moves
	self.path.step = moves and 1 or 0
end


--[[
-- ===  CLASS FUNCTION  ================================================================
--    Signature:  Actor.line_to ( x, y ) -> table
--  Description:  Obtain a move describing a simple straight line from the current
--                position.
--   Parameters:  x : [number] : horizontal component of the destination point
--                y : [number] : vertical component of the destination point
--      Returns:  A movement description object.
-- =====================================================================================
--]]
function Actor.line_to ( x, y )
	return { type = 'line', dest = { x = x, y = y } }
end



--[[
====================================================================================
  Event handling.
====================================================================================
--]]

function Actor:update ( )
	local move = self:current_move()

	if not move then
		return
	end


	-- Get the next move when the current one is completed.
	if Vector.mag({x = move.dest.x - self.loc.x(), y = move.dest.y - self.loc.y()}) < 0.5 then
		self.path.step = self.path.step + 1
		move = self:current_move()

		-- Stop at the end of the move list.
		if not move then
			self.path.step = 0
			move = nil

			self.force.x = 0
			self.force.y = 0
			self.body:setLinearVelocity(0, 0)
			self.body:setAngularVelocity(0)

			return
		end
	end

	local dest_heading = Vector(move.dest.x - self.loc.x(), move.dest.y - self.loc.y())
	local dest_angle = math.atan2(dest_heading.y, dest_heading.x)

	self.deflection = dest_angle - self.angle()

	if (math.abs(self.deflection) > math.pi / 20) then
		self.body:setLinearVelocity(0,0)
		self.body:applyAngularImpulse(0.1 * (self.deflection / math.abs(self.deflection)))
	else	
		self.body:setAngularVelocity(0)
		self.body:setAngle(self.angle() + self.deflection)

		self.force = dest_heading:unit() * self.max_accel

		self.body:setLinearVelocity(self.force.x, self.force.y)
	end
end
