-- Zone class
require'classes/Class'


game.zones = {}
game.named_zones = {}


Zone = Class("Zone", nil, {
	name       = "_unnamed_zone",  -- Zone names beginning with an underscore are not registered.
	dimensions = { x = 100, y = 100 },
	location   = { lon = 0, lat = 0 },
	units      = {},
})


--[[
-- ===  CONSTRUCTOR  ===================================================================
--    Signature:  Zone:new ( [init] ) -> table
--  Description:  Instantiate a zone object.  Calls Zone:init() to register the zone
--                in the game environment.
--   Parameters:  init : [table] : object containing initial parameters
--      Returns:  New Zone object table (in 'init', if provided).
-- =====================================================================================
--]]
function Zone:new ( init )
	local zone = init or {}

	Zone.super.new(self, zone)

	return zone:init()
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:init ( [name] ) -> table
--  Description:  Register a zone in the game environment.
--   Parameters:      name : [string] : name of the zone
--      Returns:  Self (Zone object).
-- =====================================================================================
--]]
function Zone:init ( name )
	-- Register the zone in the game zone tables.
	name = name or self.name


	if name:byte() ~= string.byte('_') then
		game.named_zones[name] = self
	end

	game.zones[self] = name


	return self
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
		self.units[unit] = unit.loc
	end


	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Zone:remove_unit ( unit ) -> table
--  Description:  Remove the specified unit from this zone.
--   Parameters:  unit : [table|string] : unit identifier
--      Returns:  Resulting unit zone (i.e., 'nil').
-- =====================================================================================
--]]
function Zone:remove_unit ( unit )
	unit = Unit.lookup(unit)


	self.units[unit] = nil


	return nil
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
