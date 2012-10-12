require'classes/Class'
require'classes/Interaction'


Attack = Class("Attack", Interaction, {
	name     = "_unnamed_attack",
	strength = 0,
	payload  = function ( self, target )
		target:damage(self.strength)
	end
})


--[[

Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
> u = Unit()
> = u.status
normal
> = u.cur_hp
100
> require 'classes/Attack'
> a = Attack()
> a.strength = 40
> a.target = u
> a:apply()
> = u.status
normal
> = u.cur_hp
60
> a:apply()
> = u.status
normal
> a:apply()
> = u.status
dead
> ^D

--]]
