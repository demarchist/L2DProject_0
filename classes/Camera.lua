require'classes.Class'
require'classes.Vector'
require'include.color'


local lg = require 'love.graphics'
local font10 = lg.newFont(10)


Camera = Class("Camera", nil, {
	targetWorld  = nil,
	targetEntity = nil,
	selectBox    = { toggle = false, x1 = 0, y1 = 0, x2 = 0, y2 = 0 },
	scale        = 1,
	center       = { x = 0, y = 0 },

	pxPerUnit = 10,
	targetCoordinates = Vector:new({x = 0, y = 0}),
	worldAperture = {lowerBound = Vector:new({x = 0, y = 0}), upperBound = Vector:new({x = 0, y = 0})},
})


function Camera:init ()
	self.targetWorld = self.world.physics

	self:calcWorldAperture()

	return self
end


function Camera:setTargetCoordinates(x, y)
	self.targetCoordinates.x = x
	self.targetCoordinates.y = y
	self:calcWorldAperture()
end


function Camera:calcWorldAperture()
	local aperture = self.worldAperture

	if not lg.isCreated() or not aperture or self.pxPerUnit <= 0 then return false end

	local view_width = lg.getWidth() / self.pxPerUnit
	local view_height = lg.getHeight() / self.pxPerUnit

	aperture.topLeftX = self.targetCoordinates.x - view_width/2
	aperture.topLeftY = self.targetCoordinates.y - view_height/2

	aperture.bottomRightX = self.targetCoordinates.x + view_width/2
	aperture.bottomRightY = self.targetCoordinates.y + view_height/2
end


function Camera:worldPosToCameraPos(worldPosX, worldPosY)
	local DestR = Vector:new({x = 0, y = 0})

	DestR.x =  ((worldPosX - self.targetCoordinates.x) * self.pxPerUnit) + (lg.getWidth() / 2)
	DestR.y = -((worldPosY - self.targetCoordinates.y) * self.pxPerUnit) + (lg.getHeight() / 2)

	return DestR
end


function Camera:camPosToWorldPos(camX, camY)
	camX = self.targetCoordinates.x + ((camX - (lg.getWidth() / 2)) / self.pxPerUnit)
	camY = self.targetCoordinates.y - ((camY - (lg.getHeight() / 2)) / self.pxPerUnit)

	return camX, camY
end


