-- =============================================================================
-- funk.lua — Functional programming utilities for TurtleWoW / Lua 5.0
-- =============================================================================
-- Inspired by:
--   • underscore.lua  https://github.com/mirven/underscore.lua
--   • lodash           https://lodash.com/docs
--   • ramda            https://ramdajs.com/docs
--
-- TARGET: Lua 5.0 / World of Warcraft (TurtleWoW) add-on environment.
--
-- ┌──────────────────────── JS ↔ Lua quick-reference ────────────────────────┐
-- │ CONCEPT              │ JavaScript              │ Lua                      │
-- │──────────────────────┼─────────────────────────┼──────────────────────── │
-- │ Array index          │ 0-based  arr[0]         │ 1-based  arr[1]          │
-- │ Undefined / null     │ undefined / null        │ nil                      │
-- │ Length               │ arr.length              │ table.getn(arr)          │
-- │ String concat        │ "a" + "b"               │ "a" .. "b"               │
-- │ Arrow func           │ (x) => x * 2            │ function(x) return x*2 end│
-- │ Spread               │ fn(...args)             │ fn(unpack(args))         │
-- │ Destructure          │ const [a,b] = arr       │ local a,b = arr[1],arr[2]│
-- │ for-of               │ for (const v of arr)    │ for _,v in ipairs(arr)   │
-- │ Object literal       │ { key: value }          │ { key = value }          │
-- │ typeof               │ typeof x                │ type(x)                  │
-- │ true equality        │ ===                     │ == (Lua has no ===)      │
-- │ Ternary              │ cond ? a : b            │ cond and a or b          │
-- └──────────────────────────────────────────────────────────────────────────┘
--
-- USAGE (WoW .toc addon — no global pollution):
--   local _, ns = ...           -- WoW passes (addonName, addonTable) to every file
--   local F = ns.funk           -- populated by funk.lua when loaded earlier in .toc
--
-- USAGE (standalone / dofile):
--   local F = dofile("funk.lua")  -- return value is the funk table
--
--   F.map({1,2,3}, function(x) return x * 2 end)  --> {2, 4, 6}
--   F.filter({1,2,3,4}, function(x) return math.mod(x, 2) == 0 end)  --> {2, 4}
--   F.reduce({1,2,3,4}, 0, function(acc, x) return acc + x end)  --> 10
-- =============================================================================

-- WoW's .toc loader passes (addonName, addonTable) as varargs to every file.
-- Capturing them here lets us share values via the per-addon namespace table
-- instead of writing to _G.  When loaded via dofile() both will be nil.
local _addonName, _ns = arg[1], arg[2]

local funk = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- _iter: returns a coroutine-based iterator over a plain table *or* passes
-- through an already-callable iterator function.
-- In JS terms: converts an Array or Iterable into an iterator.
local function _iter(list_or_iter)
    if type(list_or_iter) == "function" then
        return list_or_iter
    end
    -- Wrap the array in a coroutine so all collection functions share one
    -- iteration path.  Lua coroutines are roughly analogous to JS generators.
    return coroutine.wrap(function()
        for i = 1, table.getn(list_or_iter) do
            coroutine.yield(list_or_iter[i])
        end
    end)
end

-- _identity: returns its argument unchanged (lodash _.identity / ramda R.identity).
local function _identity(x)
    return x
end

-- _noop: does nothing (lodash _.noop).
local function _noop() end

-- _toarray: collect an iterator into a plain array table.
local function _toarray(list)
    if type(list) == "table" then return list end
    local arr = {}
    for v in list do
        arr[table.getn(arr) + 1] = v
    end
    return arr
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 1 — COLLECTION FUNCTIONS
-- Operate on arrays (sequential tables, 1-indexed) and iterator functions.
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.each(list, iteratee)
-- lodash: _.forEach   ramda: R.forEach
-- JS equivalent: arr.forEach(fn)
--
-- Calls `iteratee(value)` for every element.
-- Returns the original list unchanged (side-effects only).
-- Note: Lua has no implicit `this`; the element is always the first argument.
-- -----------------------------------------------------------------------------
function funk.each(list, iteratee)
    for v in _iter(list) do
        iteratee(v)
    end
    return list
end
funk.forEach  = funk.each
funk.for_each = funk.each

-- -----------------------------------------------------------------------------
-- funk.eachWithIndex(list, iteratee)
-- lodash: _.forEach (callback receives value, index)
-- JS equivalent: arr.forEach((v, i) => ...)
--
-- Calls `iteratee(value, index)` — index is 1-based in Lua.
-- -----------------------------------------------------------------------------
function funk.eachWithIndex(list, iteratee)
    local arr = _toarray(list)
    for i = 1, table.getn(arr) do
        iteratee(arr[i], i)
    end
    return arr
end

-- -----------------------------------------------------------------------------
-- funk.map(list, iteratee)
-- lodash: _.map   ramda: R.map
-- JS equivalent: arr.map(fn)
--
-- Returns a *new* table where each element is the result of iteratee(value).
-- The original list is never modified (pure function, like ramda).
-- -----------------------------------------------------------------------------
function funk.map(list, iteratee)
    local result = {}
    for v in _iter(list) do
        result[table.getn(result) + 1] = iteratee(v)
    end
    return result
end
funk.collect = funk.map

-- -----------------------------------------------------------------------------
-- funk.mapWithIndex(list, iteratee)
-- lodash: _.map (callback receives value, index)
-- JS equivalent: arr.map((v, i) => ...)
-- -----------------------------------------------------------------------------
function funk.mapWithIndex(list, iteratee)
    local arr = _toarray(list)
    local result = {}
    for i = 1, table.getn(arr) do
        result[i] = iteratee(arr[i], i)
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.reduce(list, accumulator, iteratee)
-- lodash: _.reduce   ramda: R.reduce
-- JS equivalent: arr.reduce(fn, initialValue)
--
-- Note the argument ORDER DIFFERENCE from JS:
--   JS:   arr.reduce((acc, val) => ..., initial)
--   Lua:  funk.reduce(arr, initial, function(acc, val) ... end)
-- The accumulator/memo is the SECOND argument here, not inside the callback.
-- -----------------------------------------------------------------------------
function funk.reduce(list, accumulator, iteratee)
    local memo = accumulator
    for v in _iter(list) do
        memo = iteratee(memo, v)
    end
    return memo
end
funk.foldl  = funk.reduce
funk.inject = funk.reduce

-- -----------------------------------------------------------------------------
-- funk.reduceRight(list, accumulator, iteratee)
-- lodash: _.reduceRight   ramda: R.reduceRight
-- JS equivalent: arr.reduceRight(fn, initialValue)
--
-- Iterates from the last element to the first.
-- -----------------------------------------------------------------------------
function funk.reduceRight(list, accumulator, iteratee)
    local arr  = _toarray(list)
    local memo = accumulator
    for i = table.getn(arr), 1, -1 do
        memo = iteratee(memo, arr[i])
    end
    return memo
end
funk.foldr = funk.reduceRight

