require "love"
flux = require "flux"

local sprites = {}
local state = {
    gamestate = "intro",
    totaldistance = 0,
    level = {
	hit  = 1,
	hill = 1,
	rock = 1,
	ramp = 1
    },
    max = {
	hit  = 6,
	hill = 2,
	rock = 3,
	ramp = 3
    },
    charging = false,
    chargetime = 0,
    chargemax = 1,
    chargeflip = false,
    font = love.graphics.getFont(),
}
local intro = {
    state = 0,
    rock = {
	xpos = 0,
	ypos = 145,
	xoffset = 185,
	yoffset = 90,
	xvel = 0,
	yvel = 0,
	rotvel = 0,
	rot = 0,
	scl = 0.5,
	friction = 10,
	gravity = 10,
	mass = 50,
	bouncedamp = 2
    },
    textfade1 = 0,
    textfade2 = 0,
    mainfont =  love.graphics.newFont(12),
    introfont = love.graphics.newFont("res/CAVEMAN.TTF", 50)
}
nextintrostate = function()
    intro.state = intro.state + 1
end
local upgrade = {
    hit = {100, 200, 300, 400, 500, 1000},
    hillspeeds = {1.0, 1.5, 2.0},
    hillheights = {145, 300, 500},
    rockfriction = {10, 5, 1},
    rockspeeds = {1.0, 1.2, 2.0}
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
    friction = upgrade.rockfriction[state.level.rock],
    gravity = 10,
    mass = 50,
    bouncedamp = 2,
}

function launch()
    state.gamestate = "launched"
end

function levelup(what)
    if (what == 1 or what == "hit")
	and state.totaldistance >= state.level.hit * 100
	and state.level.hit < state.max.hit
    then
	state.totaldistance = state.totaldistance - state.level.hit * 100
	state.level.hit = state.level.hit + 1
    elseif (what == 2 or what == "hill")
	and state.totaldistance >= state.level.hill * 100
	and state.level.hill < state.max.hill
    then
	state.totaldistance = state.totaldistance - state.level.hill * 100
	state.level.hill = state.level.hill + 1
    elseif (what == 3 or what == "rock")
	and state.totaldistance >= state.level.rock * 100
	and state.level.rock < state.max.rock
    then
	state.totaldistance = state.totaldistance - state.level.rock * 100
	state.level.rock = state.level.rock + 1
    elseif (what == 4 or what == "ramp")
	and state.totaldistance >= state.level.ramp * 100
	and state.level.ramp < state.max.ramp
    then
	state.totaldistance = state.totaldistance - state.level.ramp * 100
	state.level.ramp = state.level.ramp + 1
    end
    resetstuff()
end

local tween = nil

function resetstuff()
    state.totaldistance = state.totaldistance + rockdata.xpos / 50
    if tween then tween:stop() end
    state.gamestate = "readytoroll"
    state.charging = false
    state.chargeflip = false
    rockdata.xpos = 0
    rockdata.ypos = upgrade.hillheights[state.level.hill]
    rockdata.xoffset = 65
    rockdata.yoffset = 100
    rockdata.xvel = 0
    rockdata.yvel = 0
    rockdata.rotvel = 0
    rockdata.rot = 0

    love.graphics.setFont(intro.mainfont)
    love.keyreleased = mainkeyreleased
    love.update = mainupdate
    love.draw = maindraw
end

function love.load()
    sprites.background = love.graphics.newImage("res/background.png")

    sprites.intro = love.graphics.newImage("res/intro.png")
    sprites.rock = {
	love.graphics.newImage("res/rock1.png"),
	love.graphics.newImage("res/rock2.png"),
	love.graphics.newImage("res/rock3.png")
    }

    sprites.hill = {
	love.graphics.newImage("res/hill1.png"),
	love.graphics.newImage("res/hill2.png"),
    }
    sprites.ramp = {
	love.graphics.newImage("res/ramp1.png"),
	love.graphics.newImage("res/ramp2.png"),
	love.graphics.newImage("res/ramp3.png")
    }
end

function introupdate(dt)
    flux.update(dt)
    local r = intro.rock

    r.rotvel = r.xvel/64
    r.rotvel = r.xvel/64
    r.rot = (r.rot + r.rotvel * 2 * math.pi * dt) % (2 * math.pi)
    r.xpos = r.xpos + r.xvel * dt

    if intro.state == 2 then
	r.xvel = r.xvel - dt * r.friction
	if r.xvel < 0 then r.xvel = 0 end

	if r.xvel == 0 then intro.state = 3 end
    end

    if intro.state == 3 then
	intro.state = 4
	tween = flux.to(intro, 5, {textfade1 = 255}):delay(1):after(1, {textfade2 = 255}):delay(5)
    end
end

function mainupdate(dt)
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

love.update = introupdate

