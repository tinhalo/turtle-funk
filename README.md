# turtle-funk

Functional programming (think lodash / ramda) for TurtleWoW — written in Lua 5.0-compatible syntax.

---

## Why?

TurtleWoW add-ons are written in Lua but the WoW client ships almost no standard utility library.  This project fills that gap with a battle-tested, well-documented functional toolkit inspired by:

<table>
<thead>
<tr>
  <th align="left">Reference</th>
  <th align="left">What we borrowed</th>
</tr>
</thead>
<tbody>
<tr>
  <td><a href="https://github.com/mirven/underscore.lua">underscore.lua</a></td>
  <td>Lua idioms, coroutine-based iterators</td>
</tr>
<tr>
  <td><a href="https://lodash.com/docs">lodash</a></td>
  <td>API shape, naming, chaining</td>
</tr>
<tr>
  <td><a href="https://ramdajs.com/docs">ramda</a></td>
  <td>Immutability-first, compose/pipe, type predicates</td>
</tr>
</tbody>
</table>

---

## Files

<table>
<thead>
<tr>
  <th align="left">File</th>
  <th align="left">Purpose</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>funk.lua</code></td>
  <td>Core functional library — <strong>copy this into your addon</strong></td>
</tr>
<tr>
  <td><code>funk_debug.lua</code></td>
  <td>WoW-specific debug output (chat frame, whispers, timers)</td>
</tr>
<tr>
  <td><code>funk_test.lua</code></td>
  <td>In-game test runner (168 tests, all pass)</td>
</tr>
<tr>
  <td><code>FunkDemo.lua</code></td>
  <td>In-game interactive demo window — run live examples of every function</td>
</tr>
<tr>
  <td><code>FunkDemo.toc</code></td>
  <td>WoW addon manifest — loads all files as the <code>FunkDemo</code> addon</td>
</tr>
</tbody>
</table>

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

local evens    = F.filter({1,2,3,4,5}, function(x) return math.mod(x, 2) == 0 end)
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

<table>
<thead>
<tr>
  <th align="left">Concept</th>
  <th align="left">JavaScript</th>
  <th align="left">Lua</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Array index</td>
  <td><code>arr[0]</code> (0-based)</td>
  <td><code>arr[1]</code> (1-based)</td>
</tr>
<tr>
  <td>Undefined / null</td>
  <td><code>undefined</code> / <code>null</code></td>
  <td><code>nil</code></td>
</tr>
<tr>
  <td>Array length</td>
  <td><code>arr.length</code></td>
  <td><code>table.getn(arr)</code> (5.0) / <code>#arr</code> (5.1+)</td>
</tr>
<tr>
  <td>String concat</td>
  <td><code>"a" + "b"</code></td>
  <td><code>"a" .. "b"</code></td>
</tr>
<tr>
  <td>Arrow function</td>
  <td><code>(x) => x * 2</code></td>
  <td><code>function(x) return x*2 end</code></td>
</tr>
<tr>
  <td>Spread</td>
  <td><code>fn(...args)</code></td>
  <td><code>fn(unpack(args))</code></td>
</tr>
<tr>
  <td><code>for-of</code></td>
  <td><code>for (const v of arr)</code></td>
  <td><code>for _,v in ipairs(arr)</code></td>
</tr>
<tr>
  <td>Object literal</td>
  <td><code>{ key: value }</code></td>
  <td><code>{ key = value }</code></td>
</tr>
<tr>
  <td><code>typeof</code></td>
  <td><code>typeof x</code></td>
  <td><code>type(x)</code></td>
</tr>
<tr>
  <td>Strict equal</td>
  <td><code>===</code></td>
  <td><code>==</code> (Lua has no <code>===</code>)</td>
</tr>
<tr>
  <td>Ternary</td>
  <td><code>cond ? a : b</code></td>
  <td><code>cond and a or b</code></td>
</tr>
<tr>
  <td>Truthy <code>0</code> / <code>""</code></td>
  <td><strong>falsy</strong> in JS</td>
  <td><strong>truthy</strong> in Lua</td>
