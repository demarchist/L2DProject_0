-- Root class of the object hierarchy.
Object = {
	_name = "Object",
	class = nil,
	super = nil,

	new   = function ( self, init, ... )
		init = init or {}

		if not getmetatable(init) then
			setmetatable(init, {__index = self})
		end

		if self.super then
			self.super:new(init, ...)
		end

		if self.init then
			self.init(init, ...)
		end

		return init
	end,

	is_a  = function ( self, class )
		if not class or not self.class then return false end

		if self == class or self.class == class or self.class._name == class then
			return true
		end

		if not self.class.super then return false end

		return self.class.super:is_a(class)
	end,
}
Object.class = Object


-- Create a class registry in the game object.
game = game or {}
game.classes = game.classes or {}
game.classes.Object = Object


--[[
-- ===  GLOBAL FUNCTION  ===============================================================
--    Signature:  Class ( name[, super, members] ) -> table
--  Description:  Instantiate a table that behaves like a class.
--   Parameters:     name : [string]    : name under which the new class will be
--                                        registered
--                  super : [table|nil] : class object from which the new class will
--                                        inherit
--                members : [table|nil] : table containing member functions and
--                                        properties (returned)
--      Returns:  Table object (modified from 'member', if provided) with basic class
--                functionality.
-- =====================================================================================
--]]
function Class ( name, super, members )
	super = super or Object
	members = members or {}

	members._name = name
	members.class = members
	members.super = super

	game.classes[name] = members

	return setmetatable(members, {
		__index = super,
		__call  = function ( self, init, ... )
			return self:new(init, ...)
		end
	})
end


--[[
-- ===  GLOBAL FUNCTION  ===============================================================
--    Signature:  is_a ( var, class ) -> boolean
--  Description:  Determine whether 'var' represents an object of type 'class'.
--   Parameters:    var : [any]   : variable to test
--                class : [table] : class object to test against
--      Returns:  The 'var' object if it is an object of the indicated class; otherwise,
--                false.
-- =====================================================================================
--]]
function is_a ( var, class )
	return type(var) == 'table' and type(var.is_a) == 'function' and var:is_a(class) and var
end
