--[[
    GD50 2018
    Pong Remake

    -- Main Program --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- our Paddle class, which stores position and dimensions for each Paddle
-- and the logic for rendering them
require 'Paddle'

-- our Ball class, which isn't much different than a Paddle structure-wise
-- but which will mechanically function very differently
require 'Ball'


-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- paddle movement speed
PADDLE_SPEED = 200

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Pong')

    -- seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['intro'] = love.audio.newSource('sounds/intro.wav', 'static'),
        ['win'] = love.audio.newSource('sounds/win.wav', 'static'),
        ['bgm'] = love.audio.newSource('sounds/bgm.wav','static')
    }
    sounds['intro']:play()
    
    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    -- initialize our player paddles; make them global so that they can be
    -- detected by other functions and modules
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 20)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)


    -- initialize score variables
    player1Score = 0
    player2Score = 0

    -- either going to be 1 or 2; whomever is scored on gets to serve the
    -- following turn
    servingPlayer = 1

    -- player who won the game; not set to a proper value until we reach
    -- that state in the game
    winningPlayer = 0
    
    -- GAME MODES
    -- 1 PLAYER VS PLAYER
    -- 2 PLAYER VS COMPUTER
    gamemode = ''
    

    --initiates the x and y position of the highlight indicator
        --initiates the value for the menu idicator
    indicatorX = VIRTUAL_WIDTH / 2 - 55
    indicatorY = 49
    indicatorChoice = 1

    -- initiates the choice as left paddle
    paddleChoice = 1
    paddleIndicatorX = VIRTUAL_WIDTH/2 - 79
    paddleIndicatorY = VIRTUAL_HEIGHT/2 - 21
    paddleSide = ''
    -- the state flow of our game; can be any of the following:

    -- 1. 'menu' (this is the part where player picks the game mode)
    -- 2. 'start' (the beginning of the game, before first serve)
        -- if the user chose the pvc, will create a new state: paddle state(where player choose whether to use left or right paddle)
    -- 3. 'serve' (waiting on a key press to serve the ball)
    -- 4. 'play' (the ball is in play, bouncing between paddles)
    -- 5. 'done' (the game is over, with a victor, ready for restart)

    -- game modes are the following:
    -- 1. Player vs Player(pvp)
    -- 2. Player vs Computer(pvc)
    gameState = 'menu'
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position
        -- at which it collided, then playing a sound effect
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- detect upper and lower screen boundary collision, playing a sound
        -- effect and reversing dy if true
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left or right edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 10 then
                sounds['win']:play()
                sounds['bgm']:stop()
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                sounds['win']:play()
                sounds['bgm']:stop()
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
        --
        -- paddles can't move in 'menu' state
        -- checks if gamemode is player vs player under play gamestate
        if gamemode == 'pvp' then
            -- player 1
            if love.keyboard.isDown('w') then
                player1.dy = -PADDLE_SPEED
            elseif love.keyboard.isDown('s') then
                player1.dy = PADDLE_SPEED
            else
                player1.dy = 0
            end
  
            -- player 2
            if love.keyboard.isDown('up') then
                player2.dy = -PADDLE_SPEED
            elseif love.keyboard.isDown('down') then
                player2.dy = PADDLE_SPEED
            else
                player2.dy = 0
            end
        end
        
        --checks if game mode is player vs computer under play gamestate    
        -- first checks if user chooses to play as player 1 or 2
        -- player gets both inputs since opponent is not using the other controlls, more controlls for user
        if gamemode == 'pvc' then
            if paddleSide == 'left' then
                -- player 1
                if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
                    player1.dy = -PADDLE_SPEED
                elseif love.keyboard.isDown('s') or love.keyboard.isDown('down') then
                    player1.dy = PADDLE_SPEED
                else
                    player1.dy = 0
                end
  
            -- player 2(AI)
            -- AI will only move if the ball is coming towards it
            -- slight delay till the ball reaches an imaginary line(1/4 of the game width) to make the AI move
                if ball.dx > 0 and ball.x >= VIRTUAL_WIDTH/4 then
                    if ball.x + ball.width > 0 and ball.x < VIRTUAL_WIDTH then
                        if player2.y + player2.height/2 > ball.y + ball.height then
                            -- the value of dy is 120 which is not so fast or not too slow, also makes the ai more beatable
                            player2.dy = -115
                        elseif player2.y + player2.height/2 < ball.y then
                            player2.dy = 115
                        else
                            player2.dy = 0
                        end
                    end                  
                end
            
            -- if user chose to play as player 2 or right side    
            elseif paddleSide == 'right' then
                --player 1(AI)
                if ball.dx < 0 and ball.x <= VIRTUAL_WIDTH/2 + VIRTUAL_WIDTH/4 then
                    if ball.x + ball.width > 0 and ball.x < VIRTUAL_WIDTH then
                        if player1.y + player1.height/2 > ball.y + ball.height then
                            -- the value of dy is 120 which is not so fast or not too slow, also makes the ai more beatable
                            player1.dy = -115
                        elseif player1.y + player1.height/2 < ball.y then
                            player1.dy = 115
                        else
                            player1.dy = 0
                        end
                    end                  
                end
                
                --player 2
                if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
                    player2.dy = -PADDLE_SPEED
                elseif love.keyboard.isDown('s') or love.keyboard.isDown('down') then
                    player2.dy = PADDLE_SPEED
                else
                    player2.dy = 0
                end
            end     
        end


        -- update our ball based on its DX and DY only if we're in play state;
        -- scale the velocity by dt so movement is framerate-independent
        ball:update(dt) 

        player1:update(dt)
        player2:update(dt)
    end
