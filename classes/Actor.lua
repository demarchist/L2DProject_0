local lp = require'love.physics'
local lg = require'love.graphics'
local color = require'include.color'

require'classes.Class'
require'classes.Body'
require'classes.Vector'
require'classes.World'
require'include.color'


local font10 = lg.newFont(10)


Actor = Class("Actor", Body, {
	name         = "_unnamed_actor",
	max_velocity = 3,  -- m/s
	max_accel    = 2,  -- m/s^2
	selected     = false,
	force        = Vector(),
	path         = { step = 0, moves = {} },

	-- Read-only.
	deflection   = 0,  -- Radians.  Difference between current and desired headings.

	-- Superclass properties.
	lp           = { type = 'dynamic' },
})



--[[
====================================================================================
  Class utility.
====================================================================================
--]]

--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:init ( ) -> table
--  Description:  Apply default properties to an Actor object and create its sub-tables.
--      Returns:  Self (Actor object).
-- =====================================================================================
--]]
function Actor:init ( )
	self.lp.body:isFixedRotation(false)
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
		local pos = step <= 1 and self.transform.loc or self.path.moves[step-1].dest
		local path_moves = self.world:path(pos, move.dest:transform(self.world)) or {}

		self.path.moves[step] = nil

		local s = 0
		for i, m in ipairs(path_moves) do
			local clear = true

			if i > 1 and step + s > 2 then
				local m2 = self.path.moves[step + s - 2].dest
				local skippable = true

				self.world.physics:rayCast(m2.x, m2.y, m.x, m.y, function() skippable = false; return 0 end)

				if skippable then
					s = s - 1
					table.remove(self.path.moves, step + s)
				end
			end

			table.insert(self.path.moves, step + s, self.line_to(m:transform(self.zone)))
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
-- ===  METHOD  ========================================================================
--    Signature:  Actor:line_to ( x, y ) -> table
--  Description:  Obtain a move describing a simple straight line from the current
--                position.
--   Parameters:  location : [table] : Vector-like location representing the destination
--      Returns:  A movement description object.
-- =====================================================================================
--]]
function Actor:line_to ( location )
	location.zone = location.zone or self.parent
	return { type = 'line', dest = Vector(location) }
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Actor:path_to ( x, y ) -> table
--  Description:  Obtain a move describing a world-assisted path from the current
--                position.
--   Parameters:  position : [table] : Vector-like location representing the destination
--      Returns:  A movement description object.
-- =====================================================================================
--]]
function Actor:path_to ( location )
	location.zone = location.zone or self.parent
	return { type = 'path', dest = Vector(location) }
end



--[[
====================================================================================
  Event handling.
====================================================================================
--]]

function Actor:dist_to_next_move ( )
	return self._w.loc:distance_to(self:current_move().dest:transform(self.world))
end


function Actor:time_to_next_move ( )
	return self.body:getLinearVelocity() / self:dist_to_next_move()
end


function Actor:update ( )
	local lp_body = self.lp.body
	local move = self:current_move()


	-- Get the next move when the current one is completed.
	if move and self._w.loc:distance_to(move.dest:transform(self.world)) < 0.5 then
		self.path.step = self.path.step + 1
		move = self:current_move()
	end


	-- Stop at the end of the move list.
	if not move then
		self.path.step = 0
		move = nil

		self.force.x = 0
		self.force.y = 0
		lp_body:setLinearVelocity(0, 0)
		lp_body:setAngularVelocity(0)

		self.turning = false
		self.moving = false

		return
	end


	self:expand_current_move()


	local dest_heading = Vector(move.dest.x - self._w..x, move.dest.y - self._w.y)
	local dest_angle = math.atan2(dest_heading.y, dest_heading.x)

	self.deflection = dest_angle - self._w.rot

	if (math.abs(self.deflection) > math.pi / 20) then
		lp_body:setLinearVelocity(0,0)
		lp_body:applyAngularImpulse(0.1 * (self.deflection / math.abs(self.deflection)))
	else
		lp_body:setAngularVelocity(0)
		lp_body:setAngle(dest_angle)

		self.force = dest_heading:unit() * self.max_accel

		lp_body:setLinearVelocity(self.force.x, self.force.y)
	end
end


function Actor:draw( )
	Body.draw(self)

	self:draw_start() do

		local x, y, rot = self.transform.loc.x, self.transform.loc.y, self.transform.rot
		local shape = self.lp.shape
		local bb = { topleft = {}, bottomright = {} }


		bb.topleft.x, bb.topleft.y, bb.bottomright.x, bb.bottomright.y = shape:computeAABB(0, 0, rot, 1)


		-- Force vector.
		lg.setColor(color.FIRE_ENGINE_RED); lg.setLine(1, 'smooth')
		lg.line(x, y, x + self.force.x, y + self.force.y)


		-- Name tag.
		lg.setColor(color.PERIWINKLE); lg.setFont(font10)
		lg.print(self.name,
		         x - font10:getWidth(self.name) / 2,
		         y - math.abs(bb.topleft.y) - font10:getHeight() * 1.5,
		         0, 1, 1, 0, 0, 0, 0)


		-- Path to objective.
		if self:current_move() then
			-- Path lines.
			lg.setColor(color.PINK); lg.setLine(2, 'smooth')

			local src = Vector(x, y)
			for i, move in ipairs(self.path.moves) do
				if i >= self.path.step then
					local dest = move.dest

					lg.line(src.x, src.y, dest.x, dest.y)

					src = dest
				end
			end


			-- Path nodes.
			lg.setColor(color.WHITE); lg.setLine(2, 'smooth')

			for i, move in ipairs(self.path.moves) do
				if i >= self.path.step then
					lg.circle('fill', move.dest.x, move.dest.y, 3, 10)
				end
			end


			-- Direction to objective indicator.
			if shape:getType() == 'circle' then
				local r = shape:getRadius()

				lg.setColor(color.MAROON); lg.setLine(1, 'smooth')

				lg.line(x, j,
				x + r * math.cos(rot + self.deflection),
				y - r * math.sin(rot + self.deflection))
			end
		end


		-- Selection box.
		if self.selected then
			lg.setColor(color.WHITE)
			lg.rectangle('line',
			x - math.abs(bb.topleft.x), y - math.abs(bb.topleft.y),
			bb.bottomright.x - bb.topleft.x, bb.bottomright.y - bb.topleft.y)
		end

	end self:draw_end()
end
