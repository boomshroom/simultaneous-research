---@class Debug
local debug = {}

function debug.research(command)
    if not command.parameter then command.parameter = "1" end
    local index = tonumber(command.parameter)
    local tech_queue = game.forces["player"].research_queue
    local tech = tech_queue[index]
    if not tech then return end
    research_tech(tech)
end

function debug.set_speed(command)
    if not command.parameter then command.parameter = "1" end
    CHEAT_SPEED_MULTIPLIER = tonumber(command.parameter)
end

function debug.set_productivity(command)
    if not command.parameter then command.parameter = "1" end
    CHEAT_PRODUCTIVITY_MULTIPLIER = tonumber(command.parameter)
end

commands.add_command("sr_research", nil, function(command) debug.research(command) end)
commands.add_command("sr_research_speed", nil, function(command) debug.set_speed(command) end)
commands.add_command("sr_research_productivity", nil, function(command) debug.set_productivity(command) end)