end
    


--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    -- will not exit even if the game is still playing
    if key == 'escape' then
        if gameState ~= 'menu'  and gameState ~= 'play' then
            ball:reset()
            -- reset scores to 0
            player1Score = 0
            player2Score = 0
            servingPlayer = 1
            gameState = 'menu'

        elseif gameState == 'menu' then
            love.event.quit()
        end
    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' or key == 'space' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0
            sounds['bgm']:setLooping(true)
            sounds['bgm']:stop()
            sounds['bgm']:play()
            
            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
    
    -- changes as the position of the indicator moves per key
    if gameState == 'menu' then
        if key == 'down' then
            if indicatorChoice >= 1 and indicatorChoice < 2 then
                indicatorY = indicatorY + 10
                indicatorChoice = indicatorChoice + 1
            elseif indicatorChoice == 2 then
                indicatorChoice = 1
                indicatorY = indicatorY - 10
            end
        end

        if key == 'up' then
            if indicatorChoice == 2 then
                indicatorY = indicatorY - 10
                indicatorChoice = indicatorChoice - 1
            elseif indicatorChoice == 1 then
                indicatorY = indicatorY + 10
                indicatorChoice = 2
            end
        end

    -- confirm the choice of the user
        if key == 'enter' or key == 'return' then
            if indicatorChoice == 1  then
                gamemode = 'pvp'
                gameState = 'start'
                sounds['bgm']:setLooping(true)
                sounds['bgm']:stop()
                sounds['bgm']:play()
            elseif indicatorChoice == 2 then
                gameState = 'paddle'
            end
        end
    
    -- in the paddle state, moves the paddle indicator
    -- also confirms the choice of the user by clicking space or enter
    elseif gameState == 'paddle' then
        if key == 'left' or key == 'right' then
            if paddleChoice == 1 then
                paddleIndicatorX = VIRTUAL_WIDTH/2 + 16
                paddleChoice = 2
            elseif paddleChoice == 2 then
                paddleIndicatorX = VIRTUAL_WIDTH/2 - 79
                paddleChoice = 1
            end
        end

        if  key == 'return' or key == 'space' or key == 'enter 'then
            if paddleChoice == 1 then
                paddleSide = 'left'
                gamemode = 'pvc'
                gameState = 'start'
                sounds['bgm']:setLooping(true)
                sounds['bgm']:stop()
                sounds['bgm']:play()
            elseif paddleChoice == 2 then
                paddleSide = 'right'
                gamemode = 'pvc'
                gameState = 'start'
                sounds['bgm']:setLooping(true)
                sounds['bgm']:stop()
                sounds['bgm']:play()
            end
        end
    end
end


--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:start()

    love.graphics.clear(0.1569, 0.1765, 0.2039, 1)
    
    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter or Space to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Escape to go back to Menu.', 0, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'center')
    
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter or Space to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Escape to go back to Menu.', 0, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter or Space to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Escape to go back to Menu.', 0, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'center')

    --for the menu
    elseif gameState == 'menu' then
        -- for the choice indicator thingy that highlights the choice in the menu
        love.graphics.setColor(65/255, 71/255, 67/255, 255)
        love.graphics.rectangle('fill', indicatorX, indicatorY, 110, 10)
        love.graphics.setColor(1, 1, 1, 1)

        --menu texts
        love.graphics.setFont(largeFont)
        love.graphics.printf('Choose a mode',0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player vs Player' , 0, 50, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Player vs Computer', 0, 60, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press escape to quit.', 0, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'center')


    elseif gameState == 'paddle' then
        drawPaddleCHOICE()
    end

    -- controls texts
    if gameState == 'start' or gameState == 'serve' then
        
        love.graphics.setFont(smallFont)


        if gamemode == 'pvp' then
            love.graphics.printf('W - move up\nS - move down', 5, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'left')
            love.graphics.print('UP KEY - move up\nDOWN KEY- move down', VIRTUAL_WIDTH - 100, VIRTUAL_HEIGHT - 20)
        
        elseif gamemode == 'pvc' then
            if paddleSide == 'left' then
                love.graphics.printf('W or UP - move up\nS or DOWN - move down', 5, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'left')
            elseif paddleSide == 'right' then
                love.graphics.print('W or UP - move up\nS or DOWN - move down', VIRTUAL_WIDTH - 105, VIRTUAL_HEIGHT - 20)
            end
        end

    end

    -- show the score before ball is rendered so it can move over the text
    -- player, ball, and score will not display in menu and paddle states
    if gameState ~= 'menu' and gameState ~= 'paddle' then
    displayScore()
    
    player1:render()
    player2:render()
    ball:render()
    end

    -- display FPS for debugging; simply comment out to remove
    displayFPS()

    -- end our drawing to push
    push:finish()
end

--[[
    Simple function for rendering the scores.
]]
function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end


function drawPaddleCHOICE()
    love.graphics.setFont(smallFont)
    love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Choose your preferred paddle', 0, 20, VIRTUAL_WIDTH, 'center')
    
    -- draws the indicator for the choices in paddle
    love.graphics.setColor(65/255, 71/255, 67/255, 255)
    love.graphics.rectangle('fill', paddleIndicatorX, paddleIndicatorY, 70, 18)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(largeFont)
    love.graphics.print('LEFT', VIRTUAL_WIDTH/2 - 60, VIRTUAL_HEIGHT/2 - 20)
    love.graphics.print('RIGHT', VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/2 - 20)
end