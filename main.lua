WINDOW_WIDTH = 1280 --sets the windows width
WINDOW_HEIGHT = 720 --sets the windows height

function love.load() --initializes the windows height and
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false, -- not fullscreen
        resizable = false, --not not resizable
        vsync = true --vertical sync for monitor refresh rate
    })
end 

function love.draw() --initializes the contents of the function love.load()
    love.graphics.printf(
        'Hello Pong! The Day-0 Update', --prints the message inside the quoutation mark
        0,
        WINDOW_HEIGHT / 2-6, 
        WINDOW_WIDTH,
        'center')
end