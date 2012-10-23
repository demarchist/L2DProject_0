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
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_current_move ( ) -> nil
--  Description:  Update this actor's move list by expanding the current move, if
--                necessary.
-- =====================================================================================
--]]
function Actor:expand_current_move ( )
	local move = self:current_move()

	if move and move.type == 'path' then
		local x = self.path.step <= 1 and self.loc.x() or self.path.moves[self.path.step-1].dest.x
		local y = self.path.step <= 1 and self.loc.y() or self.path.moves[self.path.step-1].dest.y

		local path_moves = self.world:path(self.loc.x(), self.loc.y(), move.dest.x, move.dest.y) or {}

		for _, p in ipairs(path_moves) do
			p.x = p.x + (math.random() - 0.5) / 20  -- Jitter to prevent absolutely vertical movement.
		end

		self.path.moves[self.path.step] = nil

		for i, m in ipairs(path_moves) do
			table.insert(self.path.moves, self.path.step + i - 1, Actor.line_to(m.x, m.y))
		end
	end
end


--
--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:expand_all_moves ( ) -> nil
--  Description:  Expand out this actor's move list by resolving all complex moves.
-- =====================================================================================
--]]
function Actor:expand_all_moves ( )
	local s = self.path.step


	self.path.step = 1
	while self:current_move() do
		self:expand_current_move()
		self.path.step = self.path.step + 1
	end

	self.path.step = s
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
--    Signature:  Actor.line_to ( x, y ) -> table
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

function Actor:update ( )
	local move = self:current_move()

	if not move then
		return
	end

	self:expand_current_move()

	-- Get the next move when the current one is completed.
	if Vector.mag({x = move.dest.x - self.loc.x(), y = move.dest.y - self.loc.y()}) < 1 then
		self.path.step = self.path.step + 1
		move = self:current_move()
		self:expand_current_move()

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


	local dest_heading = (Vector(move.dest) - Vector(self.loc.x(), self.loc.y())):unit()
	local body_heading = Vector(math.cos(self.angle()), math.sin(self.angle()))
	self.deflection = math.atan2(body_heading.x * dest_heading.y - body_heading.y * dest_heading.x,
	                             body_heading * dest_heading)

	if (math.abs(self.deflection) > math.pi / 20) then
		self.body:applyAngularImpulse(0.1 * (self.deflection / math.abs(self.deflection)))
	else
		self.body:setAngularVelocity(0)
		self.body:setAngle(self.angle() + self.deflection)

		local velocity = Vector(self.body:getLinearVelocity())

		if velocity:mag() == 0 then
			self.force = dest_heading
		else
			self.force = dest_heading - velocity:unit()
		end

		self.force = (dest_heading + self.force:unit()):unit() * self.max_accel

		self.body:applyForce(self.force.x, self.force.y)
	end
end
