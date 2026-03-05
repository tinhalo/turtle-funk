# turtle-funk

Functional programming (think lodash / ramda) for TurtleWoW — written in Lua 5.0-compatible syntax.

---

## Why?

TurtleWoW add-ons are written in Lua but the WoW client ships almost no standard utility library.  This project fills that gap with a battle-tested, well-documented functional toolkit inspired by:

| Reference | What we borrowed |
|-----------|-----------------|
| [underscore.lua](https://github.com/mirven/underscore.lua) | Lua idioms, coroutine-based iterators |
| [lodash](https://lodash.com/docs) | API shape, naming, chaining |
| [ramda](https://ramdajs.com/docs) | Immutability-first, compose/pipe, type predicates |

---

## Files

| File | Purpose |
|------|---------|
| `funk.lua` | Core functional library — **copy this into your addon** |
| `funk_debug.lua` | WoW-specific debug output (chat frame, whispers, timers) |
| `funk_test.lua` | In-game test runner (168 tests, all pass) |
| `FunkDemo.lua` | In-game interactive demo window — run live examples of every function |
| `FunkDemo.toc` | WoW addon manifest — loads all files as the `FunkDemo` addon |

---

## FunkDemo — in-game interactive demo

`FunkDemo.toc` bundles all four files as a standalone WoW addon.
Copy the entire repository folder into your `Interface/AddOns/FunkDemo/` directory, then:

1. Log in and type `/funkdemo` to open the demo window.
2. Click any button to run that function's demo — output appears in the chat frame.
3. Use **Previous** / **Next** to page through all 40 demos.
4. Click **runtests** to execute the full 168-test suite.

---

## Quick-start

```lua
-- ── WoW addon (.toc) — zero global-namespace pollution ──────────────────────
-- WoW passes (addonName, addonTable) as ... to every file it loads via .toc.
-- The addonTable is a per-addon namespace shared between all files in the same
-- .toc.  Nothing is written to _G; other addons are completely unaffected.
local _, ns = ...        -- capture the WoW per-addon namespace
local F = ns.funk        -- populated by funk.lua (listed first in .toc)
local D = ns.funk_debug  -- populated by funk_debug.lua

-- Map / filter / reduce
local doubled  = F.map({1,2,3,4}, function(x) return x * 2 end)
-- → {2, 4, 6, 8}

local evens    = F.filter({1,2,3,4,5}, function(x) return x % 2 == 0 end)
-- → {2, 4}

local total    = F.reduce({1,2,3,4}, 0, function(acc, x) return acc + x end)
-- → 10

-- Sort by a property
local players  = {{name="Arthas",level=60},{name="Jaina",level=55}}
local sorted   = F.sortBy(players, "level")
-- → {{name="Jaina",level=55},{name="Arthas",level=60}}

-- Compose functions (right-to-left, like ramda)
local process = F.compose(
    function(x) return x * 2 end,
    function(x) return x + 1 end
)
process(3)  -- → 8   (3+1=4, 4*2=8)

-- Chaining (like lodash)
local result = F.chain({3,1,4,1,5,9,2,6})
    :filter(function(x) return x > 2 end)
    :sort(function(a,b) return a < b end)
    :map(function(x) return x * 10 end)
    :value()
-- → {30, 40, 50, 60, 90}

-- Debug output
D.log("sorted players", sorted)
D.dump({hp=100, mana=80, level=60})
D.whisper("Arthas", "Your HP is %d", UnitHealth("player"))
```

---

## JS ↔ Lua quick-reference

| Concept | JavaScript | Lua |
|---------|-----------|-----|
| Array index | `arr[0]` (0-based) | `arr[1]` (1-based) |
| Undefined / null | `undefined` / `null` | `nil` |
| Array length | `arr.length` | `#arr` |
| String concat | `"a" + "b"` | `"a" .. "b"` |
| Arrow function | `(x) => x * 2` | `function(x) return x*2 end` |
| Spread | `fn(...args)` | `fn(unpack(args))` |
| `for-of` | `for (const v of arr)` | `for _,v in ipairs(arr)` |
| Object literal | `{ key: value }` | `{ key = value }` |
| `typeof` | `typeof x` | `type(x)` |
| Strict equal | `===` | `==` (Lua has no `===`) |
| Ternary | `cond ? a : b` | `cond and a or b` |
| Truthy `0` / `""` | **falsy** in JS | **truthy** in Lua |
| `nil` in array | valid `undefined` slot | creates a **hole** — avoid! |

---

## API Reference

### Collection functions

| Function | lodash equiv | ramda equiv | Description |
|----------|-------------|-------------|-------------|
| `F.each(list, fn)` | `_.forEach` | `R.forEach` | Iterate for side-effects |
| `F.eachWithIndex(list, fn)` | `_.forEach` (with index) | — | Iterate with 1-based index |
| `F.map(list, fn)` | `_.map` | `R.map` | Transform each element |
| `F.mapWithIndex(list, fn)` | `_.map` (with index) | — | Transform with index |
| `F.reduce(list, init, fn)` | `_.reduce` | `R.reduce` | Accumulate into single value |
| `F.reduceRight(list, init, fn)` | `_.reduceRight` | `R.reduceRight` | Reduce right-to-left |
| `F.filter(list, pred)` | `_.filter` | `R.filter` | Keep matching elements |
| `F.reject(list, pred)` | `_.reject` | `R.reject` | Remove matching elements |
| `F.find(list, pred)` | `_.find` | `R.find` | First matching element |
| `F.findIndex(list, pred)` | `_.findIndex` | — | 1-based index of first match |
| `F.every(list, pred)` | `_.every` | `R.all` | True if all match |
| `F.some(list, pred)` | `_.some` | `R.any` | True if any match |
| `F.includes(list, value)` | `_.includes` | `R.includes` | Membership test |
| `F.pluck(list, key)` | `_.map(list, key)` | `R.pluck` | Extract property |
| `F.invoke(list, method, ...)` | `_.invokeMap` | — | Call method on each |
| `F.groupBy(list, fn)` | `_.groupBy` | `R.groupBy` | Group into sub-arrays |
| `F.countBy(list, fn)` | `_.countBy` | — | Count groups |
| `F.partition(list, pred)` | `_.partition` | `R.partition` | Split into two arrays |
| `F.sortBy(list, fn)` | `_.sortBy` | `R.sortBy` | Sort by computed key |
| `F.sort(list, cmp)` | `_.sortBy` | — | Sort with raw comparator |
| `F.min(list, fn)` | `_.minBy` | `R.minBy` | Element with smallest score |
| `F.max(list, fn)` | `_.maxBy` | `R.maxBy` | Element with largest score |
| `F.sum(list, fn)` | `_.sumBy` | — | Sum values |
| `F.mean(list, fn)` | `_.meanBy` | — | Average values |

**Aliases:** `forEach=each`, `collect=map`, `foldl=inject=reduce`, `foldr=reduceRight`, `select=filter`, `detect=find`, `all=every`, `any=some`, `contains=include=includes`

---

### Array functions

| Function | lodash equiv | Description |
|----------|-------------|-------------|
| `F.first(arr, n?)` | `_.first` / `_.take` | First element or first n |
| `F.last(arr, n?)` | `_.last` / `_.takeRight` | Last element or last n |
| `F.rest(arr, i?)` | `_.tail` / `_.drop` | Skip first i elements (default: skip 1) |
| `F.initial(arr, n?)` | `_.initial` | All but last n (default: 1) |
| `F.slice(arr, start, len)` | `_.slice` | Slice by start + length |
| `F.chunk(arr, size)` | `_.chunk` | Split into groups of size |
| `F.flatten(arr)` | `_.flattenDeep` | Deep recursive flatten |
| `F.flattenShallow(arr)` | `_.flatten` | One-level flatten |
| `F.compact(arr)` | `_.compact` | Remove `false` / `nil` values |
| `F.uniq(arr, fn?)` | `_.uniq` / `_.uniqBy` | Deduplicate |
| `F.without(arr, ...)` | `_.without` | Remove specific values |
| `F.union(...)` | `_.union` | Unique union of arrays |
| `F.intersection(...)` | `_.intersection` | Common elements |
| `F.difference(arr, ...)` | `_.difference` | Elements not in others |
| `F.zip(...)` | `_.zip` | Zip arrays together |
| `F.zipObject(keys, vals)` | `_.zipObject` | Create table from parallel arrays |
| `F.indexOf(arr, val, from?)` | `_.indexOf` | 1-based index or -1 |
| `F.lastIndexOf(arr, val)` | `_.lastIndexOf` | Last occurrence index |
| `F.range(start, stop?, step?)` | `_.range` | Numeric range array |
| `F.reverse(arr)` | `_.reverse` | Non-mutating reverse |
| `F.concat(...)` | `_.concat` | Merge arrays (one level) |
| `F.toArray(iter)` | `_.toArray` | Materialise iterator |
| `F.push(arr, v)` | — | Append (mutating) |
| `F.pop(arr)` | — | Remove last (mutating) |
| `F.shift(arr)` | — | Remove first (mutating) |
| `F.unshift(arr, v)` | — | Prepend (mutating) |
| `F.splice(arr, i, n, ...)` | — | Remove/insert (mutating) |
| `F.join(arr, sep?)` | `_.join` | Concatenate with separator |

**Aliases:** `head=first`, `take=first`, `tail=drop=rest`

---

### Object functions

| Function | lodash equiv | ramda equiv | Description |
|----------|-------------|-------------|-------------|
| `F.keys(obj)` | `_.keys` | `R.keys` | Array of keys |
| `F.values(obj)` | `_.values` | `R.values` | Array of values |
| `F.entries(obj)` | `_.toPairs` | `R.toPairs` | Array of `{k, v}` pairs |
| `F.fromEntries(pairs)` | `_.fromPairs` | `R.fromPairs` | Table from `{k, v}` pairs |
| `F.assign(dst, ...)` | `_.assign` | `R.mergeRight` | Shallow copy (mutating) |
| `F.merge(dst, ...)` | `_.merge` | `R.mergeDeepRight` | Deep merge (mutating) |
| `F.defaults(obj, ...)` | `_.defaults` | — | Fill missing keys only |
| `F.clone(obj)` | `_.clone` | — | Shallow clone |
| `F.cloneDeep(obj)` | `_.cloneDeep` | `R.clone` | Deep clone |
| `F.pick(obj, keys)` | `_.pick` | `R.pick` | New table with only keys |
| `F.omit(obj, keys)` | `_.omit` | `R.omit` | New table without keys |
| `F.has(obj, key)` | `_.has` | `R.has` | Key existence check |
| `F.invert(obj)` | `_.invert` | `R.invertObj` | Swap keys and values |
| `F.mapValues(obj, fn)` | `_.mapValues` | `R.map` (obj) | Transform values, keep keys |
| `F.mapKeys(obj, fn)` | `_.mapKeys` | — | Transform keys, keep values |
| `F.filterObject(obj, pred)` | `_.pickBy` | — | Keep entries matching pred |
| `F.isEmpty(v)` | `_.isEmpty` | `R.isEmpty` | Empty table / string / nil |
| `F.isEqual(a, b)` | `_.isEqual` | `R.equals` | Deep equality |
| `F.size(v)` | `_.size` | — | Count entries or string length |

**Aliases:** `extend=assign`, `toPairs=entries`, `fromPairs=fromEntries`, `pickBy=filterObject`

---

### Function utilities

| Function | lodash equiv | ramda equiv | Description |
|----------|-------------|-------------|-------------|
| `F.identity(v)` | `_.identity` | `R.identity` | Returns its argument |
| `F.constant(v)` | `_.constant` | `R.always` | Returns a function that always returns v |
| `F.noop()` | `_.noop` | — | Does nothing |
| `F.compose(f, g, ...)` | `_.flowRight` | `R.compose` | Right-to-left composition |
| `F.pipe(f, g, ...)` | `_.flow` | `R.pipe` | Left-to-right composition |
| `F.curry(fn, ...)` | `_.partial` | `R.partial` | Pre-fill arguments |
| `F.flip(fn)` | — | `R.flip` | Swap first two arguments |
| `F.negate(pred)` | `_.negate` | `R.complement` | Invert a predicate |
| `F.once(fn)` | `_.once` | `R.once` | Call fn only once, cache result |
| `F.memoize(fn, resolver?)` | `_.memoize` | — | Cache return values |
| `F.wrap(fn, wrapper)` | `_.wrap` | — | Wrap fn inside wrapper |
| `F.after(n, fn)` | `_.after` | — | Call fn only after n invocations |
| `F.before(n, fn)` | `_.before` | — | Call fn only for first n invocations |
| `F.times(n, fn)` | `_.times` | `R.times` | Call fn n times, return results |

**Aliases:** `flowRight=compose`, `flow=pipe`, `partial=curry`, `complement=negate`, `always=constant`

---

### String utilities

| Function | lodash / JS equiv | Description |
|----------|--------------------|-------------|
| `F.trim(s)` | `_.trim` / `s.trim()` | Strip leading and trailing whitespace |
| `F.trimStart(s)` | `_.trimStart` | Strip leading whitespace |
| `F.trimEnd(s)` | `_.trimEnd` | Strip trailing whitespace |
| `F.split(s, sep, max?)` | `_.split` / `s.split()` | Split by separator |
| `F.startsWith(s, pre)` | `_.startsWith` | Prefix check |
| `F.endsWith(s, suf)` | `_.endsWith` | Suffix check |
| `F.capitalize(s)` | `_.capitalize` | First letter upper, rest lower |
| `F.upperCase(s)` | `_.toUpper` | Full upper-case |
| `F.lowerCase(s)` | `_.toLower` | Full lower-case |
| `F["repeat"](s, n)` | `_.repeat` | Repeat string n times |
| `F.pad(s, len, chars?)` | `_.pad` | Center-pad string |
| `F.padStart(s, len, chars?)` | `_.padStart` | Left-pad string |
| `F.padEnd(s, len, chars?)` | `_.padEnd` | Right-pad string |

> **Note:** `repeat` is a reserved keyword in Lua; call it as `F["repeat"](str, n)`.

---

### Number utilities

| Function | lodash equiv | Description |
|----------|-------------|-------------|
| `F.clamp(v, min, max)` | `_.clamp` | Constrain value to range |
| `F.inRange(v, start, stop?)` | `_.inRange` | Check if v is in [start, stop) |
| `F.random(lo?, hi?, float?)` | `_.random` | Random number in range |

---

### Type predicates

```lua
F.isNil(v)       -- v == nil
F.isBoolean(v)
F.isNumber(v)
F.isString(v)
F.isTable(v)
F.isFunction(v)
F.isArray(v)     -- sequential integer-keyed table
F.isObject(v)    -- table that is NOT an array
```

---

### Chaining

```lua
local result = funk.chain(list)
    :map(fn)
    :filter(pred)
    :sort(cmp)
    :value()    -- unwrap
```

Every function in `funk` is available as a chain method.  The wrapped value is
passed as the first argument automatically.

---

### Mixin — add your own functions

```lua
funk.mixin({
    double = function(arr)
        return funk.map(arr, function(x) return x * 2 end)
    end,
})

-- Now available on funk and in chains:
funk.double({1, 2, 3})        -- → {2, 4, 6}
funk.chain({1,2,3}):double():value()
```

---

## Debug utilities (`funk_debug`)

```lua
-- In a WoW addon file (after funk_debug.lua in the .toc):
local _, ns = ...
local D = ns.funk_debug

D.log("label", value)            -- grey label + serialised value in chat
D.dump(value, "optional label")  -- pretty-print any Lua value
D.error("Something went wrong!")  -- red text in chat + UIErrorsFrame
D.warn("Watch out: %s", reason)
D.info("Loaded %d spells", count)
D.table(tbl, "Bag items")        -- key: value list in chat
D.whisper("PlayerName", "HP=%d", hp)  -- in-game whisper to self/friend
D.say("Debug value: %d", val)    -- /say in world
D.assert(condition, "msg %s", detail) -- chat assert (no Lua error)
D.time("sortSpells", function()  -- benchmark a function
    table.sort(spellList)
end)
serialized = D.serialize(value)  -- JSON-like string
```

All output uses WoW's `|cAARRGGBB...|r` colour markup for readability.

---

## Running tests

**From the Lua command line (for development):**
```bash
lua5.1 -e "
  local funk = dofile('funk.lua')
  local funk_debug = dofile('funk_debug.lua')
  local funk_test = dofile('funk_test.lua')
  funk_test.run()
"
```

**Inside WoW (in-game `/run` command):**
```lua
/run
-- Requires funk_test.lua to be loaded in your .toc after funk.lua and funk_debug.lua.
local _, ns = ...
ns.funk_test.run()
```

Expected output: `Results: 171 / 171 passed  (0 failed)`

Three of those tests (`no global pollution` suite) specifically assert that
`_G.funk`, `_G.funk_debug`, and `_G.funk_test` are **nil** after loading via
`dofile`, confirming the library does not pollute the global namespace.

---

## WoW addon integration

### Minimal `.toc` example

```
## Interface: 11200
## Title: MyAddOn
## Notes: Powered by turtle-funk
## Version: 1.0

funk.lua
funk_debug.lua
MyAddOn.lua
```

### Typical usage pattern in WoW

```lua
-- MyAddOn.lua
-- WoW passes (addonName, addonTable) as ... to every .toc file.
-- funk.lua and funk_debug.lua have already been loaded and stored
-- themselves in ns, so we read from ns — no _G access at all.
local _, ns = ...
local F = ns.funk
local D = ns.funk_debug

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()

    -- Get all items in bag slot 0 with their counts
    local bagItems = {}
    for slot = 0, GetContainerNumSlots(0) do
        local link = GetContainerItemLink(0, slot)
        if link then
            local _, count = GetContainerItemInfo(0, slot)
            bagItems[#bagItems+1] = {link=link, count=count or 1}
        end
    end

    -- Sort by count descending, show top 5
    local top5 = F.chain(bagItems)
        :sortBy(function(i) return -i.count end)
        :first(5)
        :value()

    D.log("Top 5 stacks", F.pluck(top5, "count"))

end)
```

---

## Key design decisions

1. **Immutable by default** — all collection functions return new tables; the
   original is never mutated (matching ramda's philosophy).  Exception: the
   explicit `push/pop/shift/unshift/splice` methods match JS's mutating API.

2. **1-based indexing** — Lua arrays start at index 1.  `funk.range(4)` returns
   `{1,2,3}` (not `{0,1,2,3}`).  `funk.first({a,b,c})` returns `a`.

3. **Truthy rules differ from JS** — In Lua, `0` and `""` are **truthy**.  Only
   `false` and `nil` are falsy.  `funk.compact` removes only those two values.

4. **No `nil` in arrays** — Storing `nil` at an array index creates a "hole"
   that the `#` operator and `ipairs` may not traverse past.  Use sentinel
   values instead.

5. **`unpack` not `table.unpack`** — Lua 5.0/5.1 uses the global `unpack`.
   Lua 5.2+ moved it to `table.unpack`.  All code here uses the 5.1 form.

6. **No global namespace pollution** — WoW Lua has no `require`, but every
   `.toc` file receives `(addonName, addonTable)` as `...`.  All three library
   files store themselves in `addonTable` (the per-addon namespace), not in
   `_G`.  Use `local _, ns = ...` then `local F = ns.funk` in your addon files.

---

## License

MIT — see [LICENSE](LICENSE)