</tr>
<tr>
  <td><code>nil</code> in array</td>
  <td>valid <code>undefined</code> slot</td>
  <td>creates a <strong>hole</strong> — avoid!</td>
</tr>
</tbody>
</table>

---

## API Reference

### Collection functions

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash equiv</th>
  <th align="left">ramda equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.each(list, fn)</code></td>
  <td><code>_.forEach</code></td>
  <td><code>R.forEach</code></td>
  <td>Iterate for side-effects</td>
</tr>
<tr>
  <td><code>F.eachWithIndex(list, fn)</code></td>
  <td><code>_.forEach</code> (with index)</td>
  <td>—</td>
  <td>Iterate with 1-based index</td>
</tr>
<tr>
  <td><code>F.map(list, fn)</code></td>
  <td><code>_.map</code></td>
  <td><code>R.map</code></td>
  <td>Transform each element</td>
</tr>
<tr>
  <td><code>F.mapWithIndex(list, fn)</code></td>
  <td><code>_.map</code> (with index)</td>
  <td>—</td>
  <td>Transform with index</td>
</tr>
<tr>
  <td><code>F.reduce(list, init, fn)</code></td>
  <td><code>_.reduce</code></td>
  <td><code>R.reduce</code></td>
  <td>Accumulate into single value</td>
</tr>
<tr>
  <td><code>F.reduceRight(list, init, fn)</code></td>
  <td><code>_.reduceRight</code></td>
  <td><code>R.reduceRight</code></td>
  <td>Reduce right-to-left</td>
</tr>
<tr>
  <td><code>F.filter(list, pred)</code></td>
  <td><code>_.filter</code></td>
  <td><code>R.filter</code></td>
  <td>Keep matching elements</td>
</tr>
<tr>
  <td><code>F.reject(list, pred)</code></td>
  <td><code>_.reject</code></td>
  <td><code>R.reject</code></td>
  <td>Remove matching elements</td>
</tr>
<tr>
  <td><code>F.find(list, pred)</code></td>
  <td><code>_.find</code></td>
  <td><code>R.find</code></td>
  <td>First matching element</td>
</tr>
<tr>
  <td><code>F.findIndex(list, pred)</code></td>
  <td><code>_.findIndex</code></td>
  <td>—</td>
  <td>1-based index of first match</td>
</tr>
<tr>
  <td><code>F.every(list, pred)</code></td>
  <td><code>_.every</code></td>
  <td><code>R.all</code></td>
  <td>True if all match</td>
</tr>
<tr>
  <td><code>F.some(list, pred)</code></td>
  <td><code>_.some</code></td>
  <td><code>R.any</code></td>
  <td>True if any match</td>
</tr>
<tr>
  <td><code>F.includes(list, value)</code></td>
  <td><code>_.includes</code></td>
  <td><code>R.includes</code></td>
  <td>Membership test</td>
</tr>
<tr>
  <td><code>F.pluck(list, key)</code></td>
  <td><code>_.map(list, key)</code></td>
  <td><code>R.pluck</code></td>
  <td>Extract property</td>
</tr>
<tr>
  <td><code>F.invoke(list, method, ...)</code></td>
  <td><code>_.invokeMap</code></td>
  <td>—</td>
  <td>Call method on each</td>
</tr>
<tr>
  <td><code>F.groupBy(list, fn)</code></td>
  <td><code>_.groupBy</code></td>
  <td><code>R.groupBy</code></td>
  <td>Group into sub-arrays</td>
</tr>
<tr>
  <td><code>F.countBy(list, fn)</code></td>
  <td><code>_.countBy</code></td>
  <td>—</td>
  <td>Count groups</td>
</tr>
<tr>
  <td><code>F.partition(list, pred)</code></td>
  <td><code>_.partition</code></td>
  <td><code>R.partition</code></td>
  <td>Split into two arrays</td>
</tr>
<tr>
  <td><code>F.sortBy(list, fn)</code></td>
  <td><code>_.sortBy</code></td>
  <td><code>R.sortBy</code></td>
  <td>Sort by computed key</td>
