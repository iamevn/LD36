require "love"
flux = require "flux"

local sprites = {}
local state = {
    gamestate = "readytoroll",
    totaldistance = 0,
    level = {
	hit  = 1,
	hill = 1,
	rock = 1,
	ramp = 1
    },
    charging = false,
    chargetime = 0,
    chargemax = 1,
    chargeflip = false,
}
local hittable = {100, 200, 300, 400, 500, 1000}
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
    bouncedamp = 2,
}

function launch()
    state.gamestate = "launched"
end

local tween = nil

function resetstuff()
    state.totaldistance = state.totaldistance + rockdata.xpos / 50
    tween:stop()
    state.gamestate = "readytoroll"
    state.charging = false
    state.chargeflip = false
    rockdata.xpos = 0
    rockdata.ypos = 145
    rockdata.xoffset = 65
    rockdata.yoffset = 100
    rockdata.xvel = 0
    rockdata.yvel = 0
    rockdata.rotvel = 0
    rockdata.rot = 0
end

function love.load()
    sprites.background = love.graphics.newImage("res/background.png")

    sprites.rock = {
	love.graphics.newImage("res/rock1.png"),
	love.graphics.newImage("res/rock2.png"),
	love.graphics.newImage("res/rock3.png")
    }

    sprites.hill = {
	love.graphics.newImage("res/hill1.png")
    }
    sprites.ramp = {
	love.graphics.newImage("res/ramp1.png"),
	love.graphics.newImage("res/ramp2.png"),
	love.graphics.newImage("res/ramp3.png")
    }
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
    if state.charging then
	if state.chargeflip then
	    state.chargetime = state.chargetime - dt
	    if state.chargetime <= 0 then
		state.chargetime = -state.chargetime
		state.chargeflip = false
	    end
	else
	    state.chargetime = state.chargetime + dt
	    if state.chargetime >= state.chargemax then
		state.chargetime = state.chargemax + (state.chargemax - state.chargetime)
		state.chargeflip = true
	    end
	end
    end
end

function love.draw()
    love.graphics.clear(132, 209, 227, 255) --sky color

    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth()), 0)
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth())+sprites.background:getWidth(), 0)
    love.graphics.draw(sprites.hill[state.level.hill], -rockdata.xpos, 0)
    love.graphics.draw(sprites.ramp[state.level.ramp], -rockdata.xpos, 0)

    local r = rockdata

    love.graphics.printf("Distance: "..math.floor(r.xpos / 50 + 0.5).."\nHeight: "..math.floor(r.ypos + 0.5), 20, 20, 760)
    love.graphics.printf("[space] to roll\n[r] to reset\n[q] to quit", 20, 20, 760, "center")
    love.graphics.printf("Total Distance: "..math.floor(state.totaldistance + r.xpos / 50 + 0.5), 20, 20, 760, "right")

    love.graphics.draw(
	sprites.rock[state.level.rock],
	r.xoffset,
	love.graphics.getHeight() - r.ypos - r.yoffset,
	r.rot,
	r.scl,
	r.scl,
	sprites.rock[state.level.rock]:getWidth()/2,
	sprites.rock[state.level.rock]:getHeight()/2
    )

    if state.charging then
	love.graphics.setColor(255, 0, 0, 200)
	love.graphics.rectangle(
	    "fill",
	    r.xoffset + 32,
	    love.graphics.getHeight() - r.ypos - r.yoffset - 32,
	    state.chargetime * 50,
	    10
	)
	love.graphics.setColor(255, 255, 255, 255)
    end
end

function love.keypressed(key)
    if state.gamestate == "readytoroll" and key == "space" then
	state.chargetime = 0
	state.charging = true
	state.chargeflip = false
    end
end

function love.keyreleased(key)
    if state.gamestate == "readytoroll" and state.charging and key == "space" then
	state.gamestate = "launching"
	state.charging = false
	local maxvel = hittable[state.level.hit]
	local hillvel = maxvel/2 + maxvel/2 * state.chargetime
	if state.level.hill == 1 then
	    tween = flux.to(rockdata, 300 / hillvel, {xpos = 300, ypos = 0, xvel = hillvel, xoffset = 150}):ease("quadin")
	end

	-- ramp 1 doesn't do anything
	if state.level.ramp == 2 then tween = tween:after(50 / hillvel, {xpos = 350, ypos = 50, yvel = 0.5 * hillvel}):ease("linear") end
	if state.level.ramp == 3 then tween = tween:after(90 / hillvel, {xpos = 390, ypos = 100, yvel = 1 * hillvel}):ease("linear") end

	tween:oncomplete(launch)
    elseif key == "r" or key == "R" then
	resetstuff()
    elseif key == "q" or key == "Q" then
	love.event.quit()
    end
end
