local lg = require'love.graphics'

require'classes.Class'


game.zones = {}
game.named_zones = {}


Zone = Class("Zone", nil, {
	name     = "_unnamed_zone",       -- Zone names beginning with an underscore are not globally registered.

	parent   = nil,
	center   = { x = 0, y = 0 },      -- Relative to parent.
	scale    = { x = 1, y = 1 },      -- Relative to parent.
	rotation = 0,                     -- Relative to parent.

	size     = { w = 100, h = 100 },
	units    = {},
})


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:init ( [name] ) -> table
--  Description:  Register a zone in the game environment.
--   Parameters:  parent    : [table]  : parent zone of the new Zone object
--                name      : [string] : name of the zone
--      Returns:  Self (Zone object).
-- =====================================================================================
--]]
function Zone:init ( parent, name )
	self.parent = Zone.lookup(parent) or self.parent
	self.name = name or self.name

	if string.sub(self.name, 1, 1) ~= '_' then
		game.named_zones[self.name] = self
	end

	game.zones[self] = self.name

	getmetatable(self).__tostring = function ( self )
		return "zone::" .. self.name
	end


	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:push ( ) -> nil
--  Description:  Push transforms from this zone to the parent World object.
-- =====================================================================================
--]]
function Zone:push ( )
	local z = self

	lg.push()

	while z and not is_a(z, World) do
		lg.scale(z.scale.x, z.scale.y)
		lg.rotate(z.rotation)
		lg.translate(z.center.x, z.center.y)

		z = z.parent
	end

	if not z then
		lg.pop()
		return error("Zone:push() error [No World associated with this Zone.].")
	end
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:add_unit ( unit[, loc] ) -> table
--  Description:  Insert the specified unit into this zone.
--   Parameters:  unit : [table|string] : unit identifier
--      Returns:  Resulting unit zone (i.e., 'self').
-- =====================================================================================
--]]
function Zone:add_unit ( unit )
	unit = Unit.lookup(unit)

	if unit then
		self.units[unit] = unit.position
	end

	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:remove_unit ( unit ) -> table|nil
--  Description:  Remove the specified unit from this zone.
--   Parameters:  unit : [table|string] : unit identifier
--      Returns:  Removed unit or 'nil' if zone is empty.
-- =====================================================================================
--]]
function Zone:remove_unit ( unit )
	unit = Unit.lookup(unit)

	if unit then
		self.units[unit] = nil
	end

	return unit
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:remove_all_units ( ) -> table
--  Description:  Remove all units from this zone.
--      Returns:  Self (Zone object with no units).
-- =====================================================================================
--]]
function Zone:remove_all_units ( )
	for unit in pairs(self.units) do
		self.units[unit] = nil
	end

	return self
end


--[[
-- ===  CLASS FUNCTION  ================================================================
--    Signature:  Zone.lookup ( unit ) -> table
--  Description:  Find a zone object by name or table address.
--   Parameters:  unit : [table|string] : zone identifier
--      Returns:  Matching zone object or 'nil' if not found.
-- =====================================================================================
--]]
function Zone.lookup ( zone )
	return type(zone) == 'table' and game.zones[zone] and zone
	    or type(zone) == 'string' and game.named_zones[zone]
	    or nil
end
