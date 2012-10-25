function love.load()
	require('libraries.loveframes.init')
	require('classes.Game')

	love.graphics.setCaption("L2DProject_0")
	love.graphics.setMode(800,600,false,false,0)
	love.graphics.setBackgroundColor(120,134,107)

	game = Game:new()
end

function love.update(dt)
	game:update(dt)
	loveframes.update(dt)
end

function love.draw()

	game:drawWorld()

	loveframes.draw()
end

function love.mousepressed(x, y, button)
	game:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)

	game:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
	game:keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
	game:keyreleased(key, unicode)
end

function love.focus(f)
	if(not f) then
		--Lost Focus
	else
		--Gained Focus
	end
end

function love.quit()
	--love.graphics.print("Come back soon!")
end