-- -----------------------------------------------------------------------------
-- funk.filter(list, predicate)
-- lodash: _.filter   ramda: R.filter
-- JS equivalent: arr.filter(fn)
--
-- Returns a new table with only the elements for which predicate returns truthy.
-- Lua truthy: anything except `false` and `nil`.  0 and "" ARE truthy in Lua!
-- (Different from JavaScript where 0 and "" are falsy.)
-- -----------------------------------------------------------------------------
function funk.filter(list, predicate)
    local result = {}
    for v in _iter(list) do
        if predicate(v) then
            result[table.getn(result) + 1] = v
        end
    end
    return result
end
funk.select = funk.filter

-- -----------------------------------------------------------------------------
-- funk.reject(list, predicate)
-- lodash: _.reject   ramda: R.reject
-- JS equivalent: arr.filter(v => !fn(v))
--
-- Opposite of filter — keeps elements for which predicate returns falsy.
-- -----------------------------------------------------------------------------
function funk.reject(list, predicate)
    local result = {}
    for v in _iter(list) do
        if not predicate(v) then
            result[table.getn(result) + 1] = v
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.find(list, predicate)
-- lodash: _.find   ramda: R.find
-- JS equivalent: arr.find(fn)
--
-- Returns the *first* element for which predicate is truthy, or nil.
-- JS returns `undefined` when nothing matches; Lua returns `nil`.
-- -----------------------------------------------------------------------------
function funk.find(list, predicate)
    for v in _iter(list) do
        if predicate(v) then return v end
    end
    return nil
end
funk.detect = funk.find

-- -----------------------------------------------------------------------------
-- funk.findIndex(list, predicate)
-- lodash: _.findIndex
-- JS equivalent: arr.findIndex(fn)
--
-- Returns the 1-based index of the first matching element, or -1.
-- JS returns -1 when not found; this matches that convention.
-- -----------------------------------------------------------------------------
function funk.findIndex(list, predicate)
    local arr = _toarray(list)
    for i = 1, table.getn(arr) do
        if predicate(arr[i]) then return i end
    end
    return -1
end

-- -----------------------------------------------------------------------------
-- funk.every(list, predicate)
-- lodash: _.every   ramda: R.all
-- JS equivalent: arr.every(fn)
--
-- Returns true only if predicate returns truthy for ALL elements.
-- Returns true for an empty list (vacuous truth — same as JS).
-- -----------------------------------------------------------------------------
function funk.every(list, predicate)
    predicate = predicate or _identity
    for v in _iter(list) do
        if not predicate(v) then return false end
    end
    return true
end
funk.all = funk.every

-- -----------------------------------------------------------------------------
-- funk.some(list, predicate)
-- lodash: _.some   ramda: R.any
-- JS equivalent: arr.some(fn)
--
-- Returns true if predicate returns truthy for AT LEAST ONE element.
-- Returns false for an empty list (same as JS).
-- -----------------------------------------------------------------------------
function funk.some(list, predicate)
    predicate = predicate or _identity
    for v in _iter(list) do
        if predicate(v) then return true end
    end
    return false
end
funk.any = funk.some

-- -----------------------------------------------------------------------------
-- funk.includes(list, value)
-- lodash: _.includes   ramda: R.includes
-- JS equivalent: arr.includes(value)
--
-- Returns true if `value` appears in the list (uses == equality).
-- Lua has no strict equality (===); == is used for all types.
-- -----------------------------------------------------------------------------
function funk.includes(list, value)
    for v in _iter(list) do
        if v == value then return true end
    end
    return false
end
funk.include  = funk.includes
funk.contains = funk.includes

-- -----------------------------------------------------------------------------
-- funk.pluck(list, key)
-- lodash: _.map(list, key)   ramda: R.pluck
-- JS equivalent: arr.map(obj => obj[key])
--
-- Extracts a named property from every element in the list.
-- -----------------------------------------------------------------------------
function funk.pluck(list, key)
    return funk.map(list, function(v) return v[key] end)
end

-- -----------------------------------------------------------------------------
-- funk.invoke(list, methodName, ...)
-- lodash: _.invokeMap
-- JS equivalent: arr.forEach(obj => obj[method](...args))
--
-- Calls the named method on every element, passing extra args.
-- In Lua you must pass the object itself as first arg: obj:method(...)
-- -----------------------------------------------------------------------------
function funk.invoke(list, methodName, ...)
    local args = arg
    funk.each(list, function(obj)
        obj[methodName](obj, unpack(args))
    end)
    return list
end

-- -----------------------------------------------------------------------------
-- funk.groupBy(list, iteratee)
-- lodash: _.groupBy   ramda: R.groupBy
-- JS equivalent: _.groupBy(arr, fn)  (lodash syntax closest)
--
-- Returns a table whose keys are the results of iteratee and values are arrays
-- of elements that produced that key.
-- iteratee can be a function OR a string key name.
-- -----------------------------------------------------------------------------
function funk.groupBy(list, iteratee)
    local fn = type(iteratee) == "function" and iteratee
               or function(v) return v[iteratee] end
    local result = {}
    for v in _iter(list) do
        local k = fn(v)
        if result[k] == nil then result[k] = {} end
        result[k][table.getn(result[k]) + 1] = v
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.countBy(list, iteratee)
-- lodash: _.countBy
-- JS equivalent: _.countBy(arr, fn)
--
-- Like groupBy but returns counts instead of arrays.
-- -----------------------------------------------------------------------------
function funk.countBy(list, iteratee)
    local fn = type(iteratee) == "function" and iteratee
               or function(v) return v[iteratee] end
    local result = {}
    for v in _iter(list) do
        local k = fn(v)
        result[k] = (result[k] or 0) + 1
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.partition(list, predicate)
-- lodash: _.partition   ramda: R.partition
-- JS equivalent: [arr.filter(fn), arr.filter(v => !fn(v))]
--
-- Returns TWO tables: { matching, nonMatching }.
-- Note: Lua returns multiple values; use:
--   local yes, no = unpack(funk.partition(arr, fn))
-- -----------------------------------------------------------------------------
function funk.partition(list, predicate)
    local yes, no = {}, {}
    for v in _iter(list) do
        if predicate(v) then
            yes[table.getn(yes) + 1] = v
        else
            no[table.getn(no) + 1] = v
        end
    end
    return {yes, no}
end

-- -----------------------------------------------------------------------------
-- funk.sortBy(list, iteratee)
-- lodash: _.sortBy   ramda: R.sortBy
-- JS equivalent: [...arr].sort((a,b) => fn(a) < fn(b) ? -1 : 1)
--
-- Returns a new sorted array.  iteratee can be a function or a string key.
-- Lua's table.sort is an in-place unstable sort; we copy first to stay pure.
-- -----------------------------------------------------------------------------
function funk.sortBy(list, iteratee)
    local fn = type(iteratee) == "function" and iteratee
               or function(v) return v[iteratee] end
    local arr = {}
    for v in _iter(list) do arr[table.getn(arr) + 1] = v end
    table.sort(arr, function(a, b) return fn(a) < fn(b) end)
    return arr
