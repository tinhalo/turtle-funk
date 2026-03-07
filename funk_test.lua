-- =============================================================================
-- funk_test.lua — Lightweight in-game test runner for TurtleWoW / WoW
-- =============================================================================
-- Runs unit tests for funk.lua and reports results to the chat frame.
-- Designed to be loaded as a WoW add-on or executed via /run in the console.
--
-- USAGE (in-game):
--   /run dofile("funk_test.lua")   -- if running from disk
--   -- or include in your addon's .toc file and call funk_test.run()
--
-- OUTPUT example:
--   [PASS] map: doubles each element
--   [PASS] filter: keeps even numbers
--   [FAIL] reduce: sum of empty → expected 0, got nil
--   ─────────────────────────────────
--   Results: 42 passed, 1 failed
-- =============================================================================

-- WoW 1.12 / Lua 5.0: the per-addon namespace is a single shared global table.
-- Each file in the addon accesses it via this global instead of _G directly.
-- When loaded via dofile() standalone the table is still created here.
FunkDemo = FunkDemo or {}
local _ns = FunkDemo

-- Resolve dependencies: WoW namespace first, then dofile for CLI/standalone.
local funk       = (_ns and _ns.funk)       or (dofile and dofile("funk.lua"))       or {}
local funk_debug = (_ns and _ns.funk_debug) or (dofile and dofile("funk_debug.lua")) or {}

-- ---------------------------------------------------------------------------
-- Minimal serialiser (stand-alone, no funk_debug dependency required).
-- ---------------------------------------------------------------------------
local function _str(v)
    if type(v) == "table" then
        local parts = {}
        -- Try as array first
        local isArr = (table.getn(v) > 0)
        if isArr then
            for i, val in ipairs(v) do parts[i] = _str(val) end
            return "{" .. table.concat(parts, ", ") .. "}"
        else
            for k, val in pairs(v) do
                parts[table.getn(parts) + 1] = tostring(k) .. "=" .. _str(val)
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
    end
    return tostring(v)
end

-- ---------------------------------------------------------------------------
-- Test framework
-- ---------------------------------------------------------------------------

local funk_test = {}

local _results = { passed = 0, failed = 0, errors = {} }