function Camera:update(dt)
	if(self.selectBox.toggle == true) then
		if lg.hasFocus() then
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

		local lTopLeftX, lTopLeftY = self:camPosToWorldPos(math.min(self.selectBox.x1, self.selectBox.x2),
		                                                   math.max(self.selectBox.y1, self.selectBox.y2))
		local lBottomRightX, lBottomRightY = self:camPosToWorldPos(math.max(self.selectBox.x1, self.selectBox.x2),
		                                                           math.min(self.selectBox.y1, self.selectBox.y2))

		for k, lBody in pairs(self.targetWorld:getBodyList()) do
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

		local queryFixtures = {}
		local function bbQueryCallback(lFixture)
			if lFixture ~= nil then table.insert( queryFixtures, lFixture ) end

			return(true)
		end
		self.targetWorld:queryBoundingBox(lTopLeftX, lTopLeftY, lBottomRightX, lBottomRightY, bbQueryCallback)

		for k, lFixture in pairs(queryFixtures) do
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
							if(love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')) then
								lActor:append_move(Actor.path_to(worldX, worldY))
							else
								lActor:set_moves(Actor.path_to(worldX, worldY))
							end
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

	local queryFixtures = {}
	local function bbQueryCallback(lFixture)
		if lFixture ~= nil then table.insert( queryFixtures, lFixture ) end

		return(true)
	end
	self.targetWorld:queryBoundingBox(self.worldAperture.topLeftX, self.worldAperture.topLeftY,
	                                  self.worldAperture.bottomRightX, self.worldAperture.bottomRightY,
	                                  bbQueryCallback)

	for k, lFixture in pairs(queryFixtures) do
		if(lFixture ~= nil) then
			local lShape = lFixture:getShape()
			local lBody = lFixture:getBody()

			if((lShape ~= nil) and (lBody ~= nil)) then
				local bodyAngle = lBody:getAngle()
				local bodyCamPos = self:worldPosToCameraPos(lBody:getX(), lBody:getY())

				if(lShape:getType() == 'circle') then
					local shapeRadius = lShape:getRadius() * self.pxPerUnit

					lg.setColor(color.TAN)
					lg.setLine(2, 'smooth')
					lg.circle("line", bodyCamPos.x, bodyCamPos.y, shapeRadius, 50)
					lg.line(bodyCamPos.x, bodyCamPos.y, (bodyCamPos.x + (shapeRadius * math.cos(bodyAngle))), (bodyCamPos.y - (shapeRadius * math.sin(bodyAngle))))
				elseif(lShape:getType() == 'polygon') then
					--Have to add the ability to draw polygon shapes here!
				elseif(lShape:getType() == 'edge') then
					local x1, y1, x2, y2 = lShape:getPoints()
					local pointOneCamPos = self:worldPosToCameraPos(x1, y1)
					local pointTwoCamPos = self:worldPosToCameraPos(x2, y2)
					lg.setColor(color.DARK_GRAY)
					lg.setLine(2, 'smooth')
					lg.line(pointOneCamPos.x, pointOneCamPos.y, pointTwoCamPos.x, pointTwoCamPos.y)
				elseif(lShape:getType() == 'chain') then
					lg.setColor(color.DARK_GRAY)
					lg.setLine(4, 'smooth')
					local a = self:worldPosToCameraPos(lShape:getPoint(1))
					for i = 2, lShape:getVertexCount() do
						local b = self:worldPosToCameraPos(lShape:getPoint(i))

						lg.line(a.x, a.y, b.x, b.y)

						a = b
					end
				end

				local lActor = lFixture:getUserData()
				if(lActor ~= nil) then
					--Force Vector
					love.graphics.setColor(color.FIRE_ENGINE_RED)
					lg.setColor(color.FIRE_ENGINE_RED)
					local lForceVector = Vector:new({x = lActor.force.x, y = -lActor.force.y})
					lForceVector = (lForceVector * self.pxPerUnit) + bodyCamPos
					lg.setLine(1, 'smooth')
					lg.line(bodyCamPos.x, bodyCamPos.y, lForceVector.x, lForceVector.y)

					--NameTag
					local AABBtopLeftX, AABBtopLeftY, AABBbottomRightX, AABBbottomRightY = lShape:computeAABB( 0, 0, bodyAngle, 1 )
					lg.setColor(color.PERIWINKLE)
					lg.setFont(font10)
					lg.print(lActor.name, bodyCamPos.x - (font10:getWidth(lActor.name) / 2),
					                      bodyCamPos.y - (math.abs(AABBtopLeftY) * self.pxPerUnit) - (font10:getHeight() * 1.5),
                                          0,1,1,0,0,0,0)

					--Path to Objective
					if lActor:current_move() then
						--Path lines
						lg.setColor(color.PINK)
						lg.setLine(2, 'smooth')
						local a = Vector:new({x = bodyCamPos.x, y = bodyCamPos.y})
						for i, move in ipairs(lActor.path.moves) do
							if i >= lActor.path.step then
								local lNodeCamPos = self:worldPosToCameraPos(move.dest.x, move.dest.y)
								lg.line(a.x, a.y, lNodeCamPos.x, lNodeCamPos.y)

								a = lNodeCamPos
							end
						end

						--Path Nodes
						lg.setColor(color.WHITE)
						lg.setLine(2, 'smooth')
						for i, move in ipairs(lActor.path.moves) do
							if i >= lActor.path.step then
								local lNodeCamPos = self:worldPosToCameraPos(move.dest.x, move.dest.y)
								lg.circle("fill", lNodeCamPos.x, lNodeCamPos.y, 3, 10)
							end
						end

						--Direction to objPoint indicator
						if(lShape:getType() == 'circle') then
							local shapeRadius = lShape:getRadius() * self.pxPerUnit
							lg.setColor(color.MAROON)
							lg.setLine(1, 'smooth')
							lg.line(bodyCamPos.x, bodyCamPos.y,
							        bodyCamPos.x + (shapeRadius * math.cos(bodyAngle + lActor.deflection)),
							        bodyCamPos.y - (shapeRadius * math.sin(bodyAngle + lActor.deflection)))
						end
					end

					--Selection Box
					if(lActor.selected == true) then
						lg.setColor(color.WHITE)
						lg.rectangle("line", bodyCamPos.x - (math.abs(AABBtopLeftX) * self.pxPerUnit),
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
					lg.setColor(color.FERN_GREEN)
					lg.setLine(1, 'smooth')
					lg.line(bodyCamPos.x, bodyCamPos.y, linVel.x, linVel.y)
					--Maybe a nice little arrowhead?
				end
			end
		end
	end

	-- draw a selection box
	lg.setColor(color.WHITE)
	if(self.selectBox.toggle == true) then
		lg.rectangle("line", self.selectBox.x1, self.selectBox.y1, self.selectBox.x2  - self.selectBox.x1, self.selectBox.y2 - self.selectBox.y1)
	end

	--A cross-hair thing
	lg.setColor(color.TAN)
	local center_x = (lg.getWidth() / 2)
	local center_y = (lg.getHeight() / 2)
	lg.setLine(1, 'smooth')
	lg.line(center_x - 10, center_y, center_x + 10, center_y)
	lg.line(center_x, center_y - 10, center_x, center_y + 10)
end