end

-- -----------------------------------------------------------------------------
-- funk.sort(list, comparator)
-- lodash: _.sortBy (with explicit comparator)
-- JS equivalent: [...arr].sort(comparator)
--
-- Returns a new sorted copy using the raw comparator function.
-- Comparator must return true when a should come before b (like JS's < 0).
-- Note: JS comparators return a number; Lua comparators return a boolean.
-- -----------------------------------------------------------------------------
function funk.sort(list, comparator)
    local arr = {}
    for v in _iter(list) do arr[table.getn(arr) + 1] = v end
    table.sort(arr, comparator)
    return arr
end

-- -----------------------------------------------------------------------------
-- funk.min(list, iteratee) / funk.max(list, iteratee)
-- lodash: _.minBy / _.maxBy   ramda: R.minBy / R.maxBy
-- JS equivalent: arr.reduce((min, v) => fn(v) < fn(min) ? v : min)
--
-- Returns the element (not the value) with the smallest/largest computed score.
-- iteratee defaults to identity so plain number arrays work without a function.
-- -----------------------------------------------------------------------------
function funk.min(list, iteratee)
    local fn = iteratee or _identity
    return funk.reduce(list, {item = nil, score = nil}, function(acc, v)
        local s = fn(v)
        if acc.item == nil or s < acc.score then
            return {item = v, score = s}
        end
        return acc
    end).item
end

function funk.max(list, iteratee)
    local fn = iteratee or _identity
    return funk.reduce(list, {item = nil, score = nil}, function(acc, v)
        local s = fn(v)
        if acc.item == nil or s > acc.score then
            return {item = v, score = s}
        end
        return acc
    end).item
end

-- -----------------------------------------------------------------------------
-- funk.sum(list, iteratee)
-- lodash: _.sumBy
-- JS equivalent: arr.reduce((s, v) => s + fn(v), 0)
-- -----------------------------------------------------------------------------
function funk.sum(list, iteratee)
    local fn = iteratee or _identity
    return funk.reduce(list, 0, function(acc, v) return acc + fn(v) end)
end

-- -----------------------------------------------------------------------------
-- funk.mean(list, iteratee)
-- lodash: _.meanBy
-- JS equivalent: arr.reduce(...) / arr.length
-- -----------------------------------------------------------------------------
function funk.mean(list, iteratee)
    local arr = _toarray(list)
    if table.getn(arr) == 0 then return 0 end
    return funk.sum(arr, iteratee) / table.getn(arr)
end
funk.average = funk.mean

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 2 — ARRAY FUNCTIONS
-- Functions specific to sequential (integer-keyed, 1-based) tables.
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.first(array, n)
-- lodash: _.first / _.take   ramda: R.head / R.take
-- JS equivalent: arr[0]  or  arr.slice(0, n)
--
-- Without n: returns the first element (JS arr[0] — but Lua is 1-indexed).
-- With n:    returns the first n elements as a new array.
-- -----------------------------------------------------------------------------
function funk.first(array, n)
    if n == nil then
        return array[1]
    end
    local result = {}
    local limit = math.min(n, table.getn(array))
    for i = 1, limit do
        result[i] = array[i]
    end
    return result
end
funk.head = funk.first
funk.take = funk.first

-- -----------------------------------------------------------------------------
-- funk.last(array, n)
-- lodash: _.last / _.takeRight
-- JS equivalent: arr[arr.length - 1]  or  arr.slice(-n)
-- -----------------------------------------------------------------------------
function funk.last(array, n)
    if n == nil then
        return array[table.getn(array)]
    end
    local result = {}
    local start  = math.max(1, table.getn(array) - n + 1)
    for i = start, table.getn(array) do
        result[table.getn(result) + 1] = array[i]
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.rest(array, index)
-- lodash: _.tail / _.drop   ramda: R.tail / R.drop
-- JS equivalent: arr.slice(1)  or  arr.slice(index - 1)
--
-- Default index = 2 (skip the first element), matching underscore.lua.
-- index is 1-based; rest({1,2,3,4}, 3) returns {3, 4} (starts at position 3).
-- -----------------------------------------------------------------------------
function funk.rest(array, index)
    index = index or 2
    local result = {}
    for i = index, table.getn(array) do
        result[table.getn(result) + 1] = array[i]
    end
    return result
end
funk.tail = funk.rest
funk.drop = funk.rest

-- -----------------------------------------------------------------------------
-- funk.initial(array, n)
-- lodash: _.initial / _.dropRight
-- JS equivalent: arr.slice(0, -1)  or  arr.slice(0, -n)
--
-- Returns all elements except the last n (default 1).
-- -----------------------------------------------------------------------------
function funk.initial(array, n)
    n = n or 1
    local result = {}
    for i = 1, table.getn(array) - n do
        result[i] = array[i]
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.slice(array, startIndex, length)
-- lodash: _.slice (but with start+length rather than start+end)
-- JS: arr.slice(start, end) uses start+end; here we use start+LENGTH.
--
-- startIndex is 1-based.  Returns `length` elements beginning at startIndex.
-- -----------------------------------------------------------------------------
function funk.slice(array, startIndex, length)
    local result    = {}
    startIndex      = math.max(startIndex, 1)
    local endIndex  = math.min(startIndex + length - 1, table.getn(array))
    for i = startIndex, endIndex do
        result[table.getn(result) + 1] = array[i]
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.chunk(array, size)
-- lodash: _.chunk
-- JS equivalent: custom chunking
--
-- Splits array into groups of `size`.  The last group may be smaller.
-- -----------------------------------------------------------------------------
function funk.chunk(array, size)
    local result = {}
    local i = 1
    while i <= table.getn(array) do
        local chunk = {}
        for j = i, math.min(i + size - 1, table.getn(array)) do
            chunk[table.getn(chunk) + 1] = array[j]
        end
        result[table.getn(result) + 1] = chunk
        i = i + size
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.flatten(array)
-- lodash: _.flattenDeep   ramda: R.flatten
-- JS equivalent: arr.flat(Infinity)
--
-- Recursively flattens all nested arrays into a single flat array.
-- For one-level-only flattening, see funk.flattenShallow.
-- -----------------------------------------------------------------------------
function funk.flatten(array)
    local result = {}
    for v in _iter(array) do
        if type(v) == "table" then
            local flat = funk.flatten(v)
            for _, fv in ipairs(flat) do
                result[table.getn(result) + 1] = fv
            end
        else
            result[table.getn(result) + 1] = v
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.flattenShallow(array)
-- lodash: _.flatten (one level)
-- JS equivalent: arr.flat()  or  arr.flat(1)
-- -----------------------------------------------------------------------------
function funk.flattenShallow(array)
    local result = {}
    for v in _iter(array) do
        if type(v) == "table" then
            for _, fv in ipairs(v) do
                result[table.getn(result) + 1] = fv
            end
        else
            result[table.getn(result) + 1] = v
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.compact(array)
-- lodash: _.compact   ramda: R.filter(Boolean)
-- JS equivalent: arr.filter(Boolean)
--
-- Removes all falsy values.  In Lua only `false` and `nil` are falsy.
-- WARNING: Unlike JS, 0 and "" are NOT removed — they are truthy in Lua!
-- -----------------------------------------------------------------------------
function funk.compact(array)
    return funk.filter(array, function(v) return v ~= nil and v ~= false end)
end

-- -----------------------------------------------------------------------------
-- funk.uniq(array, iteratee)
-- lodash: _.uniq / _.uniqBy   ramda: R.uniq / R.uniqBy
-- JS equivalent: [...new Set(arr)]  or  _.uniqBy(arr, fn)
--
-- Returns a new array with duplicate values removed (keeps first occurrence).
-- Optional iteratee transforms the value used for comparison.
-- -----------------------------------------------------------------------------
function funk.uniq(array, iteratee)
    local fn   = iteratee or _identity
    local seen = {}
    local result = {}
    for v in _iter(array) do
        local key = fn(v)
        if not seen[key] then
            seen[key] = true
            result[table.getn(result) + 1] = v
        end
    end
    return result
end
funk.unique  = funk.uniq
funk.uniqBy  = funk.uniq

-- -----------------------------------------------------------------------------
-- funk.without(array, ...)
-- lodash: _.without
-- JS equivalent: arr.filter(v => !valuesToRemove.includes(v))
--
-- Returns a new array excluding all provided values.
-- -----------------------------------------------------------------------------
function funk.without(array, ...)
    local excluded = {}
    for _, v in ipairs(arg) do excluded[v] = true end
    return funk.filter(array, function(v) return not excluded[v] end)
end

-- -----------------------------------------------------------------------------
-- funk.union(...)
-- lodash: _.union
-- JS equivalent: [...new Set([...arr1, ...arr2, ...])]
--
-- Returns the unique union of all provided arrays.
-- -----------------------------------------------------------------------------
function funk.union(...)
    local all = {}
    for _, arr in ipairs(arg) do
        for _, v in ipairs(arr) do
            all[table.getn(all) + 1] = v
        end
    end
    return funk.uniq(all)
end

-- -----------------------------------------------------------------------------
-- funk.intersection(...)
-- lodash: _.intersection
-- JS equivalent: arr1.filter(v => arr2.includes(v) && arr3.includes(v) ...)
--
-- Returns elements present in ALL provided arrays.
-- -----------------------------------------------------------------------------
function funk.intersection(...)
    local arrays = arg
    if table.getn(arrays) == 0 then return {} end
    local base = arrays[1]
    local result = {}
    for _, v in ipairs(base) do
        local inAll = true
        for i = 2, table.getn(arrays) do
            if not funk.includes(arrays[i], v) then
                inAll = false
                break
            end
        end
        if inAll then result[table.getn(result) + 1] = v end
    end
    return funk.uniq(result)
end

-- -----------------------------------------------------------------------------
-- funk.difference(array, ...)
-- lodash: _.difference
-- JS equivalent: arr.filter(v => !others.includes(v))
--
-- Returns elements from `array` NOT present in any of the other arrays.
-- -----------------------------------------------------------------------------
function funk.difference(array, ...)
    local others = {}
    for _, arr in ipairs(arg) do
        for _, v in ipairs(arr) do others[v] = true end
    end
    return funk.filter(array, function(v) return not others[v] end)
end

-- -----------------------------------------------------------------------------
-- funk.zip(...)
-- lodash: _.zip   ramda: R.zip / R.zipWith
-- JS equivalent: arrays[0].map((v, i) => arrays.map(a => a[i]))
--
-- Zips multiple arrays together into an array of arrays.
-- funk.zip({1,2,3}, {"a","b","c"}) → {{1,"a"}, {2,"b"}, {3,"c"}}
-- -----------------------------------------------------------------------------
function funk.zip(...)
    local arrays = arg
    local result = {}
    local len = 0
    for _, a in ipairs(arrays) do
        if table.getn(a) > len then len = table.getn(a) end
    end
    for i = 1, len do
        local row = {}
        for _, a in ipairs(arrays) do
            row[table.getn(row) + 1] = a[i]
        end
        result[i] = row
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.zipObject(keys, values)
-- lodash: _.zipObject
-- JS equivalent: Object.fromEntries(keys.map((k, i) => [k, values[i]]))
--
-- Creates a table from parallel arrays of keys and values.
-- -----------------------------------------------------------------------------
function funk.zipObject(keys, values)
    local result = {}
    for i, k in ipairs(keys) do
        result[k] = values[i]
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.indexOf(array, value, fromIndex)
-- lodash: _.indexOf
-- JS equivalent: arr.indexOf(value, fromIndex)
--
-- Returns the 1-based index of the first occurrence, or -1 if not found.
-- JS uses 0-based indexing; Lua uses 1-based — this returns Lua indices.
-- -----------------------------------------------------------------------------
function funk.indexOf(array, value, fromIndex)
    fromIndex = fromIndex or 1
    for i = fromIndex, table.getn(array) do
        if array[i] == value then return i end
    end
    return -1
end

-- -----------------------------------------------------------------------------
-- funk.lastIndexOf(array, value)
-- lodash: _.lastIndexOf
-- JS equivalent: arr.lastIndexOf(value)
-- -----------------------------------------------------------------------------
function funk.lastIndexOf(array, value)
    for i = table.getn(array), 1, -1 do
        if array[i] == value then return i end
    end
    return -1
end

-- -----------------------------------------------------------------------------
-- funk.range(start, stop, step)
-- lodash: _.range   ramda: R.range
-- JS equivalent: Array.from({length: n}, (_, i) => start + i * step)
--
-- Creates an array of numbers from start up to (but not including) stop.
-- With one argument: range(n) → {1, 2, ..., n}   (Lua 1-based convention)
-- With two arguments: range(start, stop) → {start, ..., stop-1}
-- With three arguments: range(start, stop, step)
-- Note: ramda's R.range excludes stop (like Python). This follows that.
-- -----------------------------------------------------------------------------
function funk.range(start, stop, step)
    if stop == nil then
        -- One-argument form: range(n) → 1..n  (matches Lua 1-based indexing)
        stop  = start
        start = 1
        step  = 1
    else
        step = step or 1
    end
    local result = {}
    if step > 0 then
        local i = start
        while i < stop do
            result[table.getn(result) + 1] = i
            i = i + step
        end
    elseif step < 0 then
        local i = start
        while i > stop do
            result[table.getn(result) + 1] = i
            i = i + step
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.reverse(array)
-- lodash: _.reverse (but non-mutating)   ramda: R.reverse
-- JS equivalent: [...arr].reverse()
--
-- Returns a new reversed array.  Unlike JS's Array.prototype.reverse,
-- this does NOT mutate the original.
-- -----------------------------------------------------------------------------
function funk.reverse(array)
    local result = {}
    for i = table.getn(array), 1, -1 do
        result[table.getn(result) + 1] = array[i]
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.push(array, value) / funk.pop(array)
-- JS equivalent: arr.push(v) / arr.pop()
--
-- push: appends to end, returns the array.
-- pop:  removes and returns the last element.
-- -----------------------------------------------------------------------------
function funk.push(array, value)
    table.insert(array, value)
    return array
end

function funk.pop(array)
    return table.remove(array)
end

-- -----------------------------------------------------------------------------
-- funk.unshift(array, value) / funk.shift(array)
-- JS equivalent: arr.unshift(v) / arr.shift()
--
-- unshift: prepends to front, returns the array.
-- shift:   removes and returns the first element.
-- WARNING: These mutate the array (like JS Array methods).
-- -----------------------------------------------------------------------------
function funk.unshift(array, value)
    table.insert(array, 1, value)
    return array
end

function funk.shift(array)
    return table.remove(array, 1)
end

-- -----------------------------------------------------------------------------
-- funk.splice(array, index, deleteCount, ...)
-- JS equivalent: arr.splice(index, deleteCount, ...insertItems)
--
-- Removes `deleteCount` items at `index` (1-based) and inserts items.
-- Returns the array of removed elements.
-- WARNING: Mutates the array (matches JS behavior).
-- -----------------------------------------------------------------------------
function funk.splice(array, index, deleteCount, ...)
    local removed = {}
    for _ = 1, deleteCount or 0 do
        local v = table.remove(array, index)
        if v == nil then break end
        removed[table.getn(removed) + 1] = v
    end
    local insertItems = arg
    for i = table.getn(insertItems), 1, -1 do
        table.insert(array, index, insertItems[i])
    end
    return removed
end

-- -----------------------------------------------------------------------------
-- funk.join(array, separator)
-- lodash: _.join   JS: arr.join(sep)
-- Concatenates all elements with `separator` (default ",").
-- Elements are converted to strings via tostring().
-- -----------------------------------------------------------------------------
function funk.join(array, separator)
    separator = separator or ","
    local strs = {}
    for i, v in ipairs(array) do
        strs[i] = tostring(v)
    end
    return table.concat(strs, separator)
end

-- -----------------------------------------------------------------------------
-- funk.concat(...)
-- lodash: _.concat   JS: arr.concat(other1, other2, ...)
--
-- Merges multiple arrays into a new flat array (one level only).
-- -----------------------------------------------------------------------------
function funk.concat(...)
    local result = {}
    for _, arr in ipairs(arg) do
        if type(arr) == "table" then
            for _, v in ipairs(arr) do result[table.getn(result) + 1] = v end
        else
            result[table.getn(result) + 1] = arr
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.toArray(listOrIter)
-- lodash: _.toArray
-- Materialises an iterator or returns a copy of an array.
-- -----------------------------------------------------------------------------
function funk.toArray(listOrIter)
    if type(listOrIter) == "table" then
        local copy = {}
        for _, v in ipairs(listOrIter) do copy[table.getn(copy) + 1] = v end
        return copy
    end
    return _toarray(listOrIter)
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 3 — OBJECT / TABLE FUNCTIONS
-- Operate on key-value tables (like JS plain objects / Maps).
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.keys(obj) / funk.values(obj)
-- lodash: _.keys / _.values   ramda: R.keys / R.values
-- JS equivalent: Object.keys(obj) / Object.values(obj)
--
-- Note: In Lua `pairs` iterates ALL table keys (including non-integer ones).
-- Order is NOT guaranteed (same caveat applies in JS for non-integer keys).
-- -----------------------------------------------------------------------------
function funk.keys(obj)
    local result = {}
    for k in pairs(obj) do result[table.getn(result) + 1] = k end
    return result
end

function funk.values(obj)
    local result = {}
    for _, v in pairs(obj) do result[table.getn(result) + 1] = v end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.entries(obj)
-- lodash: _.toPairs   ramda: R.toPairs
-- JS equivalent: Object.entries(obj)
--
-- Returns an array of {key, value} pairs.
-- JS returns [key, value] sub-arrays; Lua uses {key, value} tables.
-- -----------------------------------------------------------------------------
function funk.entries(obj)
    local result = {}
    for k, v in pairs(obj) do
        result[table.getn(result) + 1] = {k, v}
    end
    return result
end
funk.toPairs = funk.entries

-- -----------------------------------------------------------------------------
-- funk.fromEntries(pairs)
-- lodash: _.fromPairs   ramda: R.fromPairs
-- JS equivalent: Object.fromEntries(pairs)
--
-- Creates a table from an array of {key, value} pairs.
-- -----------------------------------------------------------------------------
function funk.fromEntries(pairsArr)
    local result = {}
    for _, pair in ipairs(pairsArr) do
        result[pair[1]] = pair[2]
    end
    return result
end
funk.fromPairs = funk.fromEntries

-- -----------------------------------------------------------------------------
-- funk.assign(destination, ...)   /   funk.extend(destination, source)
-- lodash: _.assign   ramda: R.mergeRight
-- JS equivalent: Object.assign(dest, ...sources)
--
-- Copies all key-value pairs from each source into destination (mutates dest).
-- Later sources overwrite earlier ones for duplicate keys.
-- -----------------------------------------------------------------------------
function funk.assign(destination, ...)
    for _, source in ipairs(arg) do
        for k, v in pairs(source) do
            destination[k] = v
        end
    end
    return destination
end
funk.extend = function(dest, src) return funk.assign(dest, src) end

-- -----------------------------------------------------------------------------
-- funk.merge(destination, ...)
-- lodash: _.merge   ramda: R.mergeDeepRight
-- JS equivalent: deep version of Object.assign
--
-- Recursively merges source tables into destination.
-- Array values are merged by index (not concatenated).
-- -----------------------------------------------------------------------------
function funk.merge(destination, ...)
    for _, source in ipairs(arg) do
        for k, v in pairs(source) do
            if type(v) == "table" and type(destination[k]) == "table" then
                funk.merge(destination[k], v)
            else
                destination[k] = v
            end
        end
    end
    return destination
end

-- -----------------------------------------------------------------------------
-- funk.defaults(obj, ...)
-- lodash: _.defaults
-- JS equivalent: Object.assign({}, ...sources, obj)  (sources don't overwrite)
--
-- Fills in undefined (nil) properties using values from the source objects.
-- Only sets a key if the destination does not already have a value for it.
-- -----------------------------------------------------------------------------
function funk.defaults(obj, ...)
    for _, source in ipairs(arg) do
        for k, v in pairs(source) do
            if obj[k] == nil then
                obj[k] = v
            end
        end
    end
    return obj
end

-- -----------------------------------------------------------------------------
-- funk.clone(obj)
-- lodash: _.clone   ramda: R.clone (shallow)
-- JS equivalent: { ...obj }  or  Object.assign({}, obj)
--
-- Shallow clone: nested tables are shared, not copied.
-- For deep cloning use funk.cloneDeep.
-- -----------------------------------------------------------------------------
function funk.clone(obj)
    local result = {}
    for k, v in pairs(obj) do result[k] = v end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.cloneDeep(obj)
-- lodash: _.cloneDeep
-- JS equivalent: structuredClone(obj)  or  JSON.parse(JSON.stringify(obj))
--
-- Recursively copies all nested tables.
-- Functions and userdata are copied by reference (not cloned).
-- -----------------------------------------------------------------------------
function funk.cloneDeep(obj)
    if type(obj) ~= "table" then return obj end
    local result = {}
    for k, v in pairs(obj) do
        result[k] = funk.cloneDeep(v)
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.pick(obj, keys)
-- lodash: _.pick   ramda: R.pick
-- JS equivalent: Object.fromEntries(keys.map(k => [k, obj[k]]))
--
-- Returns a new table with ONLY the specified keys.
-- keys is an array of key names.
-- -----------------------------------------------------------------------------
function funk.pick(obj, keys)
    local result = {}
    for _, k in ipairs(keys) do
        if obj[k] ~= nil then result[k] = obj[k] end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.omit(obj, keys)
-- lodash: _.omit   ramda: R.omit
-- JS equivalent: Object.fromEntries(Object.entries(obj).filter(([k]) => !keys.includes(k)))
--
-- Returns a new table with the specified keys removed.
-- -----------------------------------------------------------------------------
function funk.omit(obj, keys)
    local excluded = {}
    for _, k in ipairs(keys) do excluded[k] = true end
    local result = {}
    for k, v in pairs(obj) do
        if not excluded[k] then result[k] = v end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.has(obj, key)
-- lodash: _.has   ramda: R.has
-- JS equivalent: Object.prototype.hasOwnProperty.call(obj, key)  or  key in obj
--
-- Returns true if the table has a non-nil value for key.
-- Unlike JS, Lua has no prototype chain to check.
-- -----------------------------------------------------------------------------
function funk.has(obj, key)
    return obj[key] ~= nil
end

-- -----------------------------------------------------------------------------
-- funk.invert(obj)
-- lodash: _.invert   ramda: R.invertObj
-- JS equivalent: Object.fromEntries(Object.entries(obj).map(([k,v]) => [v,k]))
--
-- Returns a new table with keys and values swapped.
-- If multiple keys map to the same value, the last one wins.
-- -----------------------------------------------------------------------------
function funk.invert(obj)
    local result = {}
    for k, v in pairs(obj) do result[tostring(v)] = k end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.mapValues(obj, iteratee)
-- lodash: _.mapValues   ramda: R.map (on objects)
-- JS equivalent: Object.fromEntries(Object.entries(obj).map(([k,v]) => [k, fn(v,k)]))
--
-- Like map but operates on table values, preserving keys.
-- -----------------------------------------------------------------------------
function funk.mapValues(obj, iteratee)
    local result = {}
    for k, v in pairs(obj) do
        result[k] = iteratee(v, k)
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.mapKeys(obj, iteratee)
-- lodash: _.mapKeys
-- JS equivalent: Object.fromEntries(Object.entries(obj).map(([k,v]) => [fn(k,v), v]))
-- -----------------------------------------------------------------------------
function funk.mapKeys(obj, iteratee)
    local result = {}
    for k, v in pairs(obj) do
        result[iteratee(k, v)] = v
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.filterObject(obj, predicate)
-- lodash: _.pickBy
-- JS equivalent: Object.fromEntries(Object.entries(obj).filter(([k,v]) => fn(v,k)))
-- -----------------------------------------------------------------------------
function funk.filterObject(obj, predicate)
    local result = {}
    for k, v in pairs(obj) do
        if predicate(v, k) then result[k] = v end
    end
    return result
end
funk.pickBy = funk.filterObject

-- -----------------------------------------------------------------------------
-- funk.isEmpty(obj)
-- lodash: _.isEmpty   ramda: R.isEmpty
-- JS equivalent: Object.keys(obj).length === 0  or  arr.length === 0
--
-- Works on both arrays and tables.
-- Returns true for nil as well (no value is an empty value).
-- -----------------------------------------------------------------------------
function funk.isEmpty(obj)
    if obj == nil then return true end
    if type(obj) == "table" then return next(obj) == nil end
    if type(obj) == "string" then return obj == "" end
    return false
end

-- -----------------------------------------------------------------------------
-- funk.isEqual(a, b, ignoreMeta)
-- lodash: _.isEqual   ramda: R.equals
-- JS equivalent: JSON.stringify(a) === JSON.stringify(b)  (deep equal)
--
-- Deep equality for tables.  For non-tables uses ==.
-- ignoreMeta: when true, ignores __eq metamethods (treats tables structurally).
-- Lua has no built-in deep equality operator; == on tables checks reference.
-- -----------------------------------------------------------------------------
function funk.isEqual(a, b, ignoreMeta)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return false end
    if ta ~= "table" then return a == b end
    local mt = getmetatable(a)
    if not ignoreMeta and mt and mt.__eq then return a == b end
    for k, v in pairs(a) do
        if not funk.isEqual(v, b[k], ignoreMeta) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

-- -----------------------------------------------------------------------------
-- funk.size(obj)
-- lodash: _.size
-- JS equivalent: obj.length  or  Object.keys(obj).length
--
-- Returns the number of elements/keys.
-- table.getn() in Lua only works reliably for sequential integer-keyed tables.
-- This function handles both arrays and hash tables.
-- -----------------------------------------------------------------------------
function funk.size(obj)
    if type(obj) == "string" then return string.len(obj) end
    local count = 0
    for _ in pairs(obj) do count = count + 1 end
    return count
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 4 — FUNCTION UTILITIES
-- Higher-order functions that produce or transform other functions.
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.identity(value)
-- lodash: _.identity   ramda: R.identity
-- JS equivalent: x => x
-- -----------------------------------------------------------------------------
function funk.identity(value)
    return value
end

-- -----------------------------------------------------------------------------
-- funk.constant(value)
-- lodash: _.constant   ramda: R.always
-- JS equivalent: () => value   (closure over value)
--
-- Returns a function that always returns the given value.
-- Useful as a default iteratee.
-- -----------------------------------------------------------------------------
function funk.constant(value)
    return function() return value end
end
funk.always = funk.constant

-- -----------------------------------------------------------------------------
-- funk.noop()
-- lodash: _.noop
-- JS equivalent: () => {}
-- -----------------------------------------------------------------------------
function funk.noop()
end

-- -----------------------------------------------------------------------------
-- funk.compose(f, g, ...)
-- lodash: _.flowRight   ramda: R.compose
-- JS equivalent: x => f(g(h(x)))
--
-- Creates a function that applies functions right-to-left.
-- compose(f, g)(x) === f(g(x))
-- Note: ramda's compose is right-to-left; lodash's _.flow is left-to-right.
-- -----------------------------------------------------------------------------
function funk.compose(...)
    local fns = arg
    return function(...)
        local args = arg
        local result
        for i = table.getn(fns), 1, -1 do
            if i == table.getn(fns) then
                result = fns[i](unpack(args))
            else
                result = fns[i](result)
            end
        end
        return result
    end
end
funk.flowRight = funk.compose

-- -----------------------------------------------------------------------------
-- funk.pipe(f, g, ...)
-- lodash: _.flow   ramda: R.pipe
-- JS equivalent: x => h(g(f(x)))
--
-- Creates a function that applies functions left-to-right (opposite of compose).
-- pipe(f, g)(x) === g(f(x))
-- -----------------------------------------------------------------------------
function funk.pipe(...)
    local fns = arg
    return function(...)
        local args = arg
        local result
        for i = 1, table.getn(fns) do
            if i == 1 then
                result = fns[i](unpack(args))
            else
                result = fns[i](result)
            end
        end
        return result
    end
end
funk.flow = funk.pipe

-- -----------------------------------------------------------------------------
-- funk.curry(fn, ...)
-- ramda: R.curry   lodash: _.curry (partial/fixed-arity)
-- JS equivalent: (arg) => fn(fixedArg, arg)  (partial application)
--
-- Returns a new function with the first argument pre-filled.
-- This is closest to lodash's _.partial or ramda's R.partial in behavior.
-- True variadic currying is not practical in Lua 5.0 without reflection.
-- -----------------------------------------------------------------------------
function funk.curry(fn, ...)
    local bound = arg
    return function(...)
        local args = {}
        for _, v in ipairs(bound) do args[table.getn(args) + 1] = v end
        for _, v in ipairs(arg)   do args[table.getn(args) + 1] = v end
        return fn(unpack(args))
    end
end
funk.partial = funk.curry

-- -----------------------------------------------------------------------------
-- funk.flip(fn)
-- ramda: R.flip   lodash: no direct equivalent
-- JS equivalent: (a, b) => fn(b, a)
--
-- Returns a function with its first two arguments flipped.
-- Useful for adapting reduce callbacks for pipe/compose.
-- -----------------------------------------------------------------------------
function funk.flip(fn)
    return function(a, b, ...)
        return fn(b, a, ...)
    end
end

-- -----------------------------------------------------------------------------
-- funk.negate(predicate)
-- lodash: _.negate   ramda: R.complement
-- JS equivalent: fn => (...args) => !fn(...args)
-- -----------------------------------------------------------------------------
function funk.negate(predicate)
    return function(...)
        return not predicate(...)
    end
end
funk.complement = funk.negate

-- -----------------------------------------------------------------------------
-- funk.once(fn)
-- lodash: _.once   ramda: R.once
-- JS equivalent: (fn => { let called = false; return (...args) => { if (!called) { called = true; return fn(...args); } } })(fn)
--
-- Returns a function that calls `fn` only on the first invocation.
-- Subsequent calls return the result of the first call (cached).
-- -----------------------------------------------------------------------------
function funk.once(fn)
    local called, result = false, nil
    return function(...)
        if not called then
            called = true
            result = fn(...)
        end
        return result
    end
end

-- -----------------------------------------------------------------------------
-- funk.memoize(fn, resolver)
-- lodash: _.memoize
-- JS equivalent: using a Map as cache: const cache = new Map(); ...
--
-- Returns a memoized version of fn.
-- Optional resolver computes the cache key from the arguments.
-- Default resolver uses the first argument as the key.
-- WARNING: Cache is never cleared — avoid with functions producing large values
--          or with many distinct arguments (memory leak risk in WoW).
-- -----------------------------------------------------------------------------
function funk.memoize(fn, resolver)
    local cache = {}
    return function(...)
        local key
        if resolver then
            key = resolver(...)
        else
            key = (...)  -- first argument only by default
        end
        if cache[key] == nil then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

-- -----------------------------------------------------------------------------
-- funk.wrap(fn, wrapper)
-- lodash: _.wrap
-- JS equivalent: (...args) => wrapper(fn, ...args)
--
-- Wraps fn inside wrapper.  wrapper receives fn as its first argument.
-- Useful for adding before/after hooks.
-- -----------------------------------------------------------------------------
function funk.wrap(fn, wrapper)
    return function(...)
        return wrapper(fn, ...)
    end
end

-- -----------------------------------------------------------------------------
-- funk.after(n, fn)
-- lodash: _.after
-- JS equivalent: count > n guard
--
-- Returns a function that only calls `fn` after it has been called `n` times.
-- Useful for "call me only after all async results are in".
-- -----------------------------------------------------------------------------
function funk.after(n, fn)
    local count = 0
    return function(...)
        count = count + 1
        if count >= n then
            return fn(...)
        end
    end
end

-- -----------------------------------------------------------------------------
-- funk.before(n, fn)
-- lodash: _.before
--
-- Returns a function that calls `fn` only for the first n invocations.
-- -----------------------------------------------------------------------------
function funk.before(n, fn)
    local count, result = 0, nil
    return function(...)
        count = count + 1
        if count < n then
            result = fn(...)
        end
        return result
    end
end

-- -----------------------------------------------------------------------------
-- funk.times(n, iteratee)
-- lodash: _.times   ramda: R.times
-- JS equivalent: Array.from({length: n}, (_, i) => fn(i + 1))
--
-- Calls iteratee n times with the current 1-based iteration index.
-- Returns an array of results.
-- -----------------------------------------------------------------------------
function funk.times(n, iteratee)
    local result = {}
    for i = 1, n do
        result[i] = iteratee(i)
    end
    return result
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 5 — STRING UTILITIES
-- Basic string helpers.  Lua's string library is more limited than JS.
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.trim(str)
-- lodash: _.trim   JS: str.trim()
-- Lua has no built-in trim; uses pattern matching.
-- -----------------------------------------------------------------------------
function funk.trim(str)
    local _, _, result = string.find(str, "^%s*(.-)%s*$")
    return result
end

-- -----------------------------------------------------------------------------
-- funk.trimStart(str) / funk.trimEnd(str)
-- lodash: _.trimStart / _.trimEnd   JS: str.trimStart() / str.trimEnd()
-- -----------------------------------------------------------------------------
function funk.trimStart(str)
    local _, _, result = string.find(str, "^%s*(.*)")
    return result
end

function funk.trimEnd(str)
    local _, _, result = string.find(str, "(.-)%s*$")
    return result
end

-- -----------------------------------------------------------------------------
-- funk.split(str, sep, max)
-- lodash: _.split   JS: str.split(sep, limit)
--
-- Splits string by separator (plain string, not a pattern).
-- Returns an array of strings.
-- -----------------------------------------------------------------------------
function funk.split(str, sep, max)
    local result, pattern = {}, "([^" .. sep .. "]*)" .. sep .. "?"
    local count = 0
    str:gsub(pattern, function(c)
        if max and count >= max then return end
        result[table.getn(result) + 1] = c
        count = count + 1
    end)
    -- remove trailing empty string artifact
    if table.getn(result) > 0 and result[table.getn(result)] == "" then
        result[table.getn(result)] = nil
    end
    return result
end

-- -----------------------------------------------------------------------------
-- funk.startsWith(str, prefix)
-- lodash: _.startsWith   JS: str.startsWith(prefix)
-- -----------------------------------------------------------------------------
function funk.startsWith(str, prefix)
    return str:sub(1, string.len(prefix)) == prefix
end

-- -----------------------------------------------------------------------------
-- funk.endsWith(str, suffix)
-- lodash: _.endsWith   JS: str.endsWith(suffix)
-- -----------------------------------------------------------------------------
function funk.endsWith(str, suffix)
    return suffix == "" or str:sub(-string.len(suffix)) == suffix
end

-- -----------------------------------------------------------------------------
-- funk.capitalize(str)
-- lodash: _.capitalize   JS: str[0].toUpperCase() + str.slice(1).toLowerCase()
-- -----------------------------------------------------------------------------
function funk.capitalize(str)
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- -----------------------------------------------------------------------------
-- funk.upperCase(str) / funk.lowerCase(str)
-- lodash: _.toUpper / _.toLower   JS: str.toUpperCase() / str.toLowerCase()
-- -----------------------------------------------------------------------------
function funk.upperCase(str) return str:upper() end
function funk.lowerCase(str) return str:lower() end

-- -----------------------------------------------------------------------------
-- funk.repeat(str, n)
-- lodash: _.repeat   JS: str.repeat(n)
-- `repeat` is a reserved word in Lua; use funk["repeat"](str, n).
-- -----------------------------------------------------------------------------
funk["repeat"] = function(str, n)
    local result = {}
    for i = 1, n do result[i] = str end
    return table.concat(result)
end

-- -----------------------------------------------------------------------------
-- funk.pad(str, length, chars)
-- lodash: _.pad   JS: str.padStart + padEnd
-- Centers the string within `length`, padded with `chars` (default " ").
-- -----------------------------------------------------------------------------
function funk.pad(str, length, chars)
    chars = chars or " "
    local diff = length - string.len(str)
    if diff <= 0 then return str end
    local left  = math.floor(diff / 2)
    local right = diff - left
    return funk["repeat"](chars, left) .. str .. funk["repeat"](chars, right)
end

function funk.padStart(str, length, chars)
    chars = chars or " "
    local diff = length - string.len(str)
    if diff <= 0 then return str end
    return funk["repeat"](chars, diff) .. str
end

function funk.padEnd(str, length, chars)
    chars = chars or " "
    local diff = length - string.len(str)
    if diff <= 0 then return str end
    return str .. funk["repeat"](chars, diff)
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 6 — NUMBER / MATH UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.clamp(value, min, max)
-- lodash: _.clamp   ramda: R.clamp
-- JS equivalent: Math.min(Math.max(value, min), max)
-- -----------------------------------------------------------------------------
function funk.clamp(value, minVal, maxVal)
    return math.min(math.max(value, minVal), maxVal)
end

-- -----------------------------------------------------------------------------
-- funk.inRange(value, start, stop)
-- lodash: _.inRange
-- JS equivalent: value >= start && value < stop
-- With two args: inRange(value, stop) → 0 <= value < stop
-- -----------------------------------------------------------------------------
function funk.inRange(value, start, stop)
    if stop == nil then
        stop  = start
        start = 0
    end
    return value >= start and value < stop
end

-- -----------------------------------------------------------------------------
-- funk.random(lower, upper, floating)
-- lodash: _.random
-- JS equivalent: Math.random() * (upper - lower) + lower
-- With no args: returns 0 or 1 (integer).
-- -----------------------------------------------------------------------------
function funk.random(lower, upper, floating)
    if lower == nil then lower, upper = 0, 1 end
    if upper == nil then upper = lower; lower = 0 end
    if floating then
        return lower + math.random() * (upper - lower)
    end
    return math.random(lower, upper)
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 7 — TYPE CHECKS
-- Simple predicates, like lodash's is* family.
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

function funk.isNil(v)      return v == nil end
function funk.isBoolean(v)  return type(v) == "boolean" end
function funk.isNumber(v)   return type(v) == "number" end
function funk.isString(v)   return type(v) == "string" end
function funk.isTable(v)    return type(v) == "table" end
function funk.isFunction(v) return type(v) == "function" end

-- isArray: heuristic check — all keys are sequential integers starting at 1.
-- Lua does not distinguish arrays from tables at the type level.
function funk.isArray(v)
    if type(v) ~= "table" then return false end
    local count = 0
    for _ in pairs(v) do count = count + 1 end
    return count == table.getn(v)
end

function funk.isObject(v)
    return type(v) == "table" and not funk.isArray(v)
end

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 8 — CHAINING API
-- Allows fluent method-chaining similar to lodash's _(value).chain().
--
-- Usage:
--   local result = funk.chain({3,1,2})
--     :map(function(x) return x * 2 end)
--     :filter(function(x) return x > 2 end)
--     :sort()
--     :value()
--   -- result = {4, 6}
--
-- JS equivalent (lodash):
--   const result = _([3,1,2])
--     .map(x => x * 2)
--     .filter(x => x > 2)
--     .sortBy()
--     .value()
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

local Chain = {}
Chain.__index = Chain

-- funk.chain(value) — wraps a value in a chainable wrapper.
function funk.chain(value)
    return setmetatable({_val = value}, Chain)
end

-- value() — unwrap the result.
function Chain:value()
    return self._val
end

-- Dynamically attach every funk function to Chain so it can be chained.
-- The first argument (list/obj) is replaced with the wrapped value.
local function _attachChainMethod(name, fn)
    Chain[name] = function(self, ...)
        self._val = fn(self._val, ...)
        return self
    end
end

-- We'll populate Chain methods after the funk table is fully defined,
-- but we can attach them now by iterating what's already set.
-- (They will be re-populated at the bottom of the file.)

-- ---------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 9 — MIXIN / EXTENSION
-- ═══════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk.mixin(methods)
-- lodash: _.mixin
-- JS equivalent: Object.assign(_, methods)
--
-- Adds custom functions to the funk namespace and enables them for chaining.
-- -----------------------------------------------------------------------------
function funk.mixin(methods)
    for name, fn in pairs(methods) do
        funk[name] = fn
        _attachChainMethod(name, fn)
    end
end

-- funk.functions() — returns an array of all public function names.
function funk.functions()
    local names = {}
    for k, v in pairs(funk) do
        if type(v) == "function" then
            names[table.getn(names) + 1] = k
        end
    end
    table.sort(names)
    return names
end
funk.methods = funk.functions

-- ---------------------------------------------------------------------------
-- Populate Chain methods for all currently-defined funk functions.
-- ---------------------------------------------------------------------------
for name, fn in pairs(funk) do
    if type(fn) == "function" and name ~= "chain" and name ~= "mixin" then
        _attachChainMethod(name, fn)
    end
end

-- Share via the WoW per-addon namespace table when available.
-- This avoids adding anything to _G and keeps the global environment clean.
-- In WoW: every .toc file receives (addonName, addonTable) as ..., so _ns is
--         the shared addon table.  Other files in the same addon access the
--         library via `local _, ns = ...` then `local F = ns.funk`.
-- Standalone (dofile/require): _ns is nil; use the return value instead.
if _ns ~= nil then
    _ns.funk = funk
end
return funk
