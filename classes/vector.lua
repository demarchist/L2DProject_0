require'classes/Class'


Vector = Class("Vector")

local set_vector_operators  -- Defined at end.



--[[
-- ===  CONSTRUCTOR  ===================================================================
--    Signature:  Vector:new ( [init] ) -> table
--  Description:  Instantiate a vector object.
--   Parameters:  init : [table] : object containing initial parameters
--                     - x : [number] : horizontal component of the new vector
--                     - y : [number] : vertical component of the new vector
--      Returns:  New Vector object table (in 'init', if provided).
-- =====================================================================================
--]]
function Vector:new ( init )
	init = init or {}

	init.x = init.x or 0
	init.y = init.y or 0

	Vector.super.new(self, init)
	set_vector_operators(init)

	return init
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:dot ( v ) -> number
--  Description:  Compute the dot product of this vector with another.
--   Parameters:  v : [table] : second (vector-like) object
--      Returns:  Value of the dot product.
--         Note:  Works equally well as Vector.dot(v1, v2) for any objects with keys 'x'
--                and 'y'.
-- =====================================================================================
--]]
function Vector:dot ( v )
	return self.x * v.x + self.y * v.y
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:mag ( ) -> number
--  Description:  Compute the magnitude of this vector.
--      Returns:  Magnitude of the vector.
--         Note:  Works equally well as Vector.mag(v) for any object with keys 'x' and
--                'y'.
-- =====================================================================================
--]]
function Vector:mag ( )
	return math.sqrt(Vector.dot(self, self))
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:unit ( ) -> table
--  Description:  Compute a unit vector in the same direction as this vector.
--      Returns:  Table of components forming a vector of magnitude 1 in the same
--                direction as this vector.
--         Note:  Works equally well as Vector.unit(v) for any object with keys 'x' and
--                'y'.  Pass return to Vector:new() to create a full Vector object.
-- =====================================================================================
--]]
function Vector:unit ( )
	local mag = Vector.mag(self)

	return { x = self.x / mag, y = self.y / mag }
end



--[[
-- ===  OPERATORS  =====================================================================
--  Description:  Perform basic element-wise operations on vectors.
--      Returns:  Number, boolean, or new Vector object with result of the operation.
-- =====================================================================================
--]]
set_vector_operators = function ( v )
	mt = getmetatable(v)

	mt.__eq = function ( v, w )
		return v.x == w.x and v.y == w.y
	end

	mt.__unm = function ( v )
		return Vector{ x = -v.x, y = -v.y }
	end

	mt.__add = function ( v, w )
		return Vector{ x = v.x + w.x, y = v.y + w.y }
	end

	mt.__sub = function ( v, w )
		return Vector{ x = v.x - w.x, y = v.y - w.y }
	end

	mt.__mul = function ( v, v_or_s )
		if type(v_or_s) == 'number' then
			return Vector{ x = v.x * v_or_s, y = v.y * v_or_s }
		else
			return v:dot(v_or_s)
		end
	end

	mt.__div = function ( v, s )
		if type(s) == 'number' then
			return Vector{ x = v.x / s, y = v.y / s }
		else
			error("Vector divisor must be scalar.")
		end
	end
end



--[[  Example:

[jjs@jjs]$ lua -i classes/vector.lua
Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
> v = Vector{x=3, y=4}
> w = Vector{x=6, y=8}
> = v.dot
function: 0x100109880
> = v:dot(w)
50
> = Vector.dot(v, w)
50
> = Vector.dot({x=3, y=5}, {x=4, y=6})
42
> = v:mag()
5
> = w:mag()
10
> w0 = w:unit()
> table.foreach(w0, print)
y       0.8
x       0.6
> = w0.x
0.6
> = w0.mag                 -- Vector:unit() returns a simple table, not a Vector.
nil
> w0 = Vector(w:unit())    -- The result of Vector:unit() can be passed to Vector:new().
> table.foreach(w0, print)
y       0.8
x       0.6
> = w0:mag()
1
> = w == v
false
> table.foreach(-v, print)
y       -4
x       -3
> table.foreach(v + w, print)
y       12
x       9
> table.foreach(w - v, print)
y       4
x       3
> table.foreach(v * 2, print)
y       8
x       6
> = v * w
50
> table.foreach(v / 2, print)
y       2
x       1.5
> table.foreach(v/v:mag(), print)
y       0.8
x       0.6
> = v:is_a('Vector')
true
> = v:is_a(Object)
true
> = v:is_a('Dog')
false
> ^D

--]]
