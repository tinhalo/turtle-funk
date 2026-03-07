# Copilot Instructions for turtle-funk

## Project Overview

turtle-funk is a functional programming library (inspired by lodash/ramda) for
**TurtleWoW**, a World of Warcraft 1.12 private server. All code targets
**Lua 5.0** and the **WoW 1.12 API** (Interface 11200).

## File Structure

| File | Purpose |
|------|---------|
| `funk.lua` | Core library — 111+ public utility functions |
| `funk_debug.lua` | WoW-specific debug/logging helpers |
| `funk_test.lua` | In-game test runner with 170+ assertions |
| `FunkDemo.lua` | Interactive demo window (`/funkdemo`) |
| `FunkDemo.toc` | WoW addon manifest |

## Things to Completely Avoid

### Lua 5.1+ Features

- **`#` length operator** — use `table.getn(t)` instead.
- **`%` modulo operator** — use `math.mod(a, b)` instead.
- **`string.gmatch`** — use `string.gfind` (Lua 5.0 name).
- **`table.insert` / `table.remove`** with modern semantics — prefer explicit
  index assignment: `t[table.getn(t) + 1] = value`.
- **`package.*` module system** — not available in WoW 1.12.
- **Metatables beyond Lua 5.0 support** — avoid `__len`, `__eq` on tables, and
  other metamethods added in Lua 5.1+.
- **Vararg syntax `...` in function bodies** — use the implicit `arg` table
  when handling variable arguments.

### WoW 2.0+ API

- Do not use any API introduced after WoW 1.12 (patch 2.0 / The Burning
  Crusade onwards).
- Do not use XML templates like `"BasicFrame"` — they do not exist in 1.12.
  Use `SetBackdrop()` with `DialogBox` textures, `CreateFontString` for titles,
  and `UIPanelCloseButton` for close buttons.
- Event handlers use implicit globals (`this`, `event`, `arg1`–`arg9`), not
  function parameters.

## Coding Conventions

### Naming

- **Functions**: `camelCase` — e.g., `funk.mapWithIndex`, `funk.groupBy`.
- **Internal helpers**: prefixed with `_` — e.g., `_iter`, `_identity`,
  `_deepEq`.
- **Constants**: `UPPER_SNAKE_CASE` — e.g., `COLOR.red`, `SLASH_FUNKDEMO1`.

### Namespace Pattern

Every file uses the shared per-addon namespace to avoid global pollution:

```lua
FunkDemo = FunkDemo or {}
local _ns = FunkDemo
```

Files export their module to the namespace at the end:

```lua
if _ns ~= nil then
    _ns.funk = funk
end
return funk
```

Never add globals to `_G` directly.

### Function Definitions

Public functions are defined on the module table:

```lua
function funk.functionName(list, iteratee)
    -- implementation
end
```

### Comment Style

Use the established comment patterns:

```lua
-- =============================================================================
-- File header with description
-- =============================================================================

-- ---------------------------------------------------------------------------
-- funk.functionName(param1, param2)
-- lodash: _.equivalent   ramda: R.equivalent
-- JS equivalent: arr.equivalent(fn)
--
-- Brief description of what the function does.
-- ---------------------------------------------------------------------------
function funk.functionName(param1, param2)
```

Section dividers:

```lua
-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION — CATEGORY NAME
-- Description of this category of functions.
-- ═══════════════════════════════════════════════════════════════════════════
```

## Error Handling

- Return `nil` for "not found" cases — do **not** throw with `error()`.
- Use defensive `nil` checks on parameters (e.g., `if n == nil then`).
- Wrap test suite execution in `pcall()` to catch unexpected errors.
- Gracefully fall back when WoW APIs are unavailable (standalone mode):

```lua
if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(text)
else
    print(text)
end
```

## Testing

### Writing Tests

Tests use the lightweight built-in runner in `funk_test.lua`. Use the
`funk_test.expect(description, got, expected)` helper for assertions:

```lua
local E = funk_test.expect

local function test_myFunction()
    E("myFunction: basic case", funk.myFunction({1,2,3}), {2,4,6})
    E("myFunction: empty input", funk.myFunction({}), {})
end
```

Register new test suites in the `_SUITES` table at the bottom of
`funk_test.lua`:

```lua
local _SUITES = {
    -- ... existing suites ...
    {"myFunction", test_myFunction},
}
```

### Running Tests

```bash
lua5.1 -e "
  local funk = dofile('funk.lua')
  local funk_debug = dofile('funk_debug.lua')
  local funk_test = dofile('funk_test.lua')
  funk_test.run()
"
```

Expected output: `Results: 171 / 171 passed  (0 failed)`

## Documentation

- Document every public function with a comment block showing the signature,
  lodash/ramda equivalents, JS equivalent, and a brief description.
- Keep the README.md API reference in sync when adding or changing functions.
- Include concrete usage examples in documentation.

## Debuggability

- Use `funk_debug.log(label, value)` for debug output — it pretty-prints tables
  and works both in WoW and standalone.
- Use `funk_debug.dump(table)` for inspecting complex data structures.
- Use `funk_debug.timer(label)` / `funk_debug.timerEnd(label)` for performance
  profiling.
