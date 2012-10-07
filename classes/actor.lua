--[[------------------------------------------------
	Actor Class
--]]------------------------------------------------

Actor = {}

function Actor:new(name, world, x, y)
	local object = {
		name = name,
		world = world,
		objPoint = {x = x, y = y},
		selected = false
	}

	object.body = love.physics.newBody(world, x, y, "dynamic")
	object.shape = love.physics.newCircleShape(10)
	object.fixture = love.physics.newFixture(object.body,object.shape,1)
	object.fixture:setUserData(self)
	object.fixture:setRestitution(0.9)
	object.body:isFixedRotation(false)
	object.body:setAngle(math.pi/4)
	object.objTheta = 0
	object.nametagFont = love.graphics.newFont(10) -- the number denotes the font size

	setmetatable(object, { __index = Actor })  -- Inheritance

	return(object)
end

function Actor:getName()
	return(self.name)
end

function Actor:getBody()
	return(body)
end

function Actor:setObjective(x,y)
	self.objPoint.x = x
	self.objPoint.y = y
end

function Actor:setSelected(lSelected)
	self.selected = lSelected
end

function Actor:update()
	if((math.abs(self.body:getX() - self.objPoint.x) > 5) or
	   (math.abs(self.body:getY() - self.objPoint.y) > 5)) then
		local vectorToObj = {x = self.objPoint.x - self.body:getX(), y = self.objPoint.y - self.body:getY()}
		local magnitude = math.sqrt((math.pow(vectorToObj.x,2)) + (math.pow(vectorToObj.y,2)))
		local unitVector = {x = vectorToObj.x / math.sqrt(magnitude), y = vectorToObj.y / math.sqrt(magnitude)}
		local directionUnitVector = {x = math.cos(self.body:getAngle()), y = math.sin(self.body:getAngle())}
		self.objTheta = math.atan2(directionUnitVector.x * unitVector.y - directionUnitVector.y * unitVector.x, directionUnitVector.x * unitVector.x + directionUnitVector.y * unitVector.y)
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
		   	self.body:applyLinearImpulse(unitVector.x, unitVector.y)
		end
	else
		--This is where I need to properly apply force to counter the linear velocity.
		--For now I'll cheat
		self.body:setLinearVelocity(0,0) --comment this out for rubberband funtimes
	end
end

function Actor:draw()
	--grab numbers I'm going to use a lot
	local bodyAngle = self.body:getAngle()
	local shapeRadius = self.shape:getRadius()
	local bodyWorldX = self.body:getX()
	local bodyWorldY = self.body:getY()

	--Line to objPoint
	love.graphics.setColor(255,192,203)
	love.graphics.line(bodyWorldX, bodyWorldY, self.objPoint.x, self.objPoint.y)

	--Direction to objPoint indicator
	love.graphics.setColor(128,0,0)
	love.graphics.line(bodyWorldX, bodyWorldY, bodyWorldX + (shapeRadius * math.cos(bodyAngle + self.objTheta)), bodyWorldY + (shapeRadius * math.sin(bodyAngle + self.objTheta)))

	--Facing indicator
	love.graphics.setColor(210,180,140)
	love.graphics.circle("line", bodyWorldX, bodyWorldY, shapeRadius,50)
	love.graphics.line(bodyWorldX, bodyWorldY, bodyWorldX + (shapeRadius * math.cos(bodyAngle)), bodyWorldY + (shapeRadius * math.sin(bodyAngle)))

	--NameTag
	love.graphics.setColor(153,153,255)
	love.graphics.setFont(self.nametagFont)
	love.graphics.print(self.name, bodyWorldX - (self.nametagFont:getWidth(self.name)/2), bodyWorldY - (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)

	--print objTheta
	--love.graphics.print(math.deg(self.objTheta), bodyWorldX - (self.nametagFont:getWidth(math.deg(self.objTheta))/2), bodyWorldY + (self.nametagFont:getHeight() + 15),0,1,1,0,0,0,0)
	
	--Selection Box
	love.graphics.print(tostring(self.selected), bodyWorldX - (self.nametagFont:getWidth(tostring(self.selected))/2), bodyWorldY + (self.nametagFont:getHeight()),0,1,1,0,0,0,0)
	if(self.selected == true) then
		
		local topLeftX, topLeftY, bottomRightX, bottomRightY = self.shape:computeAABB( 0, 0, self.body:getAngle(), 1 )
		love.graphics.rectangle("line", topLeftX, topLeftY, (bottomRightX - topLeftX), (bottomRightY - topLeftY))
	end
	
end
