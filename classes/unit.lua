-- Unit class.
require'classes/Class'
require'classes/Actor'


game.units = {}
game.named_units = {}


Unit = Class("Unit", Actor, {
	name          = "_unnamed_unit",  -- Unit names beginning with an underscore are not registered.
	max_hp        = 100,
	speed         = 1,
	damage        = 1,
	range         = 1,
	faction       = nil,
	zone          = nil,
	loc           = { x = 0, y = 0 },
	targets       = {},
	affinity_func = nil,
})


--[[
-- ===  CONSTRUCTOR  ===================================================================
--    Signature:  Unit:new ( [init] ) -> table
--  Description:  Instantiate a unit object.  Calls Unit:init() to register the unit
--                in the game environment.
--   Parameters:  init : [table] : object containing initial parameters
--      Returns:  New Unit object table (in 'init', if provided).
-- =====================================================================================
--]]
function Unit:new ( init )
	local unit = init or {}

	Unit.super.new(self, unit)

	return unit:init()
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:init ( [name, zone] ) -> table
--  Description:  Register a unit in the game environment.
--   Parameters:  name : [string]       : name of the unit
--                zone : [table|string] : zone in which to place the unit
--      Returns:  Self (Unit object).
-- =====================================================================================
--]]
function Unit:init ( name, zone )
	-- Register the unit in the game unit tables.
	name = name or self.name
	if name:byte() ~= string.byte('_') then
		game.named_units[name] = self
	end

	game.units[self] = name


	-- Associate unit with a zone.
	zone = zone or self.zone
	if zone then
		self:add_to_zone(zone)
	end


	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:set_zone ( [zone] ) -> table
--  Description:  Add a unit to the specified zone or remove it from its current zone.
--   Parameters:  zone : [table|string|nil] : zone in which to place the unit or 'nil'
--                                            to remove the unit from its current zone
--      Returns:  Self (Unit object).
-- =====================================================================================
--]]
function Unit:set_zone ( zone )
	zone = Zone.lookup(zone)


	if self.zone then
		self.zone = self.zone:remove_unit(self)
	end


	if zone then
		self.zone = zone:add_unit(self)
	end


	return self
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:primary_target ( ) -> table
--  Description:  Obtain the unit's primary target.
--      Returns:  Primary target (Unit object) and its affinity.
-- =====================================================================================
--]]
function Unit:primary_target ( )
	return self.targets[1], affinity
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:add_target ( unit[, affinity ] ) -> nil
--  Description:  Make this unit aware of a new target unit.
--   Parameters:      unit : [table|string] : target unit identifier
--                affinity : [number]       : this unit's starting affinity for the
--                                            target
-- =====================================================================================
--]]
function Unit:add_target ( unit, affinity )
	local target = {
		unit = Unit.lookup(unit),
		affinity = affinity or 0,
	}

	table.insert(self.targets, target)
	table.sort(self.targets, function ( a, b ) return a.affinity > b.affinity end)
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:remove_target ( unit ) -> nil
--  Description:  Remove this unit's awareness of another unit.
--   Parameters:  unit : [table|string] : target unit identifier
-- =====================================================================================
--]]
function Unit:remove_target ( unit )
	unit = Unit.lookup(unit)

	for i, target in ipairs(self.targets) do
		if target.unit == unit then
			table.remove(self.targets, i)
		end
	end
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:update_targets ( ) -> nil
--  Description:  Update the affinity values of the target and re-sort the target list.
--      Returns:  Primary target and its affinity, after updating.
-- =====================================================================================
--]]
function Unit:update_targets ( unit )
	unit = Unit.lookup(unit)


	for i, target in ipairs(self.targets) do
		if self.affinity_func then
			target.affinity = self.affinity_func(target.unit, target.affinity)
		end
	end


	table.sort(self.targets, function ( a, b ) return a.affinity > b.affinity end)


	return self.targets[1], affinity
end


--[[
-- ===  CLASS FUNCTION  ================================================================
--    Signature:  Unit.lookup ( unit ) -> table
--  Description:  Find a unit object by name or table address.
--   Parameters:  unit : [table|string] : unit identifier
--      Returns:  Matching unit object or 'nil' if not found.
-- =====================================================================================
--]]
function Unit.lookup ( unit )
	return type(unit) == 'table' and game.units[unit] and unit
	    or type(unit) == 'string' and game.named_units[unit]
	    or nil
end
