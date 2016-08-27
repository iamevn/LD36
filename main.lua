require "love"
flux = require "flux"

local sprites = {}
local rockdata = {
    launched = false,
    xpos = 0, --distance from start spot
    ypos = 145, --height above ground
    xoffset = 50,
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
    rockdata.launched = true
end

function love.load()
    sprites.rock = love.graphics.newImage("res/rock.png")
    sprites.background = love.graphics.newImage("res/background.png")
    sprites.hill = love.graphics.newImage("res/hill.png")
    sprites.ramp = love.graphics.newImage("res/ramp.png")
end

function love.update(dt)
    flux.update(dt)
    local r = rockdata

    r.rot = (r.rot + r.rotvel * 2 * math.pi * dt) % (2 * math.pi)
    r.xpos = r.xpos + r.xvel * dt

    if r.ypos < 10 then
	r.xvel = r.xvel - dt * r.friction
	if r.xvel < 0 then r.xvel = 0 end
    end

    r.rotvel = r.xvel/64

    local ERR = 0.1
    if r.launched then
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
    end
end

function love.draw()
    love.graphics.clear(132, 209, 227, 255) --sky color
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth()), 0)
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth())+sprites.background:getWidth(), 0)
    love.graphics.draw(sprites.hill, -rockdata.xpos, 0)
    love.graphics.draw(sprites.ramp, -rockdata.xpos, 0)
    local r = rockdata
    love.graphics.printf("Distance: "..math.floor(r.xpos / 100 + 0.5).."\nHeight: "..math.floor(r.ypos + 0.5), 20, 20, 760)
    love.graphics.draw(sprites.rock, r.xoffset, (love.graphics.getHeight() - r.ypos - r.yoffset), r.rot, r.scl, r.scl, sprites.rock:getWidth()/2, sprites.rock:getHeight()/2)
end

function love.keyreleased(key)
    if (not rockdata.launched) and rockdata.xpos == 0 and key == 'space' then
	flux.to(rockdata, 3, {xpos=280, ypos=0, xvel=100, xoffset=150}):ease("quadin"):after(0.5, {xpos=280+(100/2), ypos=50, yvel=100}):oncomplete(launch)
    end
end
