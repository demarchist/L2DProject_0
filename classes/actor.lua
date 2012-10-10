--[[------------------------------------------------
	Actor Class
--]]------------------------------------------------

require('classes.Class')
require('classes.Vector')

Actor = Class("Actor")

function Actor:new ( init )
	local actor = init or {}

	actor.name = actor.name or 0
	actor.world = actor.world or 0
	actor.objPoint = nil
	actor.selected = false

	actor.body = love.physics.newBody(actor.world, actor.x, actor.y, 'dynamic')
	actor.shape = love.physics.newCircleShape(10)
	actor.fixture = love.physics.newFixture(actor.body, actor.shape, 1)
	actor.fixture:setUserData(actor)
	actor.fixture:setRestitution(0.9) --Unitless
	actor.body:isFixedRotation(false)
	actor.body:setAngle(0) --Radians
	actor.objTheta = 0 --Radians
	actor.nametagFont = love.graphics.newFont(10) -- the number denotes the font size

	Actor.super.new(self, actor)

	return(actor)
end

function Actor:getName()
	return(self.name)
end

function Actor:setObjective(x,y)
	if(self.objPoint == nil) then
		self.objPoint = Vector:new({x = x, y = y})
	else
		self.objPoint.x = x
		self.objPoint.y = y
	end
end

function Actor:getSelected()
	return(self.selected)
end

function Actor:setSelected(lSelected)
	self.selected = lSelected
end

function Actor:update()
	if(self.objPoint ~= nil) then
		if((math.abs(self.body:getX() - self.objPoint.x) > 5) or
		   (math.abs(self.body:getY() - self.objPoint.y) > 5)) then
			local bodyVector = Vector:new({x = self.body:getX(), y = self.body:getY()})
			local vectorToObj = self.objPoint - bodyVector
			local directionUnitVector = {x = math.cos(self.body:getAngle()), y = math.sin(self.body:getAngle())}

			self.objTheta = math.atan2(directionUnitVector.x * vectorToObj:unit().y - directionUnitVector.y * vectorToObj:unit().x,
			                           directionUnitVector.x * vectorToObj:unit().x + directionUnitVector.y * vectorToObj:unit().y)

			if(math.abs(self.objTheta) > math.pi / 20) then
				self.body:applyAngularImpulse(50 * (self.objTheta / math.abs(self.objTheta)))
				--Need to limit maximum angular velocity!
			else
				--I should really use torque to zero-out the angular velocity
				--so that the body is pointing in the right direction, but
				--for now I'll cheat.
				self.body:setAngularVelocity(0)
				self.body:setAngle(self.body:getAngle() + self.objTheta)

				--I'll need to limit maximum linear velocity.
				self.body:applyLinearImpulse(vectorToObj:unit().x, vectorToObj:unit().y)
			end
		else
			--This is where I need to properly apply force to counter the linear velocity.
			--For now I'll cheat
			self.body:setLinearVelocity(0,0) --comment this out for rubberband funtimes
			self.objPoint = nil
		end
	end
end

function Actor:draw()
	--grab numbers I'm going to use a lot
	local bodyAngle = self.body:getAngle()
	local shapeRadius = self.shape:getRadius()
	local bodyWorldPos = Vector:new({x = self.body:getX(), y = self.body:getY()})

	if(self.objPoint ~= nil) then
		--Line to objPoint
		love.graphics.setColor(255,192,203)
		love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, self.objPoint.x, self.objPoint.y)

		--Direction to objPoint indicator
		love.graphics.setColor(128,0,0)
		love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, bodyWorldPos.x + (shapeRadius * math.cos(bodyAngle + self.objTheta)), bodyWorldPos.y + (shapeRadius * math.sin(bodyAngle + self.objTheta)))
	end

	--Facing indicator
	love.graphics.setColor(210,180,140)
	love.graphics.circle("line", bodyWorldPos.x, bodyWorldPos.y, shapeRadius,50)
	love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, bodyWorldPos.x + (shapeRadius * math.cos(bodyAngle)), bodyWorldPos.y + (shapeRadius * math.sin(bodyAngle)))

	--Velocity Vector
	love.graphics.setColor(113, 188, 120) --Fern Green
	local linVelX, linVelY = self.body:getLinearVelocity()
	local linVel = Vector:new({x = linVelX, y = linVelY})
	linVel = linVel + bodyWorldPos
	love.graphics.line(bodyWorldPos.x, bodyWorldPos.y, linVel.x, linVel.y)
	--Maybe a nice little arrowhead?

	--NameTag
	love.graphics.setColor(153,153,255)
	love.graphics.setFont(self.nametagFont)
	love.graphics.print(self.name, bodyWorldPos.x - (self.nametagFont:getWidth(self.name)/2), bodyWorldPos.y - (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)

	--print objTheta
	--love.graphics.print(math.deg(self.objTheta), bodyWorldPos.x - (self.nametagFont:getWidth(math.deg(self.objTheta))/2), bodyWorldPos.y + (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)

	--Selection Box
	--love.graphics.print(tostring(self.selected), bodyWorldPos.x - (self.nametagFont:getWidth(tostring(self.selected)) / 2), bodyWorldPos.y + (self.nametagFont:getHeight()),0,1,1,0,0,0,0)
	if(self.selected == true) then
		love.graphics.setColor(255,255,255)
		local topLeftX, topLeftY, bottomRightX, bottomRightY = self.shape:computeAABB( 0, 0, self.body:getAngle(), 1 )
		love.graphics.rectangle("line", bodyWorldPos.x - math.abs(topLeftX), bodyWorldPos.y - math.abs(topLeftY), (bottomRightX - topLeftX), (bottomRightY - topLeftY))
	end

end
