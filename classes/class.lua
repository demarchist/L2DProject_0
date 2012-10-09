-- Root class of the object hierarchy.
Object = {
	name  = "Object",
	class = nil,
	super = nil,

	new   = function ( self, init )
		init = init or {}
		return setmetatable(init, {__index = self})
	end,

	is_a  = function ( self, class )
		class = type(class) == 'table' and class.name or class

		local c = self.class
		while c do
			if c.name == class then
				return true
			end
			c = c.super
		end

		return false
	end,
}


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

	members.name  = name or ''
	members.class = members
	members.super = super

	game.classes[name] = members

	return setmetatable(members, {
		__index = super,
		__call  = function ( self, init )
			return self:new(init)
		end
	})
end
