require'classes.Class'
require'classes.Vector'
require'classes.Zone'
require'classes.Actor'


game.units = {}
game.named_units = {}


Unit = Class("Unit", Actor, {
	name    = "_unnamed_unit",   -- Unit names beginning with an underscore
	max_hp  = 100,               --            are not globally registered.
	cur_hp  = 100,
	speed   = 1,
	sight   = 0,
	faction = nil,
	targets = {},
	status  = 'normal',          -- Dynamically generated on field access.
})



--[[
====================================================================================
  Class utility.
====================================================================================
--]]
--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:init ( [name, zone] ) -> table
--  Description:  Register a unit in the game environment.
--   Parameters:  zone : [table|string] : zone in which to place the unit
--      Returns:  Self (Unit object).
-- =====================================================================================
--]]
function Unit:init ( name, zone )
	-- Register the unit in the game unit tables.
	if self.name:sub(1, 1) ~= '_' then
		game.named_units[self.name] = self
	end

	game.units[self] = self.name


	-- Associate the unit with a zone.
	zone = zone or self.zone
	if zone then
		self:set_zone(zone)
	end


	-- Create affinity table.
	self.affinities = {}
	self.affinity_func = self.affinity_func or function ( self, unit, old_affinity )
		return old_affinity
	end


	-- Create a sight zone, if applicable.
	self:set_sight(self.sight)


	-- Allow state to be dynamically queried as a table field.
	self.status = { _self = self }
	setmetatable(self.status, {
		__tostring = function( table ) return table._self:get_status() end,
	})


	return self
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



--[[
====================================================================================
  Internal properties.
====================================================================================
--]]

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
--    Signature:  Unit:set_sight ( [radius] ) -> table|nil
--  Description:  Set the unit's sight radius and create a Zone to represent it.
--   Parameters:  radius : [number|nil] : new sight radius or nil to only create the
--                                        zone using the unit's current radius
--      Returns:  New sight zone (Zone object or nil).
--         Note:  To remove the sight zone, pass a radius of zero.
-- =====================================================================================
--]]
function Unit:set_sight ( radius )
	radius = radius or self.sight or 0

	if radius == 0 then
		self.sight_zone = nil
		return
	end

	self.sight = radius
	self.sight_zone = Zone {
		name   = "_" .. self.name .. "__sight_zone",
		parent = self,
		size = {
			w = 2 * radius,
			h = 2 * radius,
		},
	}
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:get_status ( ) -> string
--  Description:  Obtain the unit's current status.
--      Returns:  Current status string.
--         Note:  The Unit.status field uses this to set its value on access,
--                so there is generally no need to call this function directly.
-- =====================================================================================
--]]
function Unit:get_status ( )
	return self.cur_hp <= 0 and 'dead' or 'normal'
end



--[[
====================================================================================
  Target awareness.
====================================================================================
--]]

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
	unit = Unit.lookup(unit)


	if not self.affinities[unit] then
		table.insert(self.targets, unit)
	end


	self.affinities[unit] = affinity or true
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

	self.affinities[unit] = false  -- Pending removal of the target on next update_affinities().
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:get_target_affinity ( unit ) -> number|bool
--  Description:  Obtain the affinity value of this unit for one of its targets.
--   Parameters:  unit : [table|string] : target unit identifier
--      Returns:  Affinity value for the given target (or 'false' if this unit is
--                unaware of it).
-- =====================================================================================
--]]
function Unit:get_target_affinity ( unit )
	unit = Unit.lookup(unit)

	return self.affinities[unit]
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:set_target_affinity ( unit, number ) -> number|bool
--  Description:  Set the affinity value of this unit for one of its targets.  Fails if
--                the unit is not aware of the target.
--   Parameters:  unit     : [table|string] : target unit identifier
--                affinity : [number|func]  : target's new affinity value or a function
--                                            to apply to its current affinity value
--      Returns:  New affinity value for the given target (or 'false' if this unit is
--                unaware of it).
-- =====================================================================================
--]]
function Unit:set_target_affinity ( unit, affinity )
	unit = Unit.lookup(unit)


	if not self.affinities[unit] then
		return false
	end


	if type(affinity) == 'function' then
		self.affinities[unit] = affinity(self.affinities[unit])
	else
		self.affinities[unit] = affinity
	end


	return self.affinities[unit]
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:primary_target ( ) -> table, number
--  Description:  Obtain the unit's primary target.
--      Returns:  Primary target object and its affinity.
-- =====================================================================================
--]]
function Unit:primary_target ( )
	return self.targets[1], self.affinities[self.targets[1]]
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:scan_visible ( ) -> nil
--  Description:  Update the unit's sight zone and add new targets to its awareness.
--         Note:  New targets are added with affinity value 'true', signifying awareness
--                but no affinity.
-- =====================================================================================
--]]
function Unit:scan_visible ( )
	self.sight_zone:remove_all_units()

	for unit, p in pairs(self.zone.units) do
		if p:distance_to(self.position.object) <= self.sight then
			if not self.affinities[unit] then self:add_target(unit) end

			self.sight_zone:add_unit(unit)
		end
	end
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:update_affinities ( ) -> table, number
--  Description:  Update the affinity values of the unit's targets and re-order the
--                target list based on the new affinity values.
--      Returns:  Primary target object and its affinity, after updating.
-- =====================================================================================
--]]
function Unit:update_affinities ( )
	while table.remove(self.targets) do end


	for unit, affinity in pairs(self.affinities) do
		if affinity == false then
			self.affinities[unit] = nil  -- Final removal of a 'removed' target.

		else
			if self.affinity_func then
				self.affinities[unit] = self:affinity_func(unit, self.affinities[unit])
			end

			table.insert(self.targets, unit)
		end
	end


	table.sort(self.targets, function ( a, b )
		if type(b) ~= 'number' then return a end
		if type(a) ~= 'number' then return b end
		return self.affinities[a] > self.affinities[b]
	end)


	return self.targets[1], self.affinities[self.targets[1]]
end


--[[
====================================================================================
  Received effects.
====================================================================================
--]]

--[[
-- ===  METHOD  ========================================================================
--    Signature:  Unit:damage ( value ) -> nil
--  Description:  Reduce this unit's hitpoints by the specified amount.
--   Parameters:  value : [number] : base damage to incur
-- =====================================================================================
--]]
function Unit:damage ( value )
	self.cur_hp = self.cur_hp - value
end
