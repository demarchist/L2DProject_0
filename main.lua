function love.load()
	require('libraries.loveframes.init')
	require('classes.game')


	love.graphics.setCaption("Adam's LOVE2D Project")
	love.graphics.setMode(800,600,false,false,0)
	love.graphics.setBackgroundColor(120,134,107)

	game = Game:new()
end

function love.update(dt)
	game:update(dt)
	loveframes.update(dt)
end

function love.draw()

	--A cross-hair thing
	love.graphics.setColor(210,180,140)
	local center_x = (love.graphics.getWidth() / 2)
	local center_y = (love.graphics.getHeight() / 2)
	love.graphics.line(center_x - 10, center_y, center_x + 10, center_y)
	love.graphics.line(center_x, center_y - 10, center_x, center_y + 10)

	game:drawWorld()

	loveframes.draw()
end

function love.mousepressed(x, y, button)
	-- https://love2d.org/wiki/MouseConstant

	game:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)

	game:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	-- https://love2d.org/wiki/KeyConstant
	loveframes.keypressed(key, unicode)

	if(key == 'b') then
		-- b was pressed
	elseif key == 'a' then
		-- a was pressed
	end
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
end

function love.focus(f)
	love.graphics.setFont(love.graphics.newFont(24))
	love.graphics.setColor(210,180,140)
	if(not f) then
		--Lost Focus
	else
		--Gained Focus
	end
end

function love.quit()
	--love.graphics.print("Come back soon!")
end