</tr>
<tr>
  <td><code>F.sort(list, cmp)</code></td>
  <td><code>_.sortBy</code></td>
  <td>—</td>
  <td>Sort with raw comparator</td>
</tr>
<tr>
  <td><code>F.min(list, fn)</code></td>
  <td><code>_.minBy</code></td>
  <td><code>R.minBy</code></td>
  <td>Element with smallest score</td>
</tr>
<tr>
  <td><code>F.max(list, fn)</code></td>
  <td><code>_.maxBy</code></td>
  <td><code>R.maxBy</code></td>
  <td>Element with largest score</td>
</tr>
<tr>
  <td><code>F.sum(list, fn)</code></td>
  <td><code>_.sumBy</code></td>
  <td>—</td>
  <td>Sum values</td>
</tr>
<tr>
  <td><code>F.mean(list, fn)</code></td>
  <td><code>_.meanBy</code></td>
  <td>—</td>
  <td>Average values</td>
</tr>
</tbody>
</table>

**Aliases:** `forEach=each`, `collect=map`, `foldl=inject=reduce`, `foldr=reduceRight`, `select=filter`, `detect=find`, `all=every`, `any=some`, `contains=include=includes`

---

### Array functions

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.first(arr, n?)</code></td>
  <td><code>_.first</code> / <code>_.take</code></td>
  <td>First element or first n</td>
</tr>
<tr>
  <td><code>F.last(arr, n?)</code></td>
  <td><code>_.last</code> / <code>_.takeRight</code></td>
  <td>Last element or last n</td>
</tr>
<tr>
  <td><code>F.rest(arr, i?)</code></td>
  <td><code>_.tail</code> / <code>_.drop</code></td>
  <td>Skip first i elements (default: skip 1)</td>
</tr>
<tr>
  <td><code>F.initial(arr, n?)</code></td>
  <td><code>_.initial</code></td>
  <td>All but last n (default: 1)</td>
</tr>
<tr>
  <td><code>F.slice(arr, start, len)</code></td>
  <td><code>_.slice</code></td>
  <td>Slice by start + length</td>
</tr>
<tr>
  <td><code>F.chunk(arr, size)</code></td>
  <td><code>_.chunk</code></td>
  <td>Split into groups of size</td>
</tr>
<tr>
  <td><code>F.flatten(arr)</code></td>
  <td><code>_.flattenDeep</code></td>
  <td>Deep recursive flatten</td>
</tr>
<tr>
  <td><code>F.flattenShallow(arr)</code></td>
  <td><code>_.flatten</code></td>
  <td>One-level flatten</td>
</tr>
<tr>
  <td><code>F.compact(arr)</code></td>
  <td><code>_.compact</code></td>
  <td>Remove <code>false</code> / <code>nil</code> values</td>
</tr>
<tr>
  <td><code>F.uniq(arr, fn?)</code></td>
  <td><code>_.uniq</code> / <code>_.uniqBy</code></td>
  <td>Deduplicate</td>
</tr>
<tr>
  <td><code>F.without(arr, ...)</code></td>
  <td><code>_.without</code></td>
  <td>Remove specific values</td>
</tr>
<tr>
  <td><code>F.union(...)</code></td>
  <td><code>_.union</code></td>
  <td>Unique union of arrays</td>
</tr>
<tr>
  <td><code>F.intersection(...)</code></td>
  <td><code>_.intersection</code></td>
  <td>Common elements</td>
</tr>
<tr>
  <td><code>F.difference(arr, ...)</code></td>
  <td><code>_.difference</code></td>
  <td>Elements not in others</td>
</tr>
<tr>
  <td><code>F.zip(...)</code></td>
  <td><code>_.zip</code></td>
  <td>Zip arrays together</td>
</tr>
<tr>
  <td><code>F.zipObject(keys, vals)</code></td>
  <td><code>_.zipObject</code></td>
  <td>Create table from parallel arrays</td>
