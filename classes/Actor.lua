local lp = require'love.physics'

require'classes.Class'
require'classes.Vector'
require'classes.World'
require'include.color'


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
--    Signature:  Actor:move_at_step ( ) -> table|nil
--  Description:  Obtain the movement command at the given step in this actor's move
--                list.
--   Parameters:  step : [number] : step index of move to be returned
--      Returns:  Movement description object or nil if no move exists at the given
--                step.
-- =====================================================================================
--]]
function Actor:move_at_step ( step )
	return self.path.moves[self.path.step]
end


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
--    Signature:  Actor:current_move ( ) -> table|nil
--  Description:  Obtain this actor's current movement command.
--      Returns:  Movement description object or nil if there is no 'next' move.
-- =====================================================================================
--]]
function Actor:next_move ( )
	return self.path.moves[self.path.step+1]
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
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_move_at_step ( step ) -> table
--  Description:  Update this actor's move list by expanding the specified move, if
--                necessary.
--   Parameters:  step - [number] - step index of move to be expanded
--      Returns:  First move of expanded list.
-- =====================================================================================
--]]
function Actor:expand_move_at_step ( step )
	local move = self.path.moves[step]

	if move and move.type == 'path' then
		local x = step <= 1 and self.loc.x() or self.path.moves[step-1].dest.x
		local y = step <= 1 and self.loc.y() or self.path.moves[step-1].dest.y
		local path_moves = self.world:path(self.loc.x(), self.loc.y(), move.dest.x, move.dest.y) or {}

		self.path.moves[step] = nil

		local s = 0
		for i, m in ipairs(path_moves) do
			local clear = true

			if i > 1 and step + s > 2 then
				local m2 = self.path.moves[step + s - 2].dest
				local clear = true

				self.world.physicsWorld:rayCast(m2.x, m2.y, m.x, m.y, function() clear = false; return 0 end)

				if clear then
					s = s - 1
					local dest = self.path.moves[step + s].dest
					table.remove(self.path.moves, step + s)
				end
			end

			table.insert(self.path.moves, step + s, self.line_to(m.x, m.y))
			s = s + 1
		end
	end

	return self:move_at_step(step);
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_current_move ( ) -> table
--  Description:  Update this actor's move list by expanding the current move, if
--                necessary.
--      Returns:  First step of the current move, after expansion.
-- =====================================================================================
--]]
function Actor:expand_current_move ( )
	return self:expand_move_at_step(self.path.step)
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_next_move ( ) -> table
--  Description:  Update this actor's move list by expanding the next move, if
--                necessary.
--      Returns:  First step of next move, after expansion.
-- =====================================================================================
--]]
function Actor:expand_next_move ( )
	return self:expand_move_at_step(self.path.step + 1)
end


--
--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_all_moves ( ) -> nil
--  Description:  Expand out this actor's move list by resolving all complex moves.
-- =====================================================================================
--]]
function Actor:expand_all_moves ( )
	local s = 1

	while self:move_at_step(s) do
		self:expand_move_at_step(s)
		s = s + 1
	end
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
-- ===  CLASS FUNCTION  ================================================================
--    Signature:  Actor.path_to ( x, y ) -> table
--  Description:  Obtain a move describing a world-assisted path from the current
--                position.
--   Parameters:  x : [number] : horizontal component of the destination point
--                y : [number] : vertical component of the destination point
--      Returns:  A movement description object.
-- =====================================================================================
--]]
function Actor.path_to ( x, y )
	return { type = 'path', dest = { x = x, y = y } }
end


--[[
====================================================================================
  Event handling.
====================================================================================
--]]


function Actor:dist_to_next_move ( )
	local move = self:current_move()
	return Vector.mag({x = move.dest.x - self.loc.x(), y = move.dest.y - self.loc.y()})
end


function Actor:time_to_next_move ( )
	return self.body:getLinearVelocity() / self:dist_to_next_move()
end


function Actor:update ( )
	local move = self:current_move()

	-- Stop at the end of the move list.
	if not move then
		self.path.step = 0

		self.force.x = 0
		self.force.y = 0

		self.body:setLinearVelocity(0, 0)
		self.body:setAngularVelocity(0)

		self.turning = false
		self.moving = false

		return
	end

	self:expand_current_move()


	local dest_heading = Vector(move.dest.x - self.loc.x(), move.dest.y - self.loc.y())
	local dest_angle = math.atan2(dest_heading.y, dest_heading.x)

	self.deflection = dest_angle - self.angle()


	local time_to_next = self:time_to_next_move()
	local next_move = self:next_move()

	if false and next_move and not self.turning and time_to_next < 1 then
		local next_heading = Vector(next_move.dest.x - move.dest.x, next_move.dest.y - move.dest.y)
		local next_angle = math.atan2(next_heading.y, next_heading.x)
		local next_deflection = next_angle - self.angle()

		if time_to_next < 1 then
			self.body:applyAngularImpulse(next_deflection * self.body:getMass())
			self.turning = true
		end
	end


	-- Get the next move when the current one is completed.
	if not self.moving or self:dist_to_next_move() < 0.5 then
		self.path.step = self.path.step + 1
		self.turning = false


		self.body:setAngle(dest_angle)
		self.force = dest_heading:unit() * self.max_accel
		self.body:setLinearVelocity(self.force.x, self.force.y)
		self.moving = true
	end
end

function Actor:update ( )
	local move = self:current_move()

	-- Get the next move when the current one is completed.
	if move and Vector.mag({x = move.dest.x - self.loc.x(), y = move.dest.y - self.loc.y()}) < 0.5 then
		self.path.step = self.path.step + 1
		move = self:current_move()
	end

	-- Stop at the end of the move list.
	if not move then
		self.path.step = 0
		move = nil

		self.force.x = 0
		self.force.y = 0
		self.body:setLinearVelocity(0, 0)
		self.body:setAngularVelocity(0)

		self.turning = false
		self.moving = false

		return
	end

	self:expand_current_move()

	local dest_heading = Vector(move.dest.x - self.loc.x(), move.dest.y - self.loc.y())
	local dest_angle = math.atan2(dest_heading.y, dest_heading.x)

	self.deflection = dest_angle - self.angle()

	if (math.abs(self.deflection) > math.pi / 20) then
		self.body:setLinearVelocity(0,0)
		self.body:applyAngularImpulse(0.1 * (self.deflection / math.abs(self.deflection)))
	else
		self.body:setAngularVelocity(0)
		self.body:setAngle(dest_angle)

		self.force = dest_heading:unit() * self.max_accel

		self.body:setLinearVelocity(self.force.x, self.force.y)
	end
end
