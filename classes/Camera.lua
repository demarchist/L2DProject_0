--[[
-- ===  METHOD  ========================================================================
--    Camera Class
-- =====================================================================================
--]]

require('classes.Class')
require('classes.Vector')

Camera = Class("Camera")

function Camera:new ( init )
	local camera = init or {}

	camera.targetWorld = init.world or nil
	camera.pxPerUnit = init.pxPerUnit or 1
	camera.targetEntity = init.targetEntity or nil

	camera.targetCoordinates = Vector:new({x = 0, y = 0})
	camera.drawDebugPrimitives = false

	camera.worldAperture = {lowerBound = Vector:new({x = 0, y = 0}), upperBound = Vector:new({x = 0, y = 0})}
	camera.selectBox = {toggle = false, x1 = 0, y1 = 0, x2 = 0, y2 = 0}
	camera.queryFixtures = nil

	Camera.super.new(self, camera)

	camera:calcWorldAperture()

	return(camera)
end

function Camera:setTargetWorld(targetWorld)
	if(targetWorld == nil) then return(false) end
	self.targetWorld = targetWorld
	return(true)
end

function Camera:setTargetCoordinates(x, y)
	self.targetCoordinates.x = x
	self.targetCoordinates.y = y
	self:calcWorldAperture()
end

function Camera:setTargetActor(targetEntity)
	if(targetEntity == nil) then return(false) end
	self.targetEntity = targetEntity
	return(true)
end

function Camera:calcWorldAperture()
	if(love.graphics.isCreated() == false) then return(false) end
	if(self.worldAperture == nil) then return(false) end
	if(self.pxPerUnit <= 0) then return(false) end

	self.worldAperture.topLeftX = (self.targetCoordinates.x - ((love.graphics.getWidth() / 2) * (1 / self.pxPerUnit)))
	self.worldAperture.topLeftY =  (self.targetCoordinates.y - ((love.graphics.getHeight() / 2) * (1 / self.pxPerUnit)))

	self.worldAperture.bottomRightX = (self.targetCoordinates.x + ((love.graphics.getWidth() / 2) * (1 / self.pxPerUnit)))
	self.worldAperture.bottomRightY = (self.targetCoordinates.y + ((love.graphics.getHeight() / 2) * (1 / self.pxPerUnit)))
end

function Camera:worldPosToCameraPos(worldPosX, worldPosY)
	local DestR = Vector:new({x = 0, y = 0})

	DestR.x =  ((worldPosX - self.targetCoordinates.x) * self.pxPerUnit) + (love.graphics.getWidth() / 2)
	DestR.y = -((worldPosY - self.targetCoordinates.y) * self.pxPerUnit) + (love.graphics.getHeight() / 2)

	return(DestR)
end

function Camera:camPosToWorldPos(camX, camY)
	camX = self.targetCoordinates.x + ((camX - (love.graphics.getWidth() / 2)) / self.pxPerUnit)
	camY = self.targetCoordinates.y - ((camY - (love.graphics.getHeight() / 2)) / self.pxPerUnit)
	return camX, camY
end

function Camera:update(dt)
	if(self.selectBox.toggle == true) then
		if love.graphics.hasFocus() then
			self.selectBox.x2 = love.mouse.getX()
			self.selectBox.y2 = love.mouse.getY()
		end
	end
end

function Camera:mousepressed(x, y, button)
	if(button == 'l') then
		self.selectBox.toggle = true
		self.selectBox.x1 = x
		self.selectBox.y1 = y
	elseif(button == 'wu') then
		self.pxPerUnit = self.pxPerUnit + 1
		self:calcWorldAperture()
	elseif(button == 'wd') then
		if(self.pxPerUnit > 1) then
			self.pxPerUnit = self.pxPerUnit - 1
		end
		self:calcWorldAperture()
	end
end

