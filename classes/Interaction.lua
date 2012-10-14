require'classes/Class'


Interaction = Class("Interaction", nil, {
	name    = "_unnamed_interaction",
	source  = nil,
	target  = nil,
	payload = function (self, target, source, ...) end,
})


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Interaction:apply ( [target, source, ...] ) -> table
--  Description:  Apply an Interaction's payload to a target.
--   Parameters:  target : [table] : object to which the payload will be applied
--                source : [table] : source object for the payload
--                   ... :         : additional arguments to pass to the payload
--      Returns:  Payload return value.
-- =====================================================================================
--]]
function Interaction:apply ( target, source, ... )
	target = target or self.target
	source = source or self.source

	return self:payload(target, source, ...)
end
