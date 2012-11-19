local a = require'include.affine'

require'classes.Class'


Vector = Class("Vector", nil, {x = 0, y = 0})


local set_vector_operators  -- Meta-method definitions function.  Defined at end.



--[[
-- ===  CONSTRUCTOR  ===================================================================
--    Signature:  Vector:new ( [init_or_x, y, zone] ) -> table
--  Description:  Instantiate a vector object.
--   Parameters:  init_or_x : [table|number] : object containing initial parameters or a
--                                             value for the horizontal vector component
--                        y : [number]       : vertical component of the new vector
--                     zone : [table]        : reference Zone for this vector
--      Returns:  New Vector object table (in 'init', if provided).
--         Note:  If 'init_or_x' is an initial parameter table, the parameters must be
--                indexed at 'x' and 'y'.  The second arg is only considered when the
--                first is a number.
-- =====================================================================================
--]]
function Vector:new ( init_or_x, y, zone )
	local vector = type(init_or_x) == 'table' and init_or_x or {}


	vector.x = type(init_or_x) == 'number' and init_or_x or vector.x
	vector.y = type(init_or_x) == 'number' and y or vector.y
	vector.zone = zone


	Vector.super.new(self, vector)


	set_vector_operators(vector)


	return vector
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
--      Returns:  Vector object or table of components describing a vector of magnitude
--                1 in the same direction as this vector.
--         Note:  Works equally well as Vector.unit(v) for any object with keys 'x' and
--                'y'.  A simple table of components is returned if the input is not a
--                Vector object.
-- =====================================================================================
--]]
function Vector:unit ( )
	local mag = Vector.mag(self)

	if (type(self.is_a) == 'function' and self:is_a(Vector)) then
		return self / mag
	else
		return { x = self.x / mag, y = self.y / mag }
	end
end


--[[
-- ===  OPERATORS  =====================================================================
--  Description:  Perform basic element-wise operations on vectors.
--      Returns:  Number, boolean, or new Vector object with result of the operation.
-- =====================================================================================
--]]
set_vector_operators = function ( v )
	local mt = getmetatable(v)


	mt.__tostring = function ( v )
		return "(x=" .. v.x .. ", y=" .. v.y .. ")"
	end

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


--[[
====================================================================================
  Point-like methods.
====================================================================================
--]]
--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:distance_sq ( point_or_x[, y] ) -> number|nil
--  Description:  Compute the square of the distance from the point represented by this
--                vector to another point in the same Zone (any Vectors are treated as
--                points).
--   Parameters:  point_or_x : [table|number] : Vector-like table or x-coordinate to
--                                              which distance-squared is to be
--                                              calculated
--                         y : [number]       : y-coordinate to which distance-squared
--                                              is to be calculated
--      Returns:  Square of the distance between the two points.
-- =====================================================================================
--]]
function Vector:distance_sq ( point_or_x, y )
	local dy = self.y - (y or point_or_x.y)
	local dx = self.x - (y and point_or_x or point_or_x.x)

	return dx^2 + dy^2
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:distance_to ( point_or_x[, y] ) -> number|nil
--  Description:  Compute the distance from the point represented by this vector to
--                another point in the same Zone (any Vectors are treated as points).
--   Parameters:  point_or_x : [table|number] : Vector-like table or x-coordinate to
--                                              which distance is to be calculated
--                         y : [number]       : y-coordinate to which distance is to be
--                                              calculated
--      Returns:  Distance between the two points.
-- =====================================================================================
--]]
function Vector:distance_to ( point_or_x, y )
	return self:distance_sq(point_or_x, y) ^ 0.5
end


--[[
-- ===  METHOD  ========================================================================
--    Signature:  Vector:transform ( from[, to] ) -> table
--  Description:  Transform the representation of this Vector from one Zone to another.
--   Parameters:  from : [table] : Zone relative to which the Vector currently refers
--                  to : [table] : Zone to which this Vector is to be transformed
--      Returns:  New Vector object, with 'zone' field set to the destination Zone.
--        Notes:  If passed a single argument, the function will treat it as the
--                destination Zone and use 'self.zone' as the origin Zone.
--                Zones must have a common ancestor.
-- =====================================================================================
--]]
function Vector:transform ( from, to )
	local ret

	if not to then
		from, to = self.zone, from
	end


	if from == to then
		ret = Vector(self)
	else
		local ancestry = function ( zone )
			local ancestry = {}

			while zone do
				table.insert(ancestry, zone)
				zone = zone.parent or zone.zone
			end

			return ancestry
		end

		-- Build a relationship path between zones through the lowest common ancestor.
		local up = ancestry(from)
		local dn = ancestry(to)
		local pivot

		for f, fzone in ipairs(up) do
			for t, tzone in ipairs(dn) do
				if tzone == fzone then
					pivot = true
				end

				if pivot then
					dn[t] = nil
				end
			end

			if pivot then
				up[f] = nil
			end
		end

		if not pivot then
			return error("Vector:transform() error [Zones must be related].", 2)
		end


		-- Multipy transformations upwards from origin to ancestor and downwards (inverse) to destination.
		local m = a.trans(0, 0)
		for _, z in ipairs(up) do
			local t = z.transform
			m = a.trans(t.loc.x, t.loc.y) * a.rotate(t.rot) * a.scale(t.scale.x, t.scale.y) * m
		end

		local inv_m = a.trans(0, 0)
		for _, z in ipairs(dn) do
			local t = z.transform
			inv_m = a.trans(t.loc.x, t.loc.y) * a.rotate(t.rot) * a.scale(t.scale.x, t.scale.y) * inv_m
		end

		m = m * a.inverse(inv_m)


		-- Transform and set the return vector.
		ret = Vector(m(self.x, self.y))
	end


	ret.zone = to

	return ret
end
