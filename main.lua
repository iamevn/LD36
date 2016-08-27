require "love"
flux = require "flux"

local state = 0
local timeout = 0
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
    friction = 10
}

function launch()
    rockdata.launched = true
    rockdata.xvel = 100
end

function love.load()
    sprites.rock = love.graphics.newImage("res/rock.png")
    sprites.background = love.graphics.newImage("res/background.png")
end

function love.update(dt)
    flux.update(dt)
    if state == 0 then
	local r = rockdata

	r.rot = (r.rot + r.rotvel * 2 * math.pi * dt) % (2 * math.pi)
	r.xpos = r.xpos + r.xvel * dt
	r.ypos = r.ypos + r.yvel * dt

	if r.ypos < 10 then
	    r.xvel = r.xvel - dt * r.friction
	    if r.xvel < 0 then r.xvel = 0 end
	end

	r.rotvel = r.xvel/64

	if r.launched and r.xvel == 0 and r.yvel == 0 then
	    timeout = timeout + dt
	end
	if timeout > 1 then
	    state = 1
	    timeout = 0
	end
    elseif state <= 3 then
	-- Yeah, it's one of these games
	-- I know
	--
	-- It's a pretty ancient genre isn't it?
	timeout = timeout + dt
	if timeout > 3 then
	    state = state + 1
	    timeout = 0
	end
    end
end

function love.draw()
    if state == 0 then
	love.graphics.clear(132, 209, 227, 255) --sky color
	love.graphics.draw(sprites.background, -rockdata.xpos, 0)
	local r = rockdata
	love.graphics.printf("Distance: "..math.floor(r.xpos / 100).."\nHeight: "..math.floor(r.ypos), 20, 20, 760)
	love.graphics.draw(sprites.rock, r.xoffset, (love.graphics.getHeight() - r.ypos - r.yoffset), r.rot, r.scl, r.scl, sprites.rock:getWidth()/2, sprites.rock:getHeight()/2)
    else
	local str = "Yeah it's one of these games"
	if state > 1 then str = str.."\nI know" end
	if state > 2 then str = str.."\n\nIt's a pretty ancient genre isn't it?" end
	love.graphics.clear(0, 0, 0, 255) --black
	love.graphics.printf(str, 800/2, 250, 760)
    end
end

function love.keyreleased(key)
    if (not rockdata.launched) and key == 'space' then
	flux.to(rockdata, 3, {xpos=280, ypos=0, xvel=100, xoffset=150}):ease("quadin"):oncomplete(launch)
    end
end
