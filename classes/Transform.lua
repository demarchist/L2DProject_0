local a = require'include.affine'

require'classes.Class'
require'classes.Vector'


Transform2D = Class("Transform2D", nil, {
	zone  = nil,
	loc   = Vector(0, 0),    -- location/center/translation
	rot   = 0,
	scale = Vector(1, 1),

	-- Read-only.
	matrix = a.trans(0, 0),  -- Dynamically generated.
})


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Transform2D:init ( ) -> table
--  Description:  Set meta-tables for a Transform2D object.
--      Returns:  Self (Transform2D object).
-- =====================================================================================
--]]
function Transform2D:init ( )
	local mt = getmetatable(self)
	local _index = mt.__index  -- Class table, since this immediately follows 'new()'.

	assert(type(_index) == 'table')


	mt.__index = function ( table, key )
		if key == 'matrix' then
			return a.trans(self.loc.x, self.loc.y) * a.rotate(self.rot) * a.scale(self.scale.x, self.scale.y)
		end

		return _index[key]
	end
end



--[[
====================================================================================
  DynamicTransform2D
  Transform2D with optional function closure accessors and mutators.
====================================================================================
--]]
DynamicTransform2D = Class("DynamicTransform2D", Transform2D, {
	get_loc   = nil,
	get_rot   = nil,
	get_scale = nil,

	set_loc   = nil,
	set_rot   = nil,
	set_scale = nil,
})


--[[
-- ===  METHOD  ========================================================================
--    Signature:  DynamicTransform2D:init ( ) -> table
--  Description:  Set meta-tables for a DynamicTransform2D object.
--      Returns:  Self (DynamicTransform2D object).
-- =====================================================================================
--]]
function DynamicTransform2D:init ( )
	local mt = getmetatable(self)
	local _index = mt.__index  -- Function inherited from Transform2D.
	local _newindex = mt.__newindex

	assert(type(_index) == 'function')


	mt.__index = function ( self, key )
		return self.get_loc   and key == 'loc'   and self:get_loc  ()
		    or self.get_rot   and key == 'rot'   and self:get_rot()
		    or self.get_scale and key == 'scale' and self:get_scale()
		    or _index(self, key)
	end


	mt.__newindex = function ( self, key, value )
		return self.set_loc   and key == 'loc'   and self:set_loc  (value)
		    or self.set_rot   and key == 'rot'   and self:set_rot(value)
		    or self.set_scale and key == 'scale' and self:set_scale(value)
		    or _newindex(self, key, value)
	end
end