function Camera:mousereleased(x, y, button)

	if(button == "l") then
		self.selectBox.toggle = false
		self.selectBox.x2 = x
		self.selectBox.y2 = y

		local lTopLeftX, lTopLeftY = self:camPosToWorldPos(math.min(self.selectBox.x1, self.selectBox.x2), math.max(self.selectBox.y1,self.selectBox.y2))
		local lBottomRightX, lBottomRightY = self:camPosToWorldPos(math.max(self.selectBox.x1, self.selectBox.x2), math.min(self.selectBox.y1,self.selectBox.y2))

		local lBodies = self.targetWorld:getBodyList()
		for k, lBody in pairs(lBodies) do
			if(lBody ~= nil) then
				local lFixtures = lBody:getFixtureList()
				for i, lFixture in pairs(lFixtures) do
					local lActor = lFixture:getUserData()
					if(lActor ~= nil) then
						lActor.selected = false
					end
				end
			end
		end

		self.queryFixtures = {}
		self.targetWorld:queryBoundingBox(lTopLeftX, lTopLeftY, lBottomRightX, lBottomRightY, self.bbQueryCallback)

		for k, lFixture in pairs(self.queryFixtures) do
			if(lFixture ~= nil) then
				local lActor = lFixture:getUserData()
				if(lActor ~= nil) then
					lActor.selected = true
				end
			end
		end
	elseif(button == "r") then
		local lBodies = self.targetWorld:getBodyList()
		for k, lBody in pairs(lBodies) do
			if(lBody ~= nil) then
				local lFixtures = lBody:getFixtureList()
				for i, lFixture in pairs(lFixtures) do
					local lActor = lFixture:getUserData()
					if(lActor ~= nil) then
						if(lActor.selected == true) then
							local worldX, worldY = self:camPosToWorldPos(x, y)
							lActor:setObjective(worldX, worldY)
						end

					end
				end
			end
		end
	end
end