</tr>
<tr>
  <td><code>F.indexOf(arr, val, from?)</code></td>
  <td><code>_.indexOf</code></td>
  <td>1-based index or -1</td>
</tr>
<tr>
  <td><code>F.lastIndexOf(arr, val)</code></td>
  <td><code>_.lastIndexOf</code></td>
  <td>Last occurrence index</td>
</tr>
<tr>
  <td><code>F.range(start, stop?, step?)</code></td>
  <td><code>_.range</code></td>
  <td>Numeric range array</td>
</tr>
<tr>
  <td><code>F.reverse(arr)</code></td>
  <td><code>_.reverse</code></td>
  <td>Non-mutating reverse</td>
</tr>
<tr>
  <td><code>F.concat(...)</code></td>
  <td><code>_.concat</code></td>
  <td>Merge arrays (one level)</td>
</tr>
<tr>
  <td><code>F.toArray(iter)</code></td>
  <td><code>_.toArray</code></td>
  <td>Materialise iterator</td>
</tr>
<tr>
  <td><code>F.push(arr, v)</code></td>
  <td>—</td>
  <td>Append (mutating)</td>
</tr>
<tr>
  <td><code>F.pop(arr)</code></td>
  <td>—</td>
  <td>Remove last (mutating)</td>
</tr>
<tr>
  <td><code>F.shift(arr)</code></td>
  <td>—</td>
  <td>Remove first (mutating)</td>
</tr>
<tr>
  <td><code>F.unshift(arr, v)</code></td>
  <td>—</td>
  <td>Prepend (mutating)</td>
</tr>
<tr>
  <td><code>F.splice(arr, i, n, ...)</code></td>
  <td>—</td>
  <td>Remove/insert (mutating)</td>
</tr>
<tr>
  <td><code>F.join(arr, sep?)</code></td>
  <td><code>_.join</code></td>
  <td>Concatenate with separator</td>
</tr>
</tbody>
</table>

**Aliases:** `head=first`, `take=first`, `tail=drop=rest`

---

### Object functions

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash equiv</th>
  <th align="left">ramda equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.keys(obj)</code></td>
  <td><code>_.keys</code></td>
  <td><code>R.keys</code></td>
  <td>Array of keys</td>
</tr>
<tr>
  <td><code>F.values(obj)</code></td>
  <td><code>_.values</code></td>
  <td><code>R.values</code></td>
  <td>Array of values</td>
</tr>
<tr>
  <td><code>F.entries(obj)</code></td>
  <td><code>_.toPairs</code></td>
  <td><code>R.toPairs</code></td>
  <td>Array of <code>{k, v}</code> pairs</td>
</tr>
<tr>
  <td><code>F.fromEntries(pairs)</code></td>
  <td><code>_.fromPairs</code></td>
  <td><code>R.fromPairs</code></td>
  <td>Table from <code>{k, v}</code> pairs</td>
</tr>
<tr>
  <td><code>F.assign(dst, ...)</code></td>
  <td><code>_.assign</code></td>
  <td><code>R.mergeRight</code></td>
  <td>Shallow copy (mutating)</td>
</tr>
<tr>
  <td><code>F.merge(dst, ...)</code></td>
  <td><code>_.merge</code></td>
  <td><code>R.mergeDeepRight</code></td>
  <td>Deep merge (mutating)</td>
</tr>
<tr>
  <td><code>F.defaults(obj, ...)</code></td>
  <td><code>_.defaults</code></td>
  <td>—</td>
  <td>Fill missing keys only</td>
</tr>
<tr>
  <td><code>F.clone(obj)</code></td>
  <td><code>_.clone</code></td>
  <td>—</td>
  <td>Shallow clone</td>
</tr>
<tr>
  <td><code>F.cloneDeep(obj)</code></td>
  <td><code>_.cloneDeep</code></td>
  <td><code>R.clone</code></td>
  <td>Deep clone</td>
</tr>
<tr>
  <td><code>F.pick(obj, keys)</code></td>
  <td><code>_.pick</code></td>
  <td><code>R.pick</code></td>
  <td>New table with only keys</td>
