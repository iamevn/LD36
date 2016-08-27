require "love"

local state = 0
local sprites = {}
local rockdata = {
    pos = {x = 0, y = 245}, --distance from start spot and height above ground
    offset = {x = 50, y = 0},
    vel = {x = 0, y = 0}, --pixels per second
    rotvel = 0, --full rotations per second
    rot = 0, --in radians
    scl = 0.25
}

function love.load()
    sprites.rock = love.graphics.newImage("rock.png")
    sprites.background = love.graphics.newImage("background.png")
end

function love.update(dt)
    --spin rock at 0.5 spin per second
    local r = rockdata
    r.rot = (r.rot + r.rotvel * 2 * math.pi * dt) % (2 * math.pi)
    r.pos.x = r.pos.x + r.vel.x * dt
    r.pos.y = r.pos.y + r.vel.y * dt
end

function love.draw()
    love.graphics.clear(132, 209, 227, 255) --sky color
    love.graphics.draw(sprites.background, -rockdata.pos.x, 0)
    local r = rockdata
    love.graphics.draw(sprites.rock, r.offset.x, (love.graphics.getHeight() - r.pos.y), r.rot, r.scl, r.scl, sprites.rock:getWidth()/2, sprites.rock:getHeight()/2)
end
