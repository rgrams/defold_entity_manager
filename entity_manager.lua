-- VERSION 2.0
--
--		A subscription module for keeping track of existing entities---enemies, players, pickups, etc.
------------------------------------------------------------------------------------------------------
-- 1. Entities are classed into groups, and can be further identified by a "type".
--		(Subscribers must deal with "type" checking in their own code.)
-- 2. Entity groups must be hard-coded in this module.
--		Just list their names in "groupList", below, plus a property for each one (just so autocomplete will work).
-- 3. Subscribers call M.subscribe when they want to start listening, and M.unsubscribe when they want to stop (or when they are deleted).
-- 4. Entities must call M.spawn when they are created and M.destroy when they are destroyed.
-- 5. Groups are stored as their hashed names, but refer to them with this module's properties, i.e. M.enemies or M.players.

-- 6. IMPORTANT: Entities are keyed by their url PATH, NOT the full url.
--		The path is a hashed string which is a property of the full url (which is a userdata value and can't be used as a key).
--		This removes the need to search the list for the right object, and makes it easier to store a "type" for each entity.
--		This means means that only the path to the game object is stored, not to the specific component.
--				(This, in turn, means you shouldn't have multiple scripts on an object that each register as an entity)

-- 7. Subscriptions, on the other hand, are handled with full urls.
--		This is so there can be multiple scripts on one object subscribing to different groups.


local M = {}

local noType = 1

--##########  Entity Groups  ##########
-- 	List your desired groups here as string names.
local groupList = {"players", "enemies"} -- these are here as an example, delete them if you want.
--	Also make a property for each one here.
M.players = hash("players")
M.enemies = hash("enemies")
--These could be generated in the 'for' loop below with `M[v] = hash(v)`, but then autocomplete wouldn't work.

-- Don't mess with these directly. Use the module functions to subscribe, unsubscribe, spawn, and destroy.
local ent = {}
local sub = {}
local entCounts = {}

for i,v in ipairs(groupList) do
	ent[M[v]] = {}
	sub[M[v]] = {}
	entCounts[M[v]] = 0
end


-- Called with the url of the subscribing object/component, and any number of groups to subscribe to.
-- Example: M.subscribe(msg.url("#"), M.enemies, M.pickups)
function M.subscribe(url, ...)
	assert(type(url) == "userdata" and url.path, "entity_manager.subscribe(url, group) - \"url\" is NOT a url.")
	for i, v in ipairs({...}) do
		table.insert(sub[v], url)
	end
end

-- Likewise, to unsubscribe. Be sure to call this before being destroyed (you can call it in the script's final())
-- Example: M.unsubscribe(msg.url("#"), M.enemies)
function M.unsubscribe(url, ...)
	assert(type(url) == "userdata" and url.path, "entity_manager.unsubscribe(url, group) - \"url\" is NOT a url.")
	for i, group in ipairs({...}) do
		for i, v in ipairs(sub[group]) do -- find and remove
			if v == url then
				table.remove(sub[group], i)
			end
		end
	end
end

-- Call this to register a new entity. You can call this in the new object's init(). Uses the object path, not the url!
-- The type is optional and can be any value. I generally use hashed names.
-- Example: M.spawn(msg.url().path, M.players)
function M.spawn(path, group, type)
	type = type or noType
	ent[group][path] = type
	entCounts[group] = entCounts[group] + 1
	for i, v in ipairs(sub[group]) do
		msg.post(v, "entity spawned", {group = group, entity = path, type = type})
	end
end

-- Call this when an entity is destroyed.
-- Example: M.destroy(msg.url().path, M.enemies)
-- The "entity destroyed" message includes the "last" property so you can tell when the last enemy is killed, etc.
function M.destroy(path, group)
	local type = ent[group][path]
	if type then
		ent[group][path] = nil
		entCounts[group] = entCounts[group] - 1
		for i, v in ipairs(sub[group]) do
			msg.post(v, "entity destroyed", {group = group, entity = path, type = type, last = entCounts[group] == 0})
		end
	else
		print("WARNING - entity_manager.destroy() - entity path not found.")
	end
end

-- Get the total number of entities in a group.
-- Example: M.getCount(M.enemies)
function M.getCount(group)
	return entCounts[group]
end

-- In case for some reason you need to get the whole list of entities in a group.
-- Returns a table something like this: {path1 = type1, path2 = type2}
function M.getGroup(group)
	return ent[group]
end

-- Get a semi-random entity from a group. I use this for my enemies to get the ID of the player.
-- Example: if M.getCount(M.players) > 0 then self.target = M.getAnEnt(M.players) end
function M.getAnEnt(group)
	for k,v in pairs(ent[group]) do
		return k
	end
end

-- Like the above, only truly random.
-- Returns nil if there are no entities in the specified group.
function M.getRandomEnt(group)
	if entCounts[group] == 0 then
		return
	end
	local idx = math.random(1, entCounts[group])
	local count = 1
	for path, type in pairs(ent[group]) do
		if count == idx then
			return path, type
		else
			count = count + 1
		end
	end
end


return M
