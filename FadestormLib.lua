--[[
--    Copyright (C) 2024 Fadestorm-Faerlina (Discord: hatefiend)
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--


local MODULE_NAME = "FadestormLib"
--[[ __VERSION_MARKER__ ]]--
local VERSION = { major = 7, minor = 1, patch = 0, build_date = 2024-01-24 }


-- Core module table
local FSL = (function()
	if IsAddOnLoaded and IsAddOnLoaded(...) then -- World of Warcraft-specific loading
		return LibStub and LibStub:NewLibrary(MODULE_NAME .. "-" .. VERSION.major, VERSION.minor) or nil
	elseif game and workspace and game:GetService("Players") then -- Roblox-specific loading
		return { }
	elseif os and io and package then -- Standalone-specific loading
		return { }
	end
end)() if FSL == nil then return end -- Terminate module if loading is unsuitable

setfenv(1, setmetatable({ _G = _G }, -- Setup environment
		{
			__newindex = FSL,
			__index = (function()
				local _G = _G  -- Maintain refernce to global namespace
				return function(_, key)
					local v = FSL[key] -- Prioritize FSL table for lookups
					if v == nil then v = _G[key] end -- Global namespace
					return v end
			end)(),
			__metatable = false
		}))

-- Imported standard library functions
local upper, lower, format = string.upper, string.lower, string.format
local concat, insert = table.concat, table.insert
local next, setmetatable, type, pairs, ipairs = next, setmetatable, type, pairs, ipairs

-- Utility functions
local function SENTINEL() end -- Unique pointer
local function IDENTITY(x) return x end -- Returns argument

-- Forward declarations for circular function dependencies
Type = { TABLE = IDENTITY, STRING = IDENTITY, FUNCTION = IDENTITY }
Error = { TYPE_MISMATCH = SENTINEL, UNSUPPORTED_OPERATION = SENTINEL }

--[[
-- Constructs a new meta-table, creating a read-only table when set as a metatable
--
-- @param [meta_methods] [table] (Optional) Meta-methods to be copied into the resulting meta table
-- @return [table] Read-only meta-table
]]--
local init_read_only_mt = (function()
	local function read_only_error()
		Error.UNSUPPORTED_OPERATION(MODULE_NAME, "Ready-only table cannot be modified.") end
	return function(meta_methods)
		local mt = {
			__newindex = read_only_error,
			__metatable = false, -- Protect metatable
		}
		if meta_methods ~= nil then
			for k, v in pairs(meta_methods) do -- Add any meta method that isn't already reserved
				if mt[k] == nil then mt[k] = v end end
		end
		return mt
	end
end)()


Table = (function()
	local self = {
		--[[
		-- Constructs a read-only view into a private table
		--
		-- Read-only tables cannot be modified.
		-- An error will be thrown upon __newindex being called.
		-- Read-only tables do not support the length operator '#' (Lua 5.1 limitation)
		-- Calling 'getmetatable(...)' will retrieve the length of the underlying table.
		--
		-- Meta-methods may be provided in order to further customize the read-only table.
		-- '__metatable', '__index', and '__newindex' meta-methods are ignored.
		--
		-- @param private [table] Map of fields
		-- @param [meta_methods] [table] Optional. Meta_methods to be included into the table
		-- @return [table] Read-only variant of the private table
		]]--
		read_only = function(private, meta_methods)
			local mt = init_read_only_mt({ __index = Type.TABLE(private) })
			if meta_methods ~= nil then -- User wants additional meta-methods included
				for k, v in pairs(Type.TABLE(meta_methods)) do
					if mt[k] == nil then -- Existing meta-methods cannot be overwritten
						mt[k] = v end end
			end
			return setmetatable({}, mt)
		end,

		--[[
		-- Associates the key with the default value, if said key has no existing pairing, then returns the current value
		--
		-- @param tbl [table] Table to query
		-- @param key [?] Key of the pairing
		-- @param default_value [?] Value to be paired if the key is not present
		-- @return [?] Resulting value of the key-value pairing
		]]--
		put_default = function(tbl, key, default_value)
			local v = Type.TABLE(tbl)[key]
			if v == nil then
				tbl[key] = default_value
				return default_value end
			return v
		end,

		--[[
		-- Associates the key with a computed value, if said key has no existing pairing, then returns the current value
		--
		-- @param tbl [table] Table to query
		-- @param key [?] Key of the pairing
		-- @param computer [function] Value to be paired if the key is not present
		-- @return [?] Resulting value of the key-value pairing
		]]--
		put_compute = function(tbl, key, computer)
			local v = Type.TABLE(tbl)[key]
			if v == nil then
				v = Type.FUNCTION(computer)(key)
				tbl[key] = v
			end
			return v
		end,

		--[[
		-- Constructs a set of specified values
		--
		-- Each value of the set is associated with boolean 'true'
		--
		-- @param [varargs] Values of the set
		-- @return [table] Set of values
		]]--
		set = function(...)
			local t = { }
			for _, e in ipairs({ ... }) do
				t[e] = true end
			return t
		end,

		--[[
		-- Sorts a table, using a custom comparator
		--
		-- Implementation uses a 2-partition Quicksort
		--
		-- @param tbl [table] Table to be sorted
		-- @param comparator [function] Compares two elements, returning domain [-1, 1]
		]]--
		sort = (function()
			local function swap(tbl, i, j) -- Swaps two indexes of a table
				local temp = tbl[i] tbl[i] = tbl[j] tbl[j] = temp end

			local function part(tbl, comparator, a, b)
				local pivot = tbl[b] -- Pivot is always the right-hand element
				local wall = a - 1 -- Divides the table into partitions

				for i = a, b - 1 do -- Don't iterate on the pivot
					if Type.NUMBER(comparator(tbl[i], pivot)) <= 0 then
						wall = wall + 1
						swap(tbl, wall, i) -- Add element to left partition
					end
				end

				wall = wall + 1
				swap(tbl, wall, b) -- Place pivot in its solved index
				return wall
			end

			local function quick(tbl, comparator, a, b)
				if a < b then -- Table is not yet sorted
					local pivot = part(tbl, comparator, a, b)
					quick(tbl, comparator, a, pivot - 1)
					quick(tbl, comparator, pivot + 1, b)
				end
			end

			return function(tbl, comparator)
				quick(Type.TABLE(tbl), Type.FUNCTION(comparator), 1, #tbl)
			end
		end)()
	}

	return self:read_only()
end)()


--[[
-- Version information
--
-- @field version [string] MAJOR.MINOR.PATCH
-- @field major [number] Backwards-incompatible/milestone change number
-- @field minor [number] Backward-compatible enhancements change number
-- @field patch [number] Bug fixes/minor improvements change number
-- @field build_date [string] YYYY-MM-DD date in which commit was pushed
-- @field author [string] Repository author
-- @field license [string] Repository license
-- @field repository [string] Repository URL
-- @field cmp [function] Compares this version table with another version table
--		@param version [table] Version table in which to compare against
--		@return [number] Negative/positive integer if this version is behind/ahead, otherwise 0
-- @field __call [function] Equivalent to `cmp`
-- @field __tostring [string] Equivalent to `version`
]]--
FSL.VERSION = (function()
	local function compare_versions(X, Y)
		return (X.MAJOR ~= Y.MAJOR and X.MAJOR - Y.MAJOR) or
				(X.MINOR ~= Y.MINOR and X.MINOR - Y.MINOR) or (X.PATCH - Y.PATCH)
	end
	local function check_version_tbl(v)
		Type.TABLE(v); Type.NUMBER(v.MAJOR); Type.NUMBER(v.MINOR); Type.NUMBER(v.PATCH) return v end

	for k, v in pairs({
		author = "Kevin Tyrrell",
		repository = "github.com/KevinTyrrell/FadestormLib",
		license = "MIT",
		version = format("%d.%d.%d", VERSION.MAJOR, VERSION.minor, VERSION.patch),
		cmp = function(version)
			return compare_versions(VERSION, check_version_tbl(version)) end
	}) do VERSION[k] = v end

	return Table.read_only(VERSION, {
		__tostring = function(tbl) return tbl.version end,
		__call = function(_, ...) return compare_versions(VERSION, check_version_tbl(...)) end
	})
end)()


--[[
-- Defines an enumeration
--
-- Enum Class Members
-- =======================
-- * size [number]: Number of declared enumeration constants
-- * Enum constants access [i] , where `i` is the ordinal of the constant
-- * Enum constants access s, where `s` is the identifier of the constant
-- * function stream(): Returns a stream of all instances of the enum
-- * function assert_instance(tbl): Returns param & checks it is an enum instance
--
-- Enum Constants Members
-- =======================
-- * ordinal [number]: Position of the instance within the enum's natural order
-- * name [string]: Name of the enum constant, automatically capitalized
-- * function __lt(value): Returns `true` if the instance's ordinal is lesser
-- * function __lte(value): Returns `true` if the instance's ordinal not greater
-- * function __tostring(): Returns the string representation of the instance
--
-- Enum Callback (Constructor)
-- =======================
-- Callback constructor should instantiate any additional enum instance members
-- 	callback(instance, members)
--  	@param instance [table] Read-only enum instance
--		@param members [table] Mutable enum instance members
--
-- @param values [table] Constants (strings) of the enum
-- @param callback [function] Constructor for each enum instance
-- @param [meta_methods] [table] (Optional) Meta-methods to attach to instances
-- @return [table] Enum read-only class members
-- @return [table] Enum mutable class members
]]--
function Enum(values, callback, meta_methods)
	local cls_members = { } -- Entry point to declare and mutate class members
	-- Class members which cannot be overridden
	local cls_reserved = setmetatable({
		size = #Type.TABLE(values) -- Number of enumeration instances
	}, { __index = cls_members })
	local cls_read_only = setmetatable({ }, init_read_only_mt({
		__index = cls_reserved -- Defer all searching to the reserved members table
	}))

	local ro_to_reserved = { } -- Map[Read Only Table] --> Reserved Table
	for ordinal, name in ipairs(Type.TABLE(values)) do
		name = upper(Type.STRING(name))
		local reserved = { -- Instance members which cannot be overridden
			ordinal = ordinal,
			name = name
		}
		local ro_instance = { } -- Create a read-only entry point into the instance

		ro_to_reserved[ro_instance] = reserved -- Needed for __index in instance meta-table
		cls_reserved[name] = ro_instance -- Allow name -> Enum Instance queries
		cls_reserved[ordinal] = ro_instance -- Allow ordinal -> Enum Instance queries
	end

	local instance_mt = init_read_only_mt({ -- -- Shared among all instances of the Enum
		__lt = function(t1, t2) return t1.ordinal < t2.ordinal end,
		__lte = function(t1, t2) return t1.ordinal <= t2.ordinal end,
		__tostring = function(tbl) return tbl.name end
	})

	if meta_methods ~= nil then -- Optional param, allow user to declare their own meta-methods
		for meta_method, func in pairs(Type.TABLE(meta_methods)) do
			instance_mt[meta_method] = Type.FUNCTION(func) end end
	instance_mt.__index = function(instance, key) -- All instances share meta-table, so perform a lookup on-the-fly
		return ro_to_reserved[instance][key] end -- Defer searching to the reserved table

	Type.FUNCTION(callback)
	for ordinal in ipairs(values) do
		-- Ensure all instances of the enum share the same meta-table
		local read_only = setmetatable(cls_reserved[ordinal], instance_mt)
		local members = { } -- Allows defining of members for the enum instance
		setmetatable(ro_to_reserved[read_only], {
			__index = members -- Defer searching to the members table if key not found
		})
		callback(read_only, members) -- Pseudo constructor for the user to define members
	end

	function cls_members.stream() -- Stream support
		return map(num_stream(1, cls_read_only.size),
				function(n) return n, cls_read_only[n] end)
	end

	function cls_members.assert_instance(tbl) -- Enum type-checking
		if ro_to_reserved[Type.TABLE(tbl)] == nil then
			Error.TYPE_MISMATCH(MODULE_NAME, "Table parameter is not an instance of the enum.") end
		return tbl
	end

	return cls_read_only, cls_members
end


--[[
-- Type Enum
--
-- Type Constants
-- =======================
-- * Type.NIL: Represents a nil value
-- * Type.STRING: Represents a string
-- * Type.BOOLEAN: Represents a boolean
-- * Type.NUMBER: Represents a number
-- * Type.FUNCTION: Represents a function
-- * Type.USERDATA: Represents userdata
-- * Type.THREAD: Represents a thread
-- * Type.TABLE: Represents a table
--
-- Type Constants Members
-- =======================
-- * type [string]: Type of the enum, same value as returned by Lua's type() function
-- * function match(value): Returns `true` if the type of the parameter matches the instance's type
-- * function __call(value): Type instances override `__call`
--   * @param value [?] Value to be type-checked
--   * @return [?] Value which was passed-in
--   * @error TYPE_MISMATCH If the parameter's type does not match the instance
]]--
Type = (function()
	local cls, members = Enum({ "NIL", "STRING", "BOOLEAN", "NUMBER",
								"FUNCTION", "USERDATA", "THREAD", "TABLE" },
			function(instance, members)
				members.type = lower(instance.name)
				function members.match(value) return members.type == type(value) end
			end, {
				__call = function(tbl, value)
					if tbl.type ~= type(value) then Error.TYPE_MISMATCH(MODULE_NAME,
							"Received: <", type(value),  "> Expected: <", tbl.type, ">") end
					return value
				end
			})

	--[[
    -- Ensures a specified parameter is non-nil
    --
    -- An argument whose value is nil will result in an NIL_POINTER error
    --
    -- @param [?] x Parameter to check
    -- @return [?] x
    ]]--
	function members.non_nil(x)
		if x == nil then
			Error.NIL_POINTER(MODULE_NAME, "Required non-nil argument was nil.") end
		return x
	end

	return cls
end)()


--[[
-- Error Enum
--
-- Error Constants
-- =======================
-- * Error.UNSUPPORTED_OPERATION: Signifies the function is not supported or not yet declared
-- * Error.TYPE_MISMATCH: Signifies that the type of a value was not of the expected type
-- * Error.NIL_POINTER: Signifies expected non-nil value was nil
-- * Error.ILLEGAL_ARGUMENT: Signifies the provided parameter was not within accepted bounds
-- * Error.ILLEGAL_STATE: Signifies the function or object has entered an unrecoverable state
--
-- Type Constants Members
-- =======================
-- * formal [string]: Formal name of the error
-- * function __call(value): Error instances override `__call`
--   * @param source [string] Addon/library responsible for throwing the error
--	 * @param msg [string] Error message to be raised
--   * @error TYPE_MISMATCH If the parameter's type does not match the instance
]]--
Error = (function()
	local src_color, msg_color = "ECBC2A", "FF0000" -- Gold, Red
	local c_ret, c_prefix = "\124r", "\124cFF" -- \124 => '|', cFF => 100% Opacity
	src_color, msg_color = c_prefix .. src_color, c_prefix .. msg_color

	local values = { "UNSUPPORTED_OPERATION", "TYPE_MISMATCH", "NIL_POINTER", "ILLEGAL_ARGUMENT", "ILLEGAL_STATE" }
	local formals =  { "Unsupported Operation", "Type Mismatch", "Nil Pointer", "Illegal Argument", "Illegal State" }
	-- e.g. "[FadestormLib] Type Mismatch: Expected String, Received Number"
	local ERROR_FMT = c_ret .. "[" .. src_color .. "%s" .. c_ret .. "] %s: " .. msg_color .. "%s" .. c_ret

	return Enum(values, function(instance, members)
		members.formal = formals[instance.ordinal]
	end, {
		__tostring = function(tbl) return tbl.formal end,
		__call = function(tbl, source, ...)
			msg = format(ERROR_FMT, Type.STRING(source), tbl.formal, concat({ ... }, " "))
			print(msg) error(msg)
		end
	})
end)()


--[[
-- Color Enum
--
-- Defines a text color interface (enum constants found below)
--
-- Determines the complementary color of a specified color hex string
--
-- __call meta-method
-- Wraps the specified string with the color
-- @param value [string] String to be colored
-- @return [string] Colored string
--
-- complement method
-- @return [string] Hex color which is a complement of the color
]]--
Color = (function()
	local C_NAMES = {
		"WARRIOR", "WARLOCK", "SHAMAN", "ROGUE", "PRIEST", "PALADIN", "MAGE", "HUNTER", "DRUID", "DEATHKNIGHT", -- Class
		"CHANNEL", "SYSTEM", "GUILD", "OFFICER", "PARTY", "SAY", "WHISPER", "YELL", "EMOTE", "RAID", "RAIDW", "BNET", -- Chat
		"POOR", "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "HEIRLOOM", -- Item Quality
		"WHITE", "BLACK", "RED", "BLUE", "YELLOW", "GREEN", "ORANGE", "PURPLE", "AMBER", "VERMILLION", -- Color Wheel
		"MAGENTA", "VIOLET", "TEAL", "CHARTREUSE", "PINK", "BROWN", "GRAY", "NAVY", "MAROON",
		"OLIVE", "LIME", "CYAN", "SILVER", "GOLD", "INDIGO", "TURQUOISE", "CORAL", "SALMON" }

	local C_CODES = {
		"C69B6D", "8788EE", "0070DD", "FFF468", "FFFFFF", "F48CBA", "3FC7EB", "AAD372", "FF7C0A", "C41E3A", -- Class
		"FEC1C0", "FFFF00", "3CE13F", "40BC40", "AAABFE", "FFFFFF", "FF7EFF", "FF3F40", "FF7E40", "FF7D01", "FF4700", "00FAF6", -- Chat
		"889D9D", "FFFFFF", "1EFF0C", "0070FF", "A335EE", "FF8000", "E6CC80", -- Item Quality
		"FFFFFF", "000000", "FF0000", "0000FF", "FFFF00", "00FF00", "FFA500", "A020F0", "FFBF00", "E34234", -- Color Wheel
		"FF00FF", "8F00FF", "008080", "7FFF00", "FFC0CB", "A52A2A", "808080", "000080", "800000",
		"808000", "00FF00", "00FFFF", "C0C0C0", "FFD700", "4B0082", "40E0D0", "FF7F50", "FA8072" }
	local STR_FMT = "|cFF%s%s|r"

	return Enum(C_NAMES, function(instance, members)
		members.code = C_CODES[instance.ordinal]
		members.complement = function()
			-- '%X' Converts to hex. '16777215'b10 = FFFFFFb16. FFFFFF-Color=Complement Color.
			return format('%X', 16777215 - tonumber(h, 16)) end
	end, {
		__call = function(tbl, value)
			return format(STR_FMT, tbl.code, Type.STRING(value)) end,
		__tostring = function(tbl)
			return format(STR_FMT, tbl.code, tbl.name) end
	})
end)()


--[[
-- ==========================
-- ======= Stream API =======
-- ==========================
]]--

local function stream(iterable) -- Helper function
	return Type.TABLE.match(iterable) and next or Type.FUNCTION(iterable)
end


--[[
-- Filters an iterable stream, iterating over a designated subset of elements
--
-- This is an intermediate operation. Elements are not processed until stream termination
--
-- @param iterable [table][function] Stream in which to iterate
-- @param callback [function] Callback filter function
-- @return [function] Iterator
]]--
function filter(iterable, callback)
	Type.FUNCTION(callback)
	local iterator = stream(iterable)
	local key -- Iterator key parameter cannot be trusted due to key re-mappings
	return function()
		local value
		repeat key, value = iterator(iterable, key)
		until key == nil or callback(key, value) == true
		return key, value
	end
end


--[[
-- Maps an iterable stream, translating elements into different elements
--
-- This is an intermediate operation. Elements are not processed until stream termination
--
-- @param iterable [table][function] Stream in which to iterate
-- @param callback [function] Callback mapping function
-- @return [function] Iterator
]]--
function map(iterable, callback)
	Type.FUNCTION(callback)
	local iterator = stream(iterable)
	local key -- Iterator key parameter cannot be trusted due to key re-mappings
	return function()
		local value
		key, value = iterator(iterable, key)
		if key ~= nil then return callback(key, value) end
	end
end


-- TODO: Evaluate
-- Helper function for iterating through streams
local function explore(iterable)
	local iterator = stream(iterable)
	local key, value
	return function()
		key, value = iterator(iterable, key)
		if key ~= nil then return key, value end
	end
end


--[[
-- Maps each element into a new stream, then flattens the streams into a single stream
--
-- This is an intermediate operation. Elements are not processed until stream termination
--
-- @param [table][function] Stream in which to iterate
-- @param [function] Callback function which defines a new stream dimension per element
--		The callback should invoke a new stream, per element of the original stream.
--		The returned value should be a new stream. See @usage below for an example.
--		@param key [K] Key of the key/value pair
--		@param value [V] Value of the key/value
--		@return [table][function] Stream mapped from the key/value pair
-- @return [function] Iterator
--
-- @usage
-- local function callback(key, value) -- e.g. `value` is a table
		-- Create a new stream for every single element of the original stream
		return map(value, function(k, v) return k .. v, true end)
-- end
]]--
function flat_map(iterable, callback)
	local outer = explore(iterable)
	local k, v = outer()
	if k == nil then return function()end end -- Stream was empty
	local inner = explore(Type.FUNCTION(callback)(k, v))

	return function()
		while true do
			k, v = inner()
			if k == nil then
				k, v = outer() -- Stream exhausted, move to the next inner stream
				if k == nil then return end -- All inner streams exhausted
				inner = explore(callback(k, v))
			else return k, v end
		end
	end
end


--[[
-- Peeks an iterable stream, viewing each element
--
-- This is an intermediate operation. Elements are not processed until stream termination
--
-- @param iterable [table][function] Stream in which to iterate
-- @param callback [function] Callback peeking function
-- @return [function] Iterator
]]--
function peek(iterable, callback)
	Type.FUNCTION(callback)
	local iterator = stream(iterable)
	local key, value -- Iterator key parameter cannot be trusted due to key re-mappings
	return function()
		key, value = iterator(iterable, key)
		if key ~= nil then
			callback(key, value)
			return key, value
		end
	end
end


local function DEFAULT_COMPARING(_, value) return value end -- Default functionality for determining uniqueness


--[[
-- Streams over only unique elements of a stream
--
-- This is an intermediate operation. Elements are not processed until stream termination
--
-- By default, determines uniqueness of a key/value pair only by value.
-- To override this functionality, provide callback function `comparing`.
--
-- @param iterable [table][function] Stream in which to iterate
-- @param [comparing] [function] Optional. Returns a value determining the key/value pair's uniqueness
--		@param [K] Key of the key/value pair
--		@param [V] Value of the key/value pair
--		@return [?] Metric determining the key/value pair's uniqueness
]]--
function unique(iterable, comparing)
	comparing = comparing == nil and DEFAULT_COMPARING or Type.FUNCTION(comparing) -- Default to comparing by value
	local iterator = stream(iterable)
	local key, value
	local set = setmetatable({ }, { __mode = "k" }) -- weak table, as a precaution
	return function()
		while true do
			key, value = iterator(iterable, key)
			if key == nil then break end
			local uniqueness = Type.non_nil(comparing(key, value))
			if set[uniqueness] == nil then -- Never seen this element before
				set[uniqueness] = true -- Mark element as seen
				return key, value
			end
		end
	end
end


--[[
-- Constructs an iterable stream of numbers
--
-- If no step is provided, step increment defaults to 1/-1.
-- For positive steps, start <= stop must be true.
-- For negative steps, start >= stop must be true.
-- Steps of zero will result in an exception being thrown.
--
-- @param start [number] Starting number (inclusive) to iterate
-- @param stop [number] Stopping number (inclusive) to iterate to
-- @param step [number] (optional) Amount to step by each iteration
-- @return [function] Iterator
]]--
function num_stream(start, stop, step)
	if step ~= nil then
		if Type.NUMBER(step) == 0 then
			Error.ILLEGAL_ARGUMENT(MODULE_NAME, "Number stream step must be non-zero.") end
		-- Check for infinite loop scenarios, in both increasing/decreasing contexts
		if (Type.NUMBER(start) - Type.NUMBER(stop)) / step > 0 then
			Error.ILLEGAL_ARGUMENT(MODULE_NAME, "Number stream does not terminate: [", start, stop, step, "]") end
	elseif start < stop then step = 1 else step = -1 end

	return function() -- Simple iterator function
		if start > stop then return nil end
		local v = start
		start = start + step
		return v, v
	end
end


-- Default grouping parameters, load into table and append elements
local function DEFAULT_GROUPING_ACCUMULATOR() return { } end
local function DEFAULT_GROUPING_DOWNSTREAM(_, v, a) insert(Type.TABLE(a), Type.non_nil(v)) return a end


--[[
-- Groups, accumulates, and collects a stream based on a classifier
--
-- This is a terminating operation. All elements in the stream will be processed
--
-- `accumulator` and `downstream` callbacks are optional.
-- Default functionality places groups into tables and appends elements.
--
-- @param iterable [table][function] Stream in which to iterate
--
-- @param classifier [function] Maps key/value pairs into groups
--		@param key [K] Key of the key/value pair currently being streamed
--		@param value [V] Value of the key/value pair currently being streamed
--		@return [C] Grouping key in which the key/value pair will be accumulated
--
-- @param [accumulator] [function] Optional. Creates a new accumulator for a group
--		@return [A] Accumulator in which is assigned to each new classifier group
--
-- @param [downstream] [function] Optional. Adds key/value pairs into the accumulator
--		@param key [K] Key of the key/value pair currently being streamed
--		@param value [V] Value of the key/value pair currently being streamed
-- 		@param [A] Accumulator in which the key/value pair should be acccumulated into
--		@return [A] Mutated accumulator or new accumulator after accumulation
--
-- @return [table] Map[C, A] Classifiers -> Accumulators
]]--
function grouping(iterable, classifier, accumulator, downstream)
	accumulator = accumulator == nil and DEFAULT_GROUPING_ACCUMULATOR or Type.FUNCTION(accumulator)
	downstream = downstream == nil and DEFAULT_GROUPING_DOWNSTREAM or Type.FUNCTION(downstream)
	Type.FUNCTION(classifier)

	local iterator = stream(iterable)
	local groups = { }
	local key, value
	while true do
		key, value = iterator(iterable, key)
		if key == nil then break end
		local cls = Type.non_nil(classifier(key, value))
		local acc = groups[cls]
		if acc == nil then -- New classifier, request new accumulator
			acc = Type.non_nil(accumulator()) end
		-- Accumulate the pair and request updated accumulator
		groups[cls] = Type.non_nil(downstream(key, value, acc))
	end
	return groups
end


--[[
-- Collects a stream into a table
--
-- This is a terminating operation. All elements in the stream will be processed
--
-- Collecting a stream with duplicate keys will yield undefined behavior
--
-- @param iterable [table][function] Stream in which to iterate
-- @return [table] Elements of the stream
]]--
function collect(iterable)
	local iterator = stream(iterable)
	local tbl = { }
	local key, value
	while true do
		key, value = iterator(iterable, key)
		if key == nil then break end
		tbl[key] = value
	end
	return tbl
end


--[[
-- Iterates through elements of a stream
--
-- This is a terminating operation. All elements in the stream will be processed
--
-- @param iterable [table][function] Stream in which to iterate
-- @param callback [function] Callback for-each function
]]--
function for_each(iterable, callback)
	Type.FUNCTION(callback)
	local iterator = stream(iterable)
	local key, value
	while true do
		key, value = iterator(iterable, key)
		if key == nil then break end
		callback(key, value)
	end
end


--[[
-- Sorts and collects the elements of a stream
--
-- TODO: Convert this into an intermediate operation
-- TODO: Sorted should utilize insertion sort
-- TODO: If quicksort is to be used, the user can collect and table.sort
--
-- This is a terminating operation. All elements in the stream will be processed
]]--
function sorted(iterable, comparator)
	local t = collect(iterable)
	Table.sort(t, Type.FUNCTION(comparator))
	return t
end


--[[
-- ==========================
-- ======= String API =======
-- ==========================
]]--


String = Table.read_only({
    --[[
    -- Formalizes a string, capitalizing each word
    --
    -- Underscore characters passed in the parameter are treated as whitespace
    --
    -- @param s [string] String to be made into a title
    -- @return [string] Formalized string
    ]]--
	to_title_format = function(s)
		s = Type.STRING(s):gsub("_", " ") -- Consider `_` as word separators
		return (s:gsub("%w+", function(word)
			return word:sub(1, 1):upper() .. word:sub(2):lower() end))
	end
})


return Table.read_only(FSL) -- Allow `require` to load module