</tr>
<tr>
  <td><code>F.omit(obj, keys)</code></td>
  <td><code>_.omit</code></td>
  <td><code>R.omit</code></td>
  <td>New table without keys</td>
</tr>
<tr>
  <td><code>F.has(obj, key)</code></td>
  <td><code>_.has</code></td>
  <td><code>R.has</code></td>
  <td>Key existence check</td>
</tr>
<tr>
  <td><code>F.invert(obj)</code></td>
  <td><code>_.invert</code></td>
  <td><code>R.invertObj</code></td>
  <td>Swap keys and values</td>
</tr>
<tr>
  <td><code>F.mapValues(obj, fn)</code></td>
  <td><code>_.mapValues</code></td>
  <td><code>R.map</code> (obj)</td>
  <td>Transform values, keep keys</td>
</tr>
<tr>
  <td><code>F.mapKeys(obj, fn)</code></td>
  <td><code>_.mapKeys</code></td>
  <td>—</td>
  <td>Transform keys, keep values</td>
</tr>
<tr>
  <td><code>F.filterObject(obj, pred)</code></td>
  <td><code>_.pickBy</code></td>
  <td>—</td>
  <td>Keep entries matching pred</td>
</tr>
<tr>
  <td><code>F.isEmpty(v)</code></td>
  <td><code>_.isEmpty</code></td>
  <td><code>R.isEmpty</code></td>
  <td>Empty table / string / nil</td>
</tr>
<tr>
  <td><code>F.isEqual(a, b)</code></td>
  <td><code>_.isEqual</code></td>
  <td><code>R.equals</code></td>
  <td>Deep equality</td>
</tr>
<tr>
  <td><code>F.size(v)</code></td>
  <td><code>_.size</code></td>
  <td>—</td>
  <td>Count entries or string length</td>
</tr>
</tbody>
</table>

**Aliases:** `extend=assign`, `toPairs=entries`, `fromPairs=fromEntries`, `pickBy=filterObject`

---

### Function utilities

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash equiv</th>
  <th align="left">ramda equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.identity(v)</code></td>
  <td><code>_.identity</code></td>
  <td><code>R.identity</code></td>
  <td>Returns its argument</td>
</tr>
<tr>
  <td><code>F.constant(v)</code></td>
  <td><code>_.constant</code></td>
  <td><code>R.always</code></td>
  <td>Returns a function that always returns v</td>
</tr>
<tr>
  <td><code>F.noop()</code></td>
  <td><code>_.noop</code></td>
  <td>—</td>
  <td>Does nothing</td>
</tr>
<tr>
  <td><code>F.compose(f, g, ...)</code></td>
  <td><code>_.flowRight</code></td>
  <td><code>R.compose</code></td>
  <td>Right-to-left composition</td>
</tr>
<tr>
  <td><code>F.pipe(f, g, ...)</code></td>
  <td><code>_.flow</code></td>
  <td><code>R.pipe</code></td>
  <td>Left-to-right composition</td>
</tr>
<tr>
  <td><code>F.curry(fn, ...)</code></td>
  <td><code>_.partial</code></td>
  <td><code>R.partial</code></td>
  <td>Pre-fill arguments</td>
</tr>
<tr>
  <td><code>F.flip(fn)</code></td>
  <td>—</td>
  <td><code>R.flip</code></td>
  <td>Swap first two arguments</td>
</tr>
<tr>
  <td><code>F.negate(pred)</code></td>
  <td><code>_.negate</code></td>
  <td><code>R.complement</code></td>
  <td>Invert a predicate</td>
</tr>
<tr>
  <td><code>F.once(fn)</code></td>
  <td><code>_.once</code></td>
  <td><code>R.once</code></td>
  <td>Call fn only once, cache result</td>
</tr>
<tr>
  <td><code>F.memoize(fn, resolver?)</code></td>
  <td><code>_.memoize</code></td>
  <td>—</td>
  <td>Cache return values</td>