function Camera:render()
	if(self.targetEntity ~= nil) then
		local bodyWorldPos = Vector:new({x = self.targetEntity:getBody():getX(), y = self.targetEntity:getBody():getY()})
		self.targetCoordinates.x = bodyWorldPos.x
		self.targetCoordinates.y = bodyWorldPos.y
		self.calcWorldAperture()
	end

	--bound the camera

	self.queryFixtures = {} --This table will be filled by the query callback function, so clear it out in advance.
	self.targetWorld:queryBoundingBox(self.worldAperture.topLeftX, self.worldAperture.topLeftY, self.worldAperture.bottomRightX, self.worldAperture.bottomRightY, self.bbQueryCallback)

	for k, lFixture in pairs(self.queryFixtures) do
		if(lFixture ~= nil) then
			local lShape = lFixture:getShape()
			local lBody = lFixture:getBody()
			
			if((lShape ~= nil) and (lBody ~= nil)) then
				local bodyAngle = lBody:getAngle()
				local bodyCamPos = self:worldPosToCameraPos(lBody:getX(), lBody:getY())

				if(lShape:getType() == 'circle') then
					local shapeRadius = lShape:getRadius() * self.pxPerUnit

					love.graphics.setColor(210,180,140)
					love.graphics.setLine(2, 'smooth')
					love.graphics.circle("line", bodyCamPos.x, bodyCamPos.y, shapeRadius, 50)
					love.graphics.line(bodyCamPos.x, bodyCamPos.y, (bodyCamPos.x + (shapeRadius * math.cos(bodyAngle))), (bodyCamPos.y - (shapeRadius * math.sin(bodyAngle))))
				elseif(lShape:getType() == 'polygon') then
					--Have to add the ability to draw polygon shapes here!
				elseif(lShape:getType() == 'edge') then
					local x1, y1, x2, y2 = lShape:getPoints()
					local pointOneCamPos = self:worldPosToCameraPos(x1, y1)
					local pointTwoCamPos = self:worldPosToCameraPos(x2, y2)
					love.graphics.setColor(169,169,169) -- Dark Gray
					love.graphics.setLine(2, 'smooth')
					love.graphics.line(pointOneCamPos.x, pointOneCamPos.y, pointTwoCamPos.x, pointTwoCamPos.y)
				elseif(lShape:getType() == 'chain') then

					--This makes me want to kill myself.
					local lChainPoints = {lShape:getPoints()}
					love.graphics.setColor(169,169,169) -- Dark Gray
					love.graphics.setLine(4, 'smooth')
					local pointOneCamPos = nil
					local pointTwoCamPos = nil
					for i = 4,#lChainPoints,4 do
						--print("(" .. lChainPoints[i-3] .. ", " .. lChainPoints[i-2] .. ") (" .. lChainPoints[i-1] .. ", " .. lChainPoints[i] .. ")")	
						pointOneCamPos = self:worldPosToCameraPos(lChainPoints[i-3], lChainPoints[i-2])
						if(pointTwoCamPos ~= nil) then
							love.graphics.line(pointOneCamPos.x, pointOneCamPos.y, pointTwoCamPos.x, pointTwoCamPos.y)
						end
						pointTwoCamPos = self:worldPosToCameraPos(lChainPoints[i-1], lChainPoints[i])
						love.graphics.line(pointOneCamPos.x, pointOneCamPos.y, pointTwoCamPos.x, pointTwoCamPos.y)
					end

					--Why doesn't this work?!
					--[[
					print(lShape:getType())
					local childCount = lShape:getChildCount()
					print("childCount: " .. childCount)
					for i = 1, childCount do
						print("\t" .. i)
						local lEdgeShape = lShape:getChildEdge(i)

						if(lEdgeShape ~= nil) then
							if(lEdgeShape:getType() == 'edge') then
								local x1, y1, x2, y2 = lEdgeShape:getPoints()
								local pointOneCamPos = self:worldPosToCameraPos(x1, y1)
								local pointTwoCamPos = self:worldPosToCameraPos(x2, y2)
								love.graphics.setColor(169,169,169) -- Dark Gray
								love.graphics.setLine(4, 'smooth')
								love.graphics.line(pointOneCamPos.x, pointOneCamPos.y, pointTwoCamPos.x, pointTwoCamPos.y)
							end
						end
					end
					]]
				end

				local lActor = lFixture:getUserData()
				if(lActor ~= nil) then
					--Force Vector
					love.graphics.setColor(206, 32, 41) --Fire Engine Red
					local lForceVector = Vector:new({x = lActor.forceVector.x, y = -lActor.forceVector.y})
					lForceVector = (lForceVector * self.pxPerUnit) + bodyCamPos
					love.graphics.setLine(1, 'smooth')
					love.graphics.line(bodyCamPos.x, bodyCamPos.y, lForceVector.x, lForceVector.y)

					--NameTag
					local AABBtopLeftX, AABBtopLeftY, AABBbottomRightX, AABBbottomRightY = lShape:computeAABB( 0, 0, bodyAngle, 1 )
					love.graphics.setColor(153,153,255) --Periwinkle
					love.graphics.setFont(lActor.nametagFont)
					love.graphics.print(lActor.name, bodyCamPos.x - (lActor.nametagFont:getWidth(lActor.name) / 2),
									 bodyCamPos.y - (math.abs(AABBtopLeftY) * self.pxPerUnit) - (lActor.nametagFont:getHeight() * 1.5),
									 0,1,1,0,0,0,0)

					if(lActor.objPoint ~= nil) then
						local lActorObjective = self:worldPosToCameraPos(lActor.objPoint.x, lActor.objPoint.y)
						--Line to objPoint
						love.graphics.setColor(255,192,203) --Pink
						love.graphics.setLine(2, 'smooth')
						love.graphics.line(bodyCamPos.x, bodyCamPos.y, lActorObjective.x, lActorObjective.y)

						--Direction to objPoint indicator
						if(lShape:getType() == 'circle') then
							local shapeRadius = lShape:getRadius() * self.pxPerUnit
							love.graphics.setColor(128,0,0) --Maroon
							love.graphics.setLine(1, 'smooth')
							love.graphics.line(bodyCamPos.x, bodyCamPos.y,
									   bodyCamPos.x + (shapeRadius * math.cos(bodyAngle + lActor.objTheta)),
									   bodyCamPos.y - (shapeRadius * math.sin(bodyAngle + lActor.objTheta)))
						end
					end

					--Selection Box
					if(lActor.selected == true) then
						love.graphics.setColor(255,255,255)
						love.graphics.rectangle("line", bodyCamPos.x - (math.abs(AABBtopLeftX) * self.pxPerUnit),
										bodyCamPos.y - (math.abs(AABBtopLeftY) * self.pxPerUnit),
										(AABBbottomRightX - AABBtopLeftX) * self.pxPerUnit,
										(AABBbottomRightY - AABBtopLeftY) * self.pxPerUnit)
					end
				end

				--Velocity Vector
				local linVelX, linVelY = lBody:getLinearVelocity()
				if((linVelX > 0) or (linVelY > 0)) then
					local linVel = Vector:new({x = linVelX, y = -linVelY})
					linVel = (linVel * self.pxPerUnit) + bodyCamPos
					love.graphics.setColor(113, 188, 120) --Fern Green
					love.graphics.setLine(1, 'smooth')
					love.graphics.line(bodyCamPos.x, bodyCamPos.y, linVel.x, linVel.y)
					--Maybe a nice little arrowhead?
				end
			end
		end
	end

	-- draw a selection box
	love.graphics.setColor(255,255,255)
	if(self.selectBox.toggle == true) then
		love.graphics.rectangle("line", self.selectBox.x1, self.selectBox.y1, self.selectBox.x2  - self.selectBox.x1, self.selectBox.y2 - self.selectBox.y1)
	end

	--A cross-hair thing
	love.graphics.setColor(210,180,140)
	local center_x = (love.graphics.getWidth() / 2)
	local center_y = (love.graphics.getHeight() / 2)
	love.graphics.setLine(1, 'smooth')
	love.graphics.line(center_x - 10, center_y, center_x + 10, center_y)
	love.graphics.line(center_x, center_y - 10, center_x, center_y + 10)
end

function Camera.bbQueryCallback(lFixture)
	if lFixture ~= nil then
		--table.insert(self.queryFixtures,lFixture)
		table.insert(game.cam.queryFixtures, lFixture) --I dunno about this
	end
	return(true)
end