-- _out: write a line to the WoW chat frame or stdout.
local function _out(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

-- _pass / _fail helpers
local function _pass(desc)
    _results.passed = _results.passed + 1
    _out("|cFF00FF00[PASS]|r " .. desc)
end

local function _fail(desc, expected, got, note)
    _results.failed = _results.failed + 1
    local msg = "|cFFFF4444[FAIL]|r " .. desc
    if expected ~= nil then
        msg = msg .. "  |cFFAAAAAA(expected " .. _str(expected)
            .. ", got " .. _str(got) .. ")|r"
    end
    if note then msg = msg .. "  |cFFFF8C00" .. note .. "|r" end
    _out(msg)
    _results.errors[table.getn(_results.errors) + 1] = desc
end

-- Deep-equality helper for assertions (re-uses funk.isEqual when available).
local function _deepEq(a, b)
    if funk.isEqual then return funk.isEqual(a, b) end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not _deepEq(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

-- -----------------------------------------------------------------------------
-- funk_test.expect(desc, got, expected)
-- The core assertion helper.  Compares `got` to `expected` with deep equality.
-- JS equivalent: expect(got).toEqual(expected)
-- -----------------------------------------------------------------------------
function funk_test.expect(desc, got, expected)
    if _deepEq(got, expected) then
        _pass(desc)
    else
        _fail(desc, expected, got)
    end
end

-- funk_test.expectTrue(desc, value)
function funk_test.expectTrue(desc, value)
    if value then _pass(desc) else _fail(desc, true, value) end
end

-- funk_test.expectFalse(desc, value)
function funk_test.expectFalse(desc, value)
    if not value then _pass(desc) else _fail(desc, false, value) end
end

-- funk_test.expectNil(desc, value)
function funk_test.expectNil(desc, value)
    if value == nil then _pass(desc) else _fail(desc, nil, value) end
end

-- ---------------------------------------------------------------------------
-- Test suites
-- ---------------------------------------------------------------------------

-- Helper: shorthand for funk_test.expect
local E = funk_test.expect
local T = funk_test.expectTrue
local F = funk_test.expectFalse

-- ── each ────────────────────────────────────────────────────────────────────
local function test_each()
    local acc = {}
    funk.each({10, 20, 30}, function(v) acc[table.getn(acc)+1] = v end)
    E("each: collects all values",    acc, {10, 20, 30})
    E("each: returns original list",  funk.each({1}, function() end), {1})
end

-- ── map ─────────────────────────────────────────────────────────────────────
local function test_map()
    E("map: doubles",        funk.map({1, 2, 3}, function(x) return x * 2 end), {2, 4, 6})
    E("map: empty",          funk.map({}, function(x) return x end), {})
    E("map: strings",        funk.map({"a","b"}, string.upper), {"A","B"})
    E("collect alias",       funk.collect({1,2}, function(x) return x+1 end), {2,3})
end

-- ── mapWithIndex ─────────────────────────────────────────────────────────────
local function test_mapWithIndex()
    E("mapWithIndex: index is 1-based",
        funk.mapWithIndex({"a","b","c"}, function(v, i) return i .. v end),
        {"1a", "2b", "3c"})
end

-- ── reduce ──────────────────────────────────────────────────────────────────
local function test_reduce()
    E("reduce: sum",    funk.reduce({1,2,3,4}, 0, function(acc,v) return acc+v end), 10)
    E("reduce: concat", funk.reduce({"a","b","c"}, "", function(acc,v) return acc..v end), "abc")
    E("reduce: empty",  funk.reduce({}, 42, function(acc,v) return acc+v end), 42)
    E("foldl alias",    funk.foldl({1,2,3}, 0, function(a,v) return a+v end), 6)
    E("inject alias",   funk.inject({1,2,3}, 0, function(a,v) return a+v end), 6)
end

-- ── reduceRight ──────────────────────────────────────────────────────────────
local function test_reduceRight()
    E("reduceRight: string concat",
        funk.reduceRight({"a","b","c"}, "", function(acc,v) return acc..v end), "cba")
end

-- ── filter ──────────────────────────────────────────────────────────────────
local function test_filter()
    E("filter: evens",  funk.filter({1,2,3,4,5}, function(x) return math.mod(x,2)==0 end), {2,4})
    E("filter: empty",  funk.filter({}, function() return true end), {})
    E("select alias",   funk.select({1,2,3}, function(x) return x>1 end), {2,3})
end

-- ── reject ──────────────────────────────────────────────────────────────────
local function test_reject()
    E("reject: odds",   funk.reject({1,2,3,4,5}, function(x) return math.mod(x,2)==0 end), {1,3,5})
end

-- ── find ────────────────────────────────────────────────────────────────────
local function test_find()
    E("find: first match",  funk.find({1,2,3,4}, function(x) return x>2 end), 3)
    E("find: no match",     funk.find({1,2,3},   function(x) return x>9 end), nil)
    E("detect alias",       funk.detect({5,6,7}, function(x) return x==6 end), 6)
end

-- ── findIndex ────────────────────────────────────────────────────────────────
local function test_findIndex()
    E("findIndex: found",   funk.findIndex({10,20,30}, function(x) return x==20 end), 2)
    E("findIndex: missing", funk.findIndex({1,2,3},    function(x) return x==99 end), -1)
end

-- ── every / some ─────────────────────────────────────────────────────────────
local function test_every_some()
    T("every: all positive",      funk.every({1,2,3}, function(x) return x>0 end))
    F("every: not all positive",  funk.every({1,-2,3}, function(x) return x>0 end))
    T("every: empty list",        funk.every({}))
    T("some: at least one",       funk.some({1,2,3}, function(x) return x>2 end))
    F("some: none match",         funk.some({1,2,3}, function(x) return x>9 end))
    F("some: empty list",         funk.some({}))
    T("all alias",                funk.all({2,4,6}, function(x) return math.mod(x,2)==0 end))
    T("any alias",                funk.any({1,3,5}, function(x) return x==3 end))
end

-- ── includes ─────────────────────────────────────────────────────────────────
local function test_includes()
    T("includes: found",   funk.includes({1,2,3}, 2))
    F("includes: missing", funk.includes({1,2,3}, 9))
    T("contains alias",    funk.contains({"a","b"}, "a"))
end

-- ── pluck ────────────────────────────────────────────────────────────────────
local function test_pluck()
    local items = {{name="Alice", age=30}, {name="Bob", age=25}}
    E("pluck: names", funk.pluck(items, "name"), {"Alice","Bob"})
    E("pluck: ages",  funk.pluck(items, "age"),  {30, 25})
end

-- ── groupBy ──────────────────────────────────────────────────────────────────
local function test_groupBy()
    local result = funk.groupBy({1,2,3,4,5,6}, function(x)
        return math.mod(x, 2) == 0 and "even" or "odd"
    end)
    E("groupBy: odds",  result["odd"],  {1,3,5})
    E("groupBy: evens", result["even"], {2,4,6})
end

-- ── countBy ──────────────────────────────────────────────────────────────────
local function test_countBy()
    local result = funk.countBy({1,2,3,4,5}, function(x)
        return math.mod(x, 2) == 0 and "even" or "odd"
    end)
    E("countBy: odd count",  result["odd"],  3)
    E("countBy: even count", result["even"], 2)
end

-- ── partition ────────────────────────────────────────────────────────────────
local function test_partition()
    local parts = funk.partition({1,2,3,4,5}, function(x) return math.mod(x,2)==0 end)
    E("partition: evens", parts[1], {2,4})
    E("partition: odds",  parts[2], {1,3,5})
end

-- ── sortBy / sort ─────────────────────────────────────────────────────────────
local function test_sort()
    E("sort: ascending numbers",
        funk.sort({3,1,4,1,5,9}, function(a,b) return a<b end),
        {1,1,3,4,5,9})
    local people = {{name="Bob",age=25},{name="Alice",age=30},{name="Eve",age=22}}
    local sorted = funk.sortBy(people, "age")
    E("sortBy: by age", funk.pluck(sorted,"name"), {"Eve","Bob","Alice"})
end

-- ── min / max ────────────────────────────────────────────────────────────────
local function test_min_max()
    E("min: plain numbers",     funk.min({3,1,4,1,5}), 1)
    E("max: plain numbers",     funk.max({3,1,4,1,5}), 5)
    local items = {{v=10},{v=2},{v=7}}
    E("min: with iteratee",     funk.min(items, function(x) return x.v end), {v=2})
    E("max: with iteratee",     funk.max(items, function(x) return x.v end), {v=10})
end

-- ── sum / mean ───────────────────────────────────────────────────────────────
local function test_sum_mean()
    E("sum: plain",    funk.sum({1,2,3,4,5}), 15)
    E("mean: plain",   funk.mean({2,4,6}), 4)
    E("mean: empty",   funk.mean({}), 0)
end

-- ── first / last / rest / initial ────────────────────────────────────────────
local function test_array_slices()
    E("first: single",   funk.first({10,20,30}),    10)
    E("first: n=2",      funk.first({10,20,30}, 2), {10,20})
    E("last: single",    funk.last({10,20,30}),     30)
    E("last: n=2",       funk.last({10,20,30}, 2),  {20,30})
    E("rest: default",   funk.rest({1,2,3}),         {2,3})
    E("tail alias",      funk.tail({1,2,3}),          {2,3})
    E("initial: default",funk.initial({1,2,3}),      {1,2})
    E("head alias",      funk.head({5,6,7}),           5)
    E("take: n=2",       funk.take({1,2,3,4}, 2),    {1,2})
    E("drop: n=3",       funk.drop({1,2,3,4}, 3),    {3,4})
end

-- ── slice ────────────────────────────────────────────────────────────────────
local function test_slice()
    E("slice: middle",  funk.slice({1,2,3,4,5}, 2, 3), {2,3,4})
    E("slice: clamps",  funk.slice({1,2,3},      2, 9), {2,3})
end

-- ── chunk ────────────────────────────────────────────────────────────────────
local function test_chunk()
    E("chunk: even",  funk.chunk({1,2,3,4},   2), {{1,2},{3,4}})
    E("chunk: uneven",funk.chunk({1,2,3,4,5}, 2), {{1,2},{3,4},{5}})
end

-- ── flatten ──────────────────────────────────────────────────────────────────
local function test_flatten()
    E("flatten: deep",    funk.flatten({1,{2,{3,{4}}},5}), {1,2,3,4,5})
    E("flattenShallow",   funk.flattenShallow({1,{2,3},{4,5}}), {1,2,3,4,5})
    E("flatten: empty",   funk.flatten({}), {})
end

-- ── compact ──────────────────────────────────────────────────────────────────
local function test_compact()
    -- In Lua, nil in a table literal creates a "hole" that terminates the
    -- # length operator at an unpredictable position.  Unlike JavaScript,
    -- you cannot reliably store nil inside an array.  compact therefore
    -- removes explicit `false` values and any nil gaps it can observe.
    E("compact: removes false",       funk.compact({1, false, 2, false, 3}), {1,2,3})
    -- Note: 0 and "" are truthy in Lua (unlike JS where they are falsy)
    E("compact: 0 is truthy in Lua",  funk.compact({0, "", false}), {0,""})
end

-- ── uniq ─────────────────────────────────────────────────────────────────────
local function test_uniq()
    E("uniq: basic",    funk.uniq({1,2,1,3,2}), {1,2,3})
    E("uniq: empty",    funk.uniq({}), {})
    E("uniqBy: by floor",
        funk.uniqBy({1.1, 1.9, 2.3, 3.0}, math.floor),
        {1.1, 2.3, 3.0})
end

-- ── without ──────────────────────────────────────────────────────────────────
local function test_without()
    E("without: removes values", funk.without({1,2,3,2,1}, 1, 2), {3})
end

-- ── union / intersection / difference ───────────────────────────────────────
local function test_set_ops()
    E("union",        funk.union({1,2,3},{2,3,4}), {1,2,3,4})
    E("intersection", funk.intersection({1,2,3},{2,3,4},{3,4,5}), {3})
    E("difference",   funk.difference({1,2,3,4},{2,4}), {1,3})
end

-- ── zip ──────────────────────────────────────────────────────────────────────
local function test_zip()
    E("zip: two arrays",   funk.zip({1,2,3},{"a","b","c"}), {{1,"a"},{2,"b"},{3,"c"}})
    E("zipObject",         funk.zipObject({"x","y"},{10,20}), {x=10,y=20})
end

-- ── indexOf / lastIndexOf ────────────────────────────────────────────────────
local function test_indexOf()
    E("indexOf: found",         funk.indexOf({10,20,30,20}, 20),  2)
    E("indexOf: missing",       funk.indexOf({1,2,3}, 99),        -1)
    E("lastIndexOf: found",     funk.lastIndexOf({10,20,30,20}, 20), 4)
end

-- ── range ────────────────────────────────────────────────────────────────────
local function test_range()
    E("range: one arg (Lua 1-based)",  funk.range(4), {1,2,3})
    -- range(1,4) → [1,2,3]  (excludes stop, like Python/ramda)
    E("range: start+stop",            funk.range(1,4), {1,2,3})
    E("range: step",                  funk.range(0,10,3), {0,3,6,9})
    E("range: descending",            funk.range(5,1,-1), {5,4,3,2})
end

-- ── reverse ──────────────────────────────────────────────────────────────────
local function test_reverse()
    local orig = {1,2,3}
    local rev  = funk.reverse(orig)
    E("reverse: result",       rev,  {3,2,1})
    E("reverse: non-mutating", orig, {1,2,3})
end

-- ── concat ───────────────────────────────────────────────────────────────────
local function test_concat()
    E("concat: arrays",       funk.concat({1,2},{3,4},{5}), {1,2,3,4,5})
    E("concat: scalar+array", funk.concat({1,2}, 3),        {1,2,3})
end

-- ── push / pop / shift / unshift ────────────────────────────────────────────
local function test_array_mutation()
    local a = {1,2,3}
    funk.push(a, 4)
    E("push: appended", a, {1,2,3,4})
    E("pop: returns last", funk.pop(a), 4)
    E("pop: mutated",      a, {1,2,3})
    funk.unshift(a, 0)
    E("unshift: prepended", a, {0,1,2,3})
    E("shift: returns first", funk.shift(a), 0)
    E("shift: mutated",       a, {1,2,3})
end

-- ── splice ───────────────────────────────────────────────────────────────────
local function test_splice()
    local a = {1,2,3,4,5}
    local removed = funk.splice(a, 2, 2, 20, 30)
    E("splice: removed", removed, {2,3})
    E("splice: mutated",  a, {1,20,30,4,5})
end

-- ── join ─────────────────────────────────────────────────────────────────────
local function test_join()
    E("join: comma",  funk.join({1,2,3}),      "1,2,3")
    E("join: dash",   funk.join({"a","b"}, "-"), "a-b")
end

-- ── keys / values / entries ──────────────────────────────────────────────────
local function test_object_funcs()
    local obj = {a=1, b=2}
    -- Key/value order is not guaranteed; test via inclusion
    local ks = funk.keys(obj)
    table.sort(ks)
    E("keys: sorted",  ks, {"a","b"})

    local vs = funk.values(obj)
    table.sort(vs)
    E("values: sorted", vs, {1,2})

    E("has: present",  funk.has(obj,"a"),  true)
    E("has: missing",  funk.has(obj,"z"),  false)
end

-- ── assign / defaults / merge ────────────────────────────────────────────────
local function test_object_merge()
    local dst = {a=1}
    funk.assign(dst, {b=2}, {c=3})
    E("assign: merged",   dst, {a=1,b=2,c=3})

    local d = {a=1, b=2}
    funk.defaults(d, {b=99, c=3})
    E("defaults: skips existing", d, {a=1,b=2,c=3})

    local deep = {x={y=1}}
    funk.merge(deep, {x={z=2}})
    E("merge: deep", deep, {x={y=1,z=2}})
end

-- ── pick / omit ──────────────────────────────────────────────────────────────
local function test_pick_omit()
    local obj = {a=1,b=2,c=3}
    E("pick",  funk.pick(obj, {"a","c"}), {a=1,c=3})
    E("omit",  funk.omit(obj, {"b"}),     {a=1,c=3})
end

-- ── clone / cloneDeep ────────────────────────────────────────────────────────
local function test_clone()
    local orig = {a=1, nested={b=2}}
    local sh   = funk.clone(orig)
    sh.a = 99
    E("clone: shallow copy", orig.a, 1)        -- orig unchanged
    T("clone: shares nested", sh.nested == orig.nested) -- same ref

    local deep = funk.cloneDeep(orig)
    deep.nested.b = 99
    E("cloneDeep: independent nested", orig.nested.b, 2)
end

-- ── invert / mapValues ───────────────────────────────────────────────────────
local function test_invert_mapValues()
    E("invert",     funk.invert({a="x",b="y"}), {x="a",y="b"})
    E("mapValues",  funk.mapValues({a=1,b=2}, function(v) return v*10 end), {a=10,b=20})
end

-- ── isEmpty / isEqual / size ─────────────────────────────────────────────────
local function test_utility()
    T("isEmpty: empty table", funk.isEmpty({}))
    F("isEmpty: non-empty",   funk.isEmpty({1}))
    T("isEmpty: empty string",funk.isEmpty(""))
    T("isEqual: deep",        funk.isEqual({1,{2,3}},{1,{2,3}}))
    F("isEqual: differs",     funk.isEqual({1,2},{1,3}))
    E("size: array",          funk.size({1,2,3}), 3)
    E("size: table",          funk.size({a=1,b=2}), 2)
    E("size: string",         funk.size("hello"), 5)
end

-- ── compose / pipe ──────────────────────────────────────────────────────────
local function test_compose_pipe()
    local addOne  = function(x) return x + 1 end
    local double  = function(x) return x * 2 end
    local square  = function(x) return x * x end

    -- compose: right-to-left
    local f = funk.compose(double, addOne)   -- double(addOne(x))
    E("compose: double(addOne(3))", f(3), 8)

    -- pipe: left-to-right
    local g = funk.pipe(addOne, double)      -- double(addOne(x))
    E("pipe: same as compose reversed", g(3), 8)

    local h = funk.pipe(square, addOne, double) -- double(addOne(square(x)))
    E("pipe: three funcs", h(3), 20)
end

-- ── curry / partial / flip / negate ─────────────────────────────────────────
local function test_func_utils()
    local add = function(a, b) return a + b end
    local add5 = funk.curry(add, 5)
    E("curry: pre-filled arg", add5(3), 8)

    local sub = function(a, b) return a - b end
    E("flip: args swapped", funk.flip(sub)(1, 10), 9)  -- sub(10,1)

    local isEven = function(x) return math.mod(x, 2) == 0 end
    local isOdd  = funk.negate(isEven)
    T("negate: odd", isOdd(3))
    F("negate: even", isOdd(4))
end

-- ── once / memoize / after / before ─────────────────────────────────────────
local function test_func_control()
    local count = 0
    local inc = funk.once(function() count = count + 1; return count end)
    inc(); inc(); inc()
    E("once: called only once", count, 1)

    local calls = 0
    local memo = funk.memoize(function(x) calls = calls + 1; return x * 2 end)
    memo(5); memo(5); memo(6)
    E("memoize: cache hit", calls, 2)
    E("memoize: result",    memo(5), 10)

    local fired = 0
    local fn = funk.after(3, function() fired = fired + 1 end)
    fn(); fn(); fn(); fn()
    E("after: fires from 3rd call onward", fired, 2)

    local bcount = 0
    local bfn = funk.before(3, function() bcount = bcount + 1 end)
    bfn(); bfn(); bfn(); bfn()
    E("before: fires only first 2 times", bcount, 2)
end

-- ── times ────────────────────────────────────────────────────────────────────
local function test_times()
    E("times: squares", funk.times(4, function(i) return i*i end), {1,4,9,16})
end

-- ── String utilities ─────────────────────────────────────────────────────────
local function test_strings()
    E("trim",        funk.trim("  hello  "),   "hello")
    E("trimStart",   funk.trimStart("  hi"),   "hi")
    E("trimEnd",     funk.trimEnd("bye  "),    "bye")
    E("split",       funk.split("a,b,c", ","), {"a","b","c"})
    T("startsWith",  funk.startsWith("hello", "hel"))
    F("startsWith",  funk.startsWith("hello", "world"))
    T("endsWith",    funk.endsWith("hello", "llo"))
    E("capitalize",  funk.capitalize("hELLO"),  "Hello")
    E("upperCase",   funk.upperCase("hello"),   "HELLO")
    E("lowerCase",   funk.lowerCase("HELLO"),   "hello")
    E("repeat",      funk["repeat"]("ab", 3),   "ababab")
    E("padStart",    funk.padStart("5", 3, "0"), "005")
    E("padEnd",      funk.padEnd("5", 3, "0"),   "500")
end

-- ── Number utilities ─────────────────────────────────────────────────────────
local function test_numbers()
    E("clamp: within",  funk.clamp(5, 1, 10), 5)
    E("clamp: below",   funk.clamp(-3, 1, 10), 1)
    E("clamp: above",   funk.clamp(15, 1, 10), 10)
    T("inRange: inside",  funk.inRange(3, 1, 5))
    F("inRange: outside", funk.inRange(5, 1, 5))   -- excludes stop
    T("inRange: 2-arg",   funk.inRange(3, 5))       -- 0 <= 3 < 5
end

-- ── Type checks ──────────────────────────────────────────────────────────────
local function test_types()
    T("isNil",       funk.isNil(nil))
    F("isNil",       funk.isNil(0))
    T("isBoolean",   funk.isBoolean(true))
    T("isNumber",    funk.isNumber(3.14))
    T("isString",    funk.isString("hi"))
    T("isTable",     funk.isTable({}))
    T("isFunction",  funk.isFunction(print))
    T("isArray",     funk.isArray({1,2,3}))
    F("isArray",     funk.isArray({a=1}))
    F("isObject",    funk.isObject({1,2,3}))
    T("isObject",    funk.isObject({a=1}))
end

-- ── Chaining API ─────────────────────────────────────────────────────────────
local function test_chaining()
    local result = funk.chain({3,1,4,1,5,9,2,6})
        :filter(function(x) return x > 2 end)
        :sort(function(a,b) return a < b end)
        :map(function(x) return x * 10 end)
        :value()
    E("chain: filter+sort+map", result, {30,40,50,60,90})
end

-- ── Mixin ─────────────────────────────────────────────────────────────────────
local function test_mixin()
    funk.mixin({
        double = function(arr)
            return funk.map(arr, function(x) return x * 2 end)
        end
    })
    T("mixin: adds function",     type(funk.double) == "function")
    E("mixin: function works",    funk.double({1,2,3}), {2,4,6})
    E("mixin: chainable",
        funk.chain({1,2,3}):double():value(),
        {2,4,6})
end

-- ── Namespace: no global pollution ───────────────────────────────────────────
-- When loaded via dofile() (i.e. _ns is nil), none of the libraries should
-- have written anything to _G.  rawget bypasses __index metamethods so this
-- is a direct check of the actual global table.
local function test_no_global_pollution()
    funk_test.expectNil(
        "funk.lua does not write _G.funk when loaded via dofile",
        rawget(_G, "funk"))
    funk_test.expectNil(
        "funk_debug.lua does not write _G.funk_debug when loaded via dofile",
        rawget(_G, "funk_debug"))
    funk_test.expectNil(
        "funk_test.lua does not write _G.funk_test when loaded via dofile",
        rawget(_G, "funk_test"))
end

-- ── nil safety ──────────────────────────────────────────────────────────────
local N = funk_test.expectNil

local function test_nil_safety()
    -- _iter: nil list should produce empty results for collection functions
    E("map: nil list",       funk.map(nil, function(x) return x end),    {})
    E("filter: nil list",    funk.filter(nil, function() return true end), {})
    E("each: nil list",      (function() funk.each(nil, function() end) return true end)(), true)

    -- pluck: nil elements in list should not crash
    T("pluck: nil in list doesn't crash",
        type(funk.pluck({{name="A"}, nil, {name="C"}}, "name")) == "table")

    -- String functions: nil input
    N("trim: nil",       funk.trim(nil))
    N("trimStart: nil",  funk.trimStart(nil))
    N("trimEnd: nil",    funk.trimEnd(nil))
    N("capitalize: nil", funk.capitalize(nil))
    N("upperCase: nil",  funk.upperCase(nil))
    N("lowerCase: nil",  funk.lowerCase(nil))
    N("repeat: nil",     funk["repeat"](nil, 3))
    N("pad: nil",        funk.pad(nil, 5))
    N("padStart: nil",   funk.padStart(nil, 5))
    N("padEnd: nil",     funk.padEnd(nil, 5))
    E("split: nil str",  funk.split(nil, ","),  {})
    E("split: nil sep",  funk.split("abc", nil), {"abc"})
    F("startsWith: nil str", funk.startsWith(nil, "x"))
    F("endsWith: nil str",   funk.endsWith(nil, "x"))
    F("startsWith: nil prefix", funk.startsWith("hello", nil))
    F("endsWith: nil suffix",   funk.endsWith("hello", nil))
end

-- ---------------------------------------------------------------------------
-- Run all test suites
-- ---------------------------------------------------------------------------

local _SUITES = {
    {"each",                test_each},
    {"map",                 test_map},
    {"mapWithIndex",        test_mapWithIndex},
    {"reduce",              test_reduce},
    {"reduceRight",         test_reduceRight},
    {"filter",              test_filter},
    {"reject",              test_reject},
    {"find",                test_find},
    {"findIndex",           test_findIndex},
    {"every/some",          test_every_some},
    {"includes",            test_includes},
    {"pluck",               test_pluck},
    {"groupBy",             test_groupBy},
    {"countBy",             test_countBy},
    {"partition",           test_partition},
    {"sort/sortBy",         test_sort},
    {"min/max",             test_min_max},
    {"sum/mean",            test_sum_mean},
    {"first/last/rest",     test_array_slices},
    {"slice",               test_slice},
    {"chunk",               test_chunk},
    {"flatten",             test_flatten},
    {"compact",             test_compact},
    {"uniq",                test_uniq},
    {"without",             test_without},
    {"set operations",      test_set_ops},
    {"zip",                 test_zip},
    {"indexOf",             test_indexOf},
    {"range",               test_range},
    {"reverse",             test_reverse},
    {"concat",              test_concat},
    {"array mutation",      test_array_mutation},
    {"splice",              test_splice},
    {"join",                test_join},
    {"object functions",    test_object_funcs},
    {"assign/defaults",     test_object_merge},
    {"pick/omit",           test_pick_omit},
    {"clone",               test_clone},
    {"invert/mapValues",    test_invert_mapValues},
    {"isEmpty/isEqual",     test_utility},
    {"compose/pipe",        test_compose_pipe},
    {"curry/flip/negate",   test_func_utils},
    {"once/memoize/after",  test_func_control},
    {"times",               test_times},
    {"strings",             test_strings},
    {"numbers",             test_numbers},
    {"type checks",         test_types},
    {"chaining",            test_chaining},
    {"mixin",               test_mixin},
    {"no global pollution", test_no_global_pollution},
    {"nil safety",          test_nil_safety},
}

-- -----------------------------------------------------------------------------
-- funk_test.run()
-- Executes all test suites and prints a summary.
-- Call this from in-game (/run funk_test.run()) or from the Lua REPL.
-- -----------------------------------------------------------------------------
function funk_test.run()
    _results = { passed = 0, failed = 0, errors = {} }

    _out("|cFFFFFF00═══════════════════════════════════════|r")
    _out("|cFFFFFF00  funk.lua — test suite                |r")
    _out("|cFFFFFF00═══════════════════════════════════════|r")

    for _, suite in ipairs(_SUITES) do
        local name, fn = suite[1], suite[2]
        _out("|cFFAAAAAA── " .. name .. " ──|r")
        local ok, err = pcall(fn)
        if not ok then
            _fail(name .. " [ERROR]", nil, nil, err)
        end
    end

    _out("|cFFAAAAAA─────────────────────────────────────|r")
    local total = _results.passed + _results.failed
    local color = _results.failed == 0 and "|cFF00FF00" or "|cFFFF4444"
    _out(color .. string.format(
        "Results: %d / %d passed  (%d failed)|r",
        _results.passed, total, _results.failed
    ))
    if table.getn(_results.errors) > 0 then
        _out("|cFFFF4444Failed tests:|r")
        for _, name in ipairs(_results.errors) do
            _out("  |cFFFF4444• " .. name .. "|r")
        end
    end

    return _results.failed == 0
end

-- Share via the WoW per-addon namespace table when available (no _G pollution).
if _ns ~= nil then
    _ns.funk_test = funk_test
end
return funk_test