function introdraw()
    love.graphics.clear(132, 209, 227, 255) --sky color
    love.graphics.draw(sprites.intro, -(intro.rock.xpos) * 2, -500, 0, 2)
    local r = intro.rock
    love.graphics.draw(
	sprites.rock[1],
	r.xoffset * 2,
	(love.graphics.getHeight() - r.ypos * 2 - r.yoffset),
	r.rot,
	r.scl,
	r.scl,
	sprites.rock[1]:getWidth()/2,
	sprites.rock[1]:getHeight()/2
    )
    love.graphics.setColor(255, 255, 255, math.floor(intro.textfade1))
    love.graphics.setFont(intro.introfont)
    love.graphics.printf("THE HUMAN DRIVE FOR INNOVATION\nIN THE REALM OF SCIENCE", 20, 125, 760, "center")
    love.graphics.setColor(255, 255, 255, math.floor(intro.textfade2))
    love.graphics.setFont(intro.mainfont)
    love.graphics.printf("(press [space])", 20, 400, 760, "center")
    love.graphics.setColor(255, 255, 255, 255)
end

function maindraw()
    love.graphics.clear(132, 209, 227, 255) --sky color

    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth()), 0)
    love.graphics.draw(sprites.background, -(rockdata.xpos%sprites.background:getWidth())+sprites.background:getWidth(), 0)
    love.graphics.draw(sprites.hill[state.level.hill], -rockdata.xpos, 0)
    love.graphics.draw(sprites.ramp[state.level.ramp], -rockdata.xpos, 0)

    local r = rockdata

    love.graphics.printf("Distance: "..math.floor(r.xpos / 50 + 0.5).."\nHeight: "..math.floor(r.ypos + 0.5), 20, 20, 760)
    love.graphics.printf("[space] to roll\n[r] to reset\n[q] to quit", 20, 20, 760, "center")
    love.graphics.printf("Total Distance: "..math.floor(state.totaldistance + r.xpos / 50 + 0.5), 20, 20, 760, "right")
    love.graphics.printf("Upgrades:\n(costs 100 x CurrentLevel)\n[1] hit ("..state.level.hit.."/"..state.max.hit..
	")\n[2] hill ("..state.level.hill.."/"..state.max.hill..
	")\n[3] rock ("..state.level.rock.."/"..state.max.rock..
	")\n[4] ramp ("..state.level.ramp.."/"..state.max.ramp..")"
	, 20, 34, 760, "right"
    )

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

love.draw = introdraw

function love.keypressed(key)
    if state.gamestate == "readytoroll" and key == "space" then
	state.chargetime = 0
	state.charging = true
	state.chargeflip = false
    end
end

function introkeyreleased(key)
    if state.gamestate == "intro" then
	if intro.state == 0 and key == "space" then
	    intro.state = 1
	    tween = flux.to(intro.rock, 8, {xpos = 450, xvel = 50, xoffset = 150}):ease("sinein"):oncomplete(nextintrostate)
	    flux.to(intro.rock, 8, {ypos = 10}):ease("sineinout")
	elseif intro.state == 4 and key == "space" then
	    resetstuff()
	end
    end
end

function mainkeyreleased(key)
    if state.gamestate == "readytoroll" and state.charging and key == "space" then
	state.gamestate = "launching"
	state.charging = false
	local maxvel = upgrade.hit[state.level.hit] * upgrade.hillspeeds[state.level.hill] * upgrade.rockspeeds[state.level.rock]
	local hillvel = maxvel/2 + maxvel/2 * state.chargetime

	if state.level.hill == 1 then
	    tween = flux.to(rockdata, 300 / hillvel, {xpos = 300, ypos = 0, xvel = hillvel, xoffset = 150}):ease("quadin")
	elseif state.level.hill == 2 then
	    tween = flux.to(rockdata, 300 / hillvel, {xpos = 300, ypos = 0, xvel = hillvel, xoffset = 150}):ease("cubicin")
	end

	-- ramp 1 doesn't do anything
	if state.level.ramp == 2 then
	    tween:after(50 / hillvel, {xpos = 350, ypos = 50, yvel = 1 * hillvel}):ease("linear")
	elseif state.level.ramp == 3 then
	    tween:after(90 / hillvel, {xpos = 390, ypos = 100, yvel = 2 * hillvel}):ease("linear")
	end

	tween:oncomplete(launch)
    elseif key == "r" or key == "R" then
	resetstuff()
    elseif key == "q" or key == "Q" then
	love.event.quit()
    elseif key == "1" and state.gamestate == "readytoroll" or state.gamestate == "stopped" then
	levelup(1)
    elseif key == "2" and state.gamestate == "readytoroll" or state.gamestate == "stopped" then
	levelup(2)
    elseif key == "3" and state.gamestate == "readytoroll" or state.gamestate == "stopped" then
	levelup(3)
    elseif key == "4" and state.gamestate == "readytoroll" or state.gamestate == "stopped" then
	levelup(4)
    end
end

love.keyreleased = introkeyreleased
