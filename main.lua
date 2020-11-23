push = require 'push'

WINDOW_WIDTH = 1280 --sets the windows width
WINDOW_HEIGHT = 720 --sets the windows height

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243


function love.load() --initializes the windows height and
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false, -- not fullscreen
        resizable = false, --not not resizable
        vsync = true --vertical sync for monitor refresh rate
    })
end 

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end

function love.draw() --initializes the contents of the function love.load()
    push:apply('start')

    love.graphics.printf('Hello Pong!', 0, VIRTUAL_HEIGHT / 2-6, VIRTUAL_WIDTH, 'center')

    push:apply('end')
end
