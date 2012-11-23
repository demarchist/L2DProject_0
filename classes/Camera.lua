local love = love
local lg = require'love.graphics'
local color = require'include.color'
local a = require'include.affine'

require'classes.Zone'
require'classes.Vector'


local font10 = lg.newFont(10)


Camera = Class("Camera", Zone, {
	target_entity = nil,
	select_box    = { toggle = false, loc1 = {}, loc2 = {} },
	world         = nil,
})


function Camera:update_transform ( )
	self.transform.scale.x = math.max(self.transform.scale.x, 0.2)
	self.transform.scale.y = math.max(self.transform.scale.y, 0.2)
end


function Camera:update ( dt, mloc )
	if self.select_box.toggle == true and lg.hasFocus() then
		self.select_box.loc2 = mloc:transform(self)
	end
end


function Camera:mousepressed ( mloc, button )
	local scale = self.transform.scale

	if button == 'l' then
		self.select_box.toggle = true
		self.select_box.loc1 = mloc:transform(self)

	elseif button == 'wu' then
		scale.x = scale.x + 0.2
		scale.y = scale.y + 0.2

	elseif button == 'wd' then
		scale.x = scale.x - 0.2
		scale.y = scale.y - 0.2
	end

	self:update_transform()
end


function Camera:mousereleased ( mloc, button )
	if button == 'l' then
		local sb = self.select_box

		sb.toggle = false
		sb.loc2 = mloc:transform(self)


		-- Deselect all actors.
		for _, lp_body in ipairs(self.world.physics:getBodyList()) do
			for _, fixture in ipairs(lp_body:getFixtureList()) do
				local actor = is_a(fixture:getUserData(), Actor)

				if actor then actor.selected = false end
			end
		end


		-- Select box-selected actors.
		local topl = Vector(math.min(sb.loc1.x, sb.loc2.x), math.max(sb.loc1.y, sb.loc2.y)):transform(self, self.world)
		local botr = Vector(math.max(sb.loc1.x, sb.loc2.x), math.min(sb.loc1.y, sb.loc2.y)):transform(self, self.world)

		self.world.physics:queryBoundingBox(topl.x, topl.y, botr.x, botr.y, function ( fixture )
			local actor = is_a(fixture:getUserData(), Actor)

			if actor then actor.selected = true end

			return true
		end)


	elseif button == 'r' then
		for _, body in ipairs(self.world.physics:getBodyList()) do
			for _, fixture in ipairs(body:getFixtureList()) do
				local actor = is_a(fixture:getUserData(), Actor)

				if actor and actor.selected then
					if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
						actor:append_move(actor:path_to(mloc:transform(actor.parent)))
					else
						actor:set_moves(actor:path_to(mloc:transform(actor.parent)))
					end
				end
			end
		end
	end
end


function Camera:render ( )
	self:update_transform()


	-- Lock the camera to an entity.
	if self.target_entity then
		self.center = self.target_entity.transform.loc:transform(self.world)
	end


	-- World-zone objects.
	local topl = Vector(-self.size, -self.size):transform(self, self.world)
	local botr = Vector(self.size, self.size):transform(self, self.world)
	local fixtures = {}


	self.world.physics:queryBoundingBox(topl.x, topl.y, botr.x, botr.y, function ( fixture )
		table.insert(fixtures, fixture)
		return true
	end)


	for _, fixture in ipairs(fixtures) do
		local body = is_a(fixture:getUserData(), Body)

		if body and body.draw then
			body:draw();
		end
	end


	do
		local t1, t2

		-- A cross-hair thing.
		lg.setColor(color.TAN); lg.setLine(1, 'smooth')

		t1 = Vector(-10, 0):transform(self, self.screen)
		t2 = Vector(10, 0):transform(self, self.screen)
		lg.line(t1.x, t1.y, t2.x, t2.y)

		t1 = Vector(0, -10):transform(self, self.screen)
		t2 = Vector(0, 10):transform(self, self.screen)
		lg.line(t1.x, t1.y, t2.x, t2.y)


		-- Draw a selection box.
		if self.select_box.toggle then
			lg.setColor(color.WHITE)

			t1 = self.select_box.loc1:transform(self.screen)
			t2 = self.select_box.loc2:transform(self.screen)
			lg.rectangle('line', t1.x, t1.y, t2.x - t1.x, t1.y - t2.y)
		end
	end
end
