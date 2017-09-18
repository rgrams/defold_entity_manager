# Defold Entity Manager

_version 2.0 -- (September 17th, 2017)_

This is a small Lua module for keeping track of existing entities of various types. Defold has no built-in way to check if an object exists, so this is my way of knowing if the enemy the player is targeting still exists, if any players are alive, if the enemy I just killed was the last one, when the player is killed, etc.

The module is fully commented with instructions and examples of use for each function, or you can read the slightly more thorough instructions below.

_Special thanks to solariyoung for testing and the getRandomEnt function!_

# Instructions

## Using a Lua Module

I suggest you read the [Lua module manual](https://www.defold.com/manuals/modules/) before using this or any other Lua module.

### Module Names

To use a module in a script you must first `require` it with a line of code like this:

```Lua
local M = require "entity_manager.entity_manager"
```

This will look for a module file named "entity_manager.lua" in the "entity_manager" folder, and name it "M" for the current script. Naming the module "M" is a nice convention for _writing_ modules, but it's kind of stupid to use that in your game scripts. You can name it whatever you want, I usually use "entman". So:

```Lua
local entman = require "entity_manager.entity_manager"
```

Then you will call module functions and access module properties with "entman" instead of "M".

```Lua
function init(self)
    entman.subscribe(msg.url("#"), entman.players)
end
```
I'll stick to using "M" here just to make things easier to read.


## Using the Entity Manager

This module creates a subscription system. Scripts in which you want to keep track of some entities should call `M.subscribe()` in their `init` function (or whenever you want them to start tracking entities) and `M.unsubscribe()` in their `final` function (or earlier). Likewise, entities that you want to track should call `M.spawn()` on `init`, and `M.destroy()` on `final`. The module will send "entity spawned" and "entity destroyed" messages to all subscribers for the appropriate group.

* Entities are classed into groups, and can be further identified by a "type".
	* Types are totally optional and you must deal with type checking in your own code.


* Entity groups must be hard-coded in this module.
	Just list their names in the "groupList" table, and add each one as a property of the module (just so autocomplete will work). I've put in groups for "enemies" and "players" as an example, but you can remove those if you want.

* Groups are stored as their hashed names, but refer to them with this module's properties, i.e. `M.enemies` or `M.players`.

* **IMPORTANT:** Entities are keyed by their url PATH, NOT the full url.
	The path is a hashed string which is a property of the full url (which is a userdata value and can't be used as a key). This means means that only the path to the _game object_ is stored, not to the specific component. (This, in turn, means you shouldn't have multiple scripts on an object that each register as an entity)

* Subscriptions, on the other hand, are handled with full urls. This is so there can be multiple scripts on one object subscribing to different groups.

### Functions

**M.subscribe(url, ...)**

Called with the url of the subscribing object/component, and any number of groups to subscribe to. Example:
```Lua
M.subscribe(msg.url("#"), M.enemies, M.pickups)
```

**M.unsubscribe(url, ...)**

Likewise, to unsubscribe. Be sure to call this before the object is destroyed (you can call it in the script's `final` function). Example:
```Lua
M.unsubscribe(msg.url("#"), M.enemies)
```

**M.spawn(path, group, type)**

Use this to register a new entity. You can call this in the new object's init function. Uses the object path, not the url! Example:
```Lua
M.spawn(msg.url().path, M.players)
```
The type is optional and can be any value except `nil` or `false`. I generally use hashed names. The default `noType` is `1`, but feel free to change that.

**M.destroy(path, group)**

Call this when an entity is destroyed. Example:
```Lua
M.destroy(msg.url().path, M.enemies)
```

**M.getCount(group)**

Get the total number of entities in a group. Example:
```Lua
M.getCount(M.enemies)
```

**M.getGroup(group)**

Gets the complete list of entities in a group.
Returns a table something like this: {path1 = type1, path2 = type2}
```Lua
M.getGroup(M.players)
```

**M.getAnEnt(group)**

Get a semi-random entity from a group. Returns `nil` if there are no entities in the specified group. It just grabs the first one it comes across, which will usually (but not always) be the same one. I use this for my enemies to get the ID of the player, since there's generally only one player. Example:
```Lua
if M.getCount(M.players) > 0 then self.target = M.getAnEnt(M.players) end
```

**M.getRandomEnt(group)**

Like the above, only truly random.
Returns `nil` if there are no entities in the specified group. Example:
```Lua
M.getRandomEnt(M.enemies)
```

### Messages

**"entity spawned", { group=..., entity=..., type=... }**

Sent to all group subscribers when an entity in that group is spawned.
* group <kbd>hash</kbd> -- The group that the entity was in. (_ex. `M.enemies`_) If you subscribe to multiple groups you may want to check this.
* entity <kbd>hash</kbd> -- The path to the entity game object. (_the one that it called M.spawn with_)
* type <kbd>any</kbd> -- The type of the entity. (_optional. 0 by default_)

**"entity destroyed", { group=..., entity=..., type=..., last=... }**

Sent to all group subscribers when an entity in that group is destroyed.
* group <kbd>hash</kbd> -- The group that the entity was in. (_ex. `M.enemies`_) If you subscribe to multiple groups you may want to check this.
* entity <kbd>hash</kbd> -- The path to the entity game object. (_the one that it called M.destroy with_)
* type <kbd>any</kbd> -- The type of the entity. (_optional. 0 by default_)
* last <kbd>bool</kbd> -- `true` if this entity was the last one in its group, otherwise `false`.

## Download

Since this module must be modified to add new groups, it is _not_ set up to be used as a [library dependency](https://www.defold.com/manuals/libraries/). Library dependencies are reloaded every time you start the editor, which would erase your changes. To download the module, right-click the following link and choose "Save Link As..."

https://github.com/rgrams/defold_entity_manager/raw/master/entity_manager.lua

Or create a new lua module on your drive and copy-paste [the code](https://github.com/rgrams/defold_entity_manager/blob/master/entity_manager.lua) into it.

## Other Tips

`msg.url()` is not the cheapest function in the world, so I usually only call it once in each script and store the result in a `self` property. For example:

```Lua
local entman = require "entman.entity_manager"

function init(self)
    self.url = msg.url("#")
    entman.subscribe(self.url, entman.enemies, entman.pickups)
    entman.spawn(self.url.path, entman.players)
end

function final(self)
    entman.unsubscribe(self.url, entman.enemies, entman.pickups)
    entman.destroy(self.url.path, entman.players)
end
```

## Feedback

If you have any feedback, complaints, feature requests, praise, or anything else to say about this module, please post in [the forum thread](https://forum.defold.com/t/entity-manager-module/10818), send me a message on the forum, or open a [Github issue](https://github.com/rgrams/defold_entity_manager/issues). Thanks!
