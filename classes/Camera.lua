local love = love
local lg = require'love.graphics'
local color = require'include.color'

require'classes.Zone'
require'classes.Vector'


local font10 = lg.newFont(10)


Camera = Class("Camera", Zone, {
	parent        = nil,
	target_entity = nil,
	select_box    = { toggle = false, pos1 = {}, pos2 = {} },
})


function Camera:init ( )
	self.world = self.parent

	return self
end


function Camera:update_transform ( )
	self.scale.x = math.max(self.scale.x, 0.2)
	self.scale.y = math.max(self.scale.y, 0.2)
end


function Camera:update(dt, mouse_pos)
	if self.select_box.toggle == true and lg.hasFocus() then
		self.select_box.pos2 = mouse_pos:transform(self.world, self)
	end
end


local debug = false
function Camera:mousepressed ( pos, button )
	if button == 'l' then
		self.select_box.toggle = true
		self.select_box.pos1 = pos:transform(self.world, self)

	elseif button == 'wu' then
		self.scale.x = self.scale.x + 0.2
		self.scale.y = self.scale.y + 0.2

	elseif button == 'wd' then
		self.scale.x = self.scale.x - 0.2
		self.scale.y = self.scale.y - 0.2
	end
end


function Camera:mousereleased ( pos, button )
	if button == 'l' then
		local sb = self.select_box

		sb.toggle = false
		sb.pos2 = pos:transform(self.world, self)


		-- Deselect all actors.
		for _, lp_body in ipairs(self.world.physics:getBodyList()) do
			for _, fixture in ipairs(lp_body:getFixtureList()) do
				local actor = is_a(fixture:getUserData(), Actor)
				if actor then actor.selected = false end
			end
		end


		-- Select box-selected actors.
		local topl = Vector(math.min(sb.pos1.x, sb.pos2.x), math.max(sb.pos1.y, sb.pos2.y)):transform(self, self.world)
		local botr = Vector(math.max(sb.pos1.x, sb.pos2.x), math.min(sb.pos1.y, sb.pos2.y)):transform(self, self.world)

		self.world.physics:queryBoundingBox(topl.x, topl.y, botr.x, botr.y, function ( fixture )
			local body = fixture:getUserData()

			if is_a(body, Actor) then
				body.selected = true
			end

			return true
		end)


	elseif button == 'r' then
		for _, body in ipairs(self.world.physics:getBodyList()) do
			for _, fixture in ipairs(body:getFixtureList()) do
				local actor = is_a(fixture:getUserData(), Actor)

				if actor and actor.selected then
					if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
						actor:append_move(actor:path_to(pos:transform(self.world, actor.zone)))
					else
						actor:set_moves(actor:path_to(pos:transform(self.world, self.actor)))
					end
				end
			end
		end
	end
end


function Camera:render()
	self:update_transform()


	-- Lock the camera to an entity.
	if self.target_entity then
		self.center = self.target_entity.position.loc.object:transform(self.target_entity.zone, self.world)
	end


	-- World-zone objects.
	local topl = Vector(-1, 1):transform(self, self.world)
	local botr = Vector(1, -1):transform(self, self.world)
	local fixtures = {}

	self.world.physics:queryBoundingBox(topl.x, topl.y, botr.x, botr.y, function ( fixture )
		table.insert(fixtures, fixture)
		return true
	end)


	for _, fixture in ipairs(fixtures) do
		local body = fixture:getUserData()

		if is_a(body, Body) then
			body:draw();
		end
	end


	self:push() do
		-- A cross-hair thing.
		lg.setColor(color.TAN); lg.setLine(1, 'smooth')
		lg.line(self.center.x - 10, self.center.y, self.center.x + 10, self.center.y)
		lg.line(self.center.x, self.center.y - 10, self.center.x, self.center.y + 10)


		-- Draw a selection box.
		lg.setColor(color.WHITE)
		if self.select_box.toggle then
			local sb = self.select_box
			lg.rectangle('line', sb.pos1.x, sb.pos1.y, sb.pos2.x - sb.pos1.x, sb.pos2.y - sb.pos1.y)
		end
	end lg.pop()
end
