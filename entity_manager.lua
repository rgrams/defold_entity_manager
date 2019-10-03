
-- version 3.0 for LÖVE2D
--
--		A subscription module for keeping track of existing entities---enemies, players, pickups, etc.
--
--		Copyright (c) 2019 Ross Grams
--[[
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
------------------------------------------------------------------------------------------------------

local M = {}

local defaultData = true
local MSG_SPAWN = 'entitySpawned' -- Method name called on listeners.
local MSG_DESTROY = 'entityDestroyed' -- Method name called on listeners.

local ent, sub, entCounts

-- Initialize the groups to be used.
-- Pass in any number of string group names or whatever you want to use for group keys.
function M.setGroups(...)
	ent, sub, entCounts = {}, {}, {}
	for _,group in ipairs({...}) do
		ent[group] = {}
		sub[group] = {}
		entCounts[group] = 0
	end
end

-- Called with the url of the subscribing object/component, and any number of groups to subscribe to.
-- Example: M.subscribe(obj, 'enemies', 'pickups')
function M.subscribe(obj, ...)
	assert(type(obj) == 'table', 'entity_manager.subscribe(obj, groups...) - "obj" is not a table.')
	for _, group in ipairs({...}) do
		table.insert(sub[group], obj)
	end
end

-- Likewise, to unsubscribe. Be sure to call this before being destroyed (you can call it in the script's final())
function M.unsubscribe(obj, ...)
	assert(type(obj) == 'table', 'entity_manager.subscribe(obj, groups...) - "obj" is not a table.')
	for _, group in ipairs({...}) do
		for i, listener in ipairs(sub[group]) do -- find and remove
			if listener == obj then
				table.remove(sub[group], i)
			end
		end
	end
end

-- Call this to register a new entity. You can call this in the new object's init().
-- The data is optional and can be any value.
function M.spawn(obj, group, data)
	data = data or defaultData
	ent[group][obj] = data
	entCounts[group] = entCounts[group] + 1
	for _, listener in ipairs(sub[group]) do
		listener:call(MSG_SPAWN, group, obj, data)
	end
end

-- Call this when an entity is destroyed.
-- The "entity destroyed" message includes the "last" property so you can tell when the last enemy is killed, etc.
function M.destroy(obj, group)
	local data = ent[group][obj]
	if data then
		ent[group][obj] = nil
		entCounts[group] = entCounts[group] - 1
		for _, listener in ipairs(sub[group]) do
			listener:call(MSG_DESTROY, group, obj, data, entCounts[group] == 0)
		end
	else
		print('WARNING - entity_manager.destroy() - entity not found.')
	end
end

-- Get the total number of entities in a group.
-- Example: M.getCount('enemies')
function M.getCount(group)
	return entCounts[group]
end

-- In case for some reason you need to get the whole list of entities in a group.
-- Returns a table something like this: {obj1 = data1, obj2 = data2}
function M.getGroup(group)
	return ent[group]
end

-- Get an entity's associated data. Also serves to check if an entity exists.
function M.getData(group, obj)
	return ent[group][obj]
end

-- Set the data associated with an entity. Returns true if successful or nil if the entity doesn't exist.
function M.setData(group, obj, data)
	if ent[group][obj] then
		ent[group][obj] = data
		return true
	end
end

-- Get a semi-random entity from a group. Will generally return the same one.
function M.getAny(group)
	local i, obj = next(ent[group])
	return obj
end

-- Gets a random entity from a group.
-- Returns nil if there are no entities in the specified group.
function M.getRandom(group)
	if entCounts[group] == 0 then
		return
	end
	local idx = love.math.random(1, entCounts[group])
	local count = 1
	for obj, data in pairs(ent[group]) do
		if count == idx then
			return obj, data
		else
			count = count + 1
		end
	end
end


return M
