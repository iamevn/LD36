require "love"
flux = require "flux"

local sprites = {}
local state = {
    gamestate = "readytoroll",
    totaldistance = 0,
    upgrades = {
	hill = 0,
	rock = 0,
	ramp = 0
    },

}
local rockdata = {
    xpos = 0, --distance from start spot
    ypos = 145, --height above ground
    xoffset = 65,
    yoffset = 100,
    xvel = 0,
    yvel = 0,
    rotvel = 0, --full rotations per second
    rot = 0, --in radians
    scl = 0.25,
    friction = 10,
    gravity = 10,
    mass = 50,
    bouncedamp = 2
}

function launch()
    state.gamestate = "launched"
end

function love.load()
    sprites.rock = love.graphics.newImage("res/rock.png")
    sprites.background = love.graphics.newImage("res/background.png")
    sprites.hill = love.graphics.newImage("res/hill.png")
    sprites.ramp = love.graphics.newImage("res/ramp.png")
    sprites.caveman = love.graphics.newImage("res/caveman.png")
end

function love.update(dt)
    flux.update(dt)
    local r = rockdata

    r.rotvel = r.xvel/64
    r.rot = (r.rot + r.rotvel * 2 * math.pi * dt) % (2 * math.pi)
    r.xpos = r.xpos + r.xvel * dt


    if state.gamestate == "launched" then
	local ERR = 0.1
	--friction slows rock when on ground
	if r.ypos < 10 then
	    r.xvel = r.xvel - dt * r.friction
	    if r.xvel < 0 then r.xvel = 0 end
	end

	if r.ypos < 0 then
	    r.yvel = -r.yvel * 1/r.bouncedamp
	    r.ypos = 0
	    if r.yvel < 0 then
		r.ypos = 0
		r.yvel = 0
	    end
	elseif r.ypos < 0+ERR and r.yvel > -ERR and r.yvel < ERR then
	    r.yvel = 0
	    r.ypos = 0
	else
	    r.yvel = r.yvel - r.gravity * r.mass * dt
	    r.ypos = r.ypos + r.yvel * dt
	end

	if r.xvel == 0 and r.yvel == 0 then
	    state.gamestate = "stopped"
	end
    end
end

function love.draw()
    love.graphics.clear(132, 209, 227, 255) --sky color
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth()), 0)
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth())+sprites.background:getWidth(), 0)
    love.graphics.draw(sprites.hill, -rockdata.xpos, 0)
    love.graphics.draw(sprites.caveman, -rockdata.xpos, 10)
    -- love.graphics.draw(sprites.ramp, -rockdata.xpos, 0)
    local r = rockdata
    love.graphics.printf("Distance: "..math.floor(r.xpos / 100 + 0.5).."\nHeight: "..math.floor(r.ypos + 0.5), 20, 20, 760)
    if state.gamestate == "readytoroll" then
	love.graphics.printf("[space] to roll", 20, 100, 700)
    end
    love.graphics.printf(state.gamestate, 400, 20, 700)
    love.graphics.draw(sprites.rock, r.xoffset, (love.graphics.getHeight() - r.ypos - r.yoffset), r.rot, r.scl, r.scl, sprites.rock:getWidth()/2, sprites.rock:getHeight()/2)
end

function love.keyreleased(key)
    if state.gamestate == "readytoroll" and key == "space" then
	state.gamestate = "launching"
	flux.to(rockdata, 3, {xpos = 280, ypos = 0, xvel = 100, xoffset = 150}):ease("quadin")
	    -- :after(0.5, {xpos = 280+(100/2), ypos = 50, yvel = 100})
	    :oncomplete(launch)
    end
end
