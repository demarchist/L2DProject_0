--[[------------------------------------------------
	Actor Class
--]]------------------------------------------------

require('classes.Class')
require('classes.Vector')
require('classes.World')
require('include.color')


Actor = Class("Actor")

function Actor:new ( init )
	local actor = init or {}

	actor.name = actor.name or 0
	actor.world = actor.world or 0
	actor.pathToObj = {Vector:new({x = actor.x, y = actor.y})}
	Actor.super.new(self, actor)

	return(actor:init())
end

function Actor:init()
	
	self.selected = false

	self.body = love.physics.newBody(self.world.physicsWorld, self.pathToObj[1].x, self.pathToObj[1].y, 'dynamic')
	self.shape = love.physics.newCircleShape(1)
	self.fixture = love.physics.newFixture(self.body, self.shape, 1)
	self.fixture:setUserData(self)
	self.fixture:setRestitution(0.9) --Unitless
	self.fixture:setDensity(25.5) --Kilograms per square meter
	self.body:isFixedRotation(false)
	self.body:setAngle(0) --Radians
	self.objTheta = 0 --Radians
	self.forceVector = Vector:new({x = 0, y = 0})
	self.nametagFont = love.graphics.newFont(10) -- the number denotes the font size

	self.maxAccel = 2 --20 --Meters per second per second
	self.maxVel = 3 --Meters per second

	return(self)
end

function Actor:getName()
	return(self.name)
end

function Actor:setObjective(x,y)
	self.pathToObj = self.world:path(self.body:getX(), self.body:getY(), x, y) or {}
end

function Actor:pushPathNode(x,y)
	if((#self.pathToObj > 0) and
	   (self.pathToObj[1].x == x) and
	   (self.pathToObj[1].y == y)) then
	   return
	end
	table.insert(self.pathToObj,Vector:new({x = x, y = y}))
end

function Actor:getSelected()
	return(self.selected)
end

function Actor:setSelected(lSelected)
	self.selected = lSelected
end

function Actor:update()
	if( #self.pathToObj > 0) then
		if((math.abs(self.body:getX() - self.pathToObj[1].x) > 1) or
		   (math.abs(self.body:getY() - self.pathToObj[1].y) > 1)) then
			local bodyVector = Vector:new({x = self.body:getX(), y = self.body:getY()})
			local vectorToObj = self.pathToObj[1] - bodyVector
			local directionUnitVector = {x = math.cos(self.body:getAngle()), y = math.sin(self.body:getAngle())}

			self.objTheta = math.atan2(directionUnitVector.x * vectorToObj:unit().y - directionUnitVector.y * vectorToObj:unit().x,
			                           directionUnitVector.x * vectorToObj:unit().x + directionUnitVector.y * vectorToObj:unit().y)

			if(math.abs(self.objTheta) > math.pi / 20) then
				self.body:applyAngularImpulse(0.1 * (self.objTheta / math.abs(self.objTheta)))
				--Need to limit maximum angular velocity!
			else
				--I should really use torque to zero-out the angular velocity
				--so that the body is pointing in the right direction, but
				--for now I'll cheat.
				self.body:setAngularVelocity(0)
				self.body:setAngle(self.body:getAngle() + self.objTheta)

				--I'll need to limit maximum linear velocity.
				local linVelX, linVelY = self.body:getLinearVelocity()
				local linVel = Vector:new({x = linVelX, y = linVelY}) --body local

				--local forceVector = nil
				if(linVel:mag() == 0) then
					self.forceVector = Vector(vectorToObj:unit())
				else
					self.forceVector = Vector(Vector(vectorToObj:unit()) - Vector(linVel:unit()))
				end

				self.forceVector = Vector((Vector(vectorToObj:unit()) + Vector(self.forceVector:unit())):unit()) * self.maxAccel

				--this is an "authentic" force-based way of doing it.
				--[[if(linVel:mag() >= self.maxVel) then
				--force Vector plus the scalar projection of the force vector on to the velocity vector
				self.forceVector = self.forceVector - ((Vector(linVel:unit()) * self.forceVector:dot(linVel)) / linVel:mag())
				end]]

				self.body:applyForce( self.forceVector.x, self.forceVector.y )

				--But doing this might actually be better because applying an impulse overwrites existing forces
				--self.forceVector = self.forceVector * self.maxAccel
				--self.body:applyLinearImpulse(self.forceVector.x, self.forceVector.y)
			end
		else
			if(#self.pathToObj > 0) then table.remove(self.pathToObj,1) end
			if(#self.pathToObj == 0) then
				self.forceVector.x = 0
				self.forceVector.y = 0
				self.body:setLinearVelocity(0,0) --Put the brakes on manually
				self.body:setAngularVelocity(0)
			end
		end
	end
end
--[[ saving this because there's some useful trig in there
function Actor:draw()
	--grab numbers I'm going to use a lot
	local bodyAngle = self.body:getAngle()
	local shapeRadius = self.shape:getRadius()
	local bodyWorldPos = Vector:new({x = self.body:getX(), y = self.body:getY()})

	if( #self.pathToObj > 0) then
		--Line to objPoint
		love.graphics.setColor(color.PINK)
		love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, self.pathToObj[1].x, self.pathToObj[1].y)

		--Direction to objPoint indicator
		love.graphics.setColor(color.MAROON)
		love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, bodyWorldPos.x + (shapeRadius * math.cos(bodyAngle + self.objTheta)), bodyWorldPos.y + (shapeRadius * math.sin(bodyAngle + self.objTheta)))
	end

	--Facing indicator
	love.graphics.setColor(color.TAN)
	love.graphics.circle("line", bodyWorldPos.x, bodyWorldPos.y, shapeRadius,50)
	love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, bodyWorldPos.x + (shapeRadius * math.cos(bodyAngle)), bodyWorldPos.y + (shapeRadius * math.sin(bodyAngle)))

	--Velocity Vector
	love.graphics.setColor(color.FERN_GREEN)
	local linVelX, linVelY = self.body:getLinearVelocity()
	local linVel = Vector:new({x = linVelX, y = linVelY})
	linVel = linVel + bodyWorldPos
	love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, linVel.x, linVel.y)
	--Maybe a nice little arrowhead?

	--NameTag
	love.graphics.setColor(color.PERIWINKLE)
	love.graphics.setFont(self.nametagFont)
	love.graphics.print(self.name, bodyWorldPos.x - (self.nametagFont:getWidth(self.name)/2), bodyWorldPos.y - (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)

	--print objTheta
	--love.graphics.print(math.deg(self.objTheta), bodyWorldPos.x - (self.nametagFont:getWidth(math.deg(self.objTheta))/2), bodyWorldPos.y + (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)

	--Selection Box
	--love.graphics.print(tostring(self.selected), bodyWorldPos.x - (self.nametagFont:getWidth(tostring(self.selected)) / 2), bodyWorldPos.y + (self.nametagFont:getHeight()),0,1,1,0,0,0,0)
	if(self.selected == true) then
		love.graphics.setColor(color.WHITE)
		local topLeftX, topLeftY, bottomRightX, bottomRightY = self.shape:computeAABB( 0, 0, self.body:getAngle(), 1 )
		love.graphics.rectangle("line", bodyWorldPos.x - math.abs(topLeftX), bodyWorldPos.y - math.abs(topLeftY), (bottomRightX - topLeftX), (bottomRightY - topLeftY))
	end

end
]]