</tr>
<tr>
  <td><code>F.wrap(fn, wrapper)</code></td>
  <td><code>_.wrap</code></td>
  <td>—</td>
  <td>Wrap fn inside wrapper</td>
</tr>
<tr>
  <td><code>F.after(n, fn)</code></td>
  <td><code>_.after</code></td>
  <td>—</td>
  <td>Call fn only after n invocations</td>
</tr>
<tr>
  <td><code>F.before(n, fn)</code></td>
  <td><code>_.before</code></td>
  <td>—</td>
  <td>Call fn only for first n invocations</td>
</tr>
<tr>
  <td><code>F.times(n, fn)</code></td>
  <td><code>_.times</code></td>
  <td><code>R.times</code></td>
  <td>Call fn n times, return results</td>
</tr>
</tbody>
</table>

**Aliases:** `flowRight=compose`, `flow=pipe`, `partial=curry`, `complement=negate`, `always=constant`

---

### String utilities

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash / JS equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.trim(s)</code></td>
  <td><code>_.trim</code> / <code>s.trim()</code></td>
  <td>Strip leading and trailing whitespace</td>
</tr>
<tr>
  <td><code>F.trimStart(s)</code></td>
  <td><code>_.trimStart</code></td>
  <td>Strip leading whitespace</td>
</tr>
<tr>
  <td><code>F.trimEnd(s)</code></td>
  <td><code>_.trimEnd</code></td>
  <td>Strip trailing whitespace</td>
</tr>
<tr>
  <td><code>F.split(s, sep, max?)</code></td>
  <td><code>_.split</code> / <code>s.split()</code></td>
  <td>Split by separator</td>
</tr>
<tr>
  <td><code>F.startsWith(s, pre)</code></td>
  <td><code>_.startsWith</code></td>
  <td>Prefix check</td>
</tr>
<tr>
  <td><code>F.endsWith(s, suf)</code></td>
  <td><code>_.endsWith</code></td>
  <td>Suffix check</td>
</tr>
<tr>
  <td><code>F.capitalize(s)</code></td>
  <td><code>_.capitalize</code></td>
  <td>First letter upper, rest lower</td>
</tr>
<tr>
  <td><code>F.upperCase(s)</code></td>
  <td><code>_.toUpper</code></td>
  <td>Full upper-case</td>
</tr>
<tr>
  <td><code>F.lowerCase(s)</code></td>
  <td><code>_.toLower</code></td>
  <td>Full lower-case</td>
</tr>
<tr>
  <td><code>F["repeat"](s, n)</code></td>
  <td><code>_.repeat</code></td>
  <td>Repeat string n times</td>
</tr>
<tr>
  <td><code>F.pad(s, len, chars?)</code></td>
  <td><code>_.pad</code></td>
  <td>Center-pad string</td>
</tr>
<tr>
  <td><code>F.padStart(s, len, chars?)</code></td>
  <td><code>_.padStart</code></td>
  <td>Left-pad string</td>
</tr>
<tr>
  <td><code>F.padEnd(s, len, chars?)</code></td>
  <td><code>_.padEnd</code></td>
  <td>Right-pad string</td>
</tr>
</tbody>
</table>

> **Note:** `repeat` is a reserved keyword in Lua; call it as `F["repeat"](str, n)`.

---

### Number utilities

<table>
<thead>
<tr>
  <th align="left">Function</th>
  <th align="left">lodash equiv</th>
  <th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>F.clamp(v, min, max)</code></td>
  <td><code>_.clamp</code></td>
  <td>Constrain value to range</td>
</tr>
<tr>
  <td><code>F.inRange(v, start, stop?)</code></td>
  <td><code>_.inRange</code></td>
  <td>Check if v is in [start, stop)</td>
</tr>
<tr>
  <td><code>F.random(lo?, hi?, float?)</code></td>
  <td><code>_.random</code></td>
  <td>Random number in range</td>
</tr>
</tbody>
</table>

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
            bagItems[table.getn(bagItems)+1] = {link=link, count=count or 1}
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
