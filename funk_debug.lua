-- =============================================================================
-- funk_debug.lua — WoW / TurtleWoW debug output helpers
-- =============================================================================
-- Provides friendly helpers for printing values while developing add-ons.
-- All output targets the WoW client UI.  No standard I/O is available.
--
-- Available output channels:
--   1. DEFAULT_CHAT_FRAME — the main chat window (visible to the player only).
--   2. SendChatMessage   — actual in-game chat, including whispers.
--   3. UIErrorsFrame     — the small error/notification overlay.
--   4. print()           — WoW's built-in print, writes to the chat frame.
--
-- USAGE (inside your addon's .lua files):
--   local D = funk_debug
--
--   D.log("hello world")          -- grey label in chat frame
--   D.dump({1,2,3})               -- pretty-print a table
--   D.whisper("Arthas", "value=5")-- send a whisper to yourself
--   D.error("Something broke!")   -- red text in chat frame
-- =============================================================================

-- WoW .toc loader provides (addonName, addonTable) as varargs.
-- _ns is the per-addon namespace table populated by earlier .toc files.
-- When loaded via dofile() both are nil.
local _addonName, _ns = ...

-- Grab the funk library: prefer the namespace, fall back to the global (if the
-- caller set one deliberately), and finally use an empty stub.
local funk = (_ns and _ns.funk) or funk or {}

local funk_debug = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- Lua 5.0 may not have string.format on all versions, but WoW's Lua does.
local fmt = string.format

-- Color codes for WoW's rich text markup.
-- WoW uses |cAARRGGBB...text...|r  (hex, with leading AA = alpha).
local COLOR = {
    white  = "|cFFFFFFFF",
    grey   = "|cFFAAAAAA",
    yellow = "|cFFFFFF00",
    green  = "|cFF00FF00",
    red    = "|cFFFF4444",
    cyan   = "|cFF00FFFF",
    orange = "|cFFFF8C00",
    reset  = "|r",
}

-- _colorize(color, text) — wraps text in a WoW color code.
local function _colorize(color, text)
    return (COLOR[color] or "") .. tostring(text) .. COLOR.reset
end

-- _printLine(text) — writes a single line to the default chat frame.
-- Falls back to print() when DEFAULT_CHAT_FRAME is unavailable (testing).
local function _printLine(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(tostring(text))
    else
        print(tostring(text))
    end
end

-- ---------------------------------------------------------------------------
-- _serialize(value, indent, depth, maxDepth)
-- Converts any Lua value into a human-readable string.
--
-- In JavaScript you would use:  JSON.stringify(value, null, 2)
-- Lua has no built-in serialiser; this is a hand-rolled recursive version.
--
-- maxDepth prevents stack overflows on deeply nested or circular tables.
-- ---------------------------------------------------------------------------
local function _serialize(value, indent, depth, maxDepth)
    indent   = indent   or ""
    depth    = depth    or 0
    maxDepth = maxDepth or 5

    local t = type(value)

    if t == "nil"     then return "nil"
    elseif t == "boolean" then return tostring(value)
    elseif t == "number"  then return tostring(value)
    elseif t == "string"  then return '"' .. value:gsub('"', '\\"') .. '"'
    elseif t == "function" then return "<function>"
    elseif t == "userdata" then return "<userdata>"
    elseif t == "thread"   then return "<thread>"
    elseif t == "table" then
        if depth >= maxDepth then
            return "{...}"
        end

        -- Check if the table is array-like (sequential integer keys).
        local isArray = true
        local n = 0
        for k in pairs(value) do
            n = n + 1
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                isArray = false
                break
            end
        end
        -- Also verify no gaps
        if isArray and n ~= table.getn(value) then isArray = false end

        local childIndent = indent .. "  "
        local parts = {}

        if isArray and n > 0 then
            -- Print as a JS-style array: [v1, v2, v3]
            for i = 1, table.getn(value) do
                parts[table.getn(parts) + 1] = childIndent
                    .. _serialize(value[i], childIndent, depth + 1, maxDepth)
            end
            if table.getn(parts) == 0 then return "[]" end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
        else
            -- Print as a JS-style object: { key: value, ... }
            for k, v in pairs(value) do
                local keyStr = type(k) == "string"
                    and (string.find(k, "^[%a_][%w_]*$") and k or ('"' .. k .. '"'))
                    or ("[" .. tostring(k) .. "]")
                parts[table.getn(parts) + 1] = childIndent .. keyStr .. ": "
                    .. _serialize(v, childIndent, depth + 1, maxDepth)
            end
            if table.getn(parts) == 0 then return "{}" end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        end
    end
    return tostring(value)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- funk_debug.log(label, value)
-- Prints a labelled value to the chat frame in grey/white.
-- Similar to console.log(label, value) in JavaScript DevTools.
--
-- Examples:
--   funk_debug.log("player level", UnitLevel("player"))
--   funk_debug.log("items", {sword = 1, shield = 2})
-- -----------------------------------------------------------------------------
function funk_debug.log(label, value)
    if value == nil then
        _printLine(_colorize("grey", "[funk] ") .. _colorize("white", tostring(label)))
    else
        _printLine(
            _colorize("grey",  "[funk] ") ..
            _colorize("cyan",  tostring(label)) ..
            _colorize("grey",  " = ") ..
            _colorize("white", _serialize(value))
        )
    end
end

-- -----------------------------------------------------------------------------
-- funk_debug.dump(value, label)
-- Pretty-prints any Lua value with optional label.
-- Like console.dir() in JavaScript DevTools.
-- Tables are expanded with indentation (up to 5 levels deep).
-- -----------------------------------------------------------------------------
function funk_debug.dump(value, label)
    local header = label and (_colorize("orange", "[dump:" .. label .. "]") .. " ") or _colorize("orange", "[dump] ")
    _printLine(header .. _serialize(value))
end

-- -----------------------------------------------------------------------------
-- funk_debug.error(message, ...)
-- Prints an error message in red.
-- Similar to console.error() in JavaScript.
-- Also fires UIErrorsFrame if available (the small floating error display).
-- -----------------------------------------------------------------------------
function funk_debug.error(message, ...)
    local text = fmt(tostring(message), ...)
    _printLine(_colorize("red", "[ERROR] ") .. _colorize("white", text))
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(text, 1, 0.2, 0.2, 1)
    end
end

-- -----------------------------------------------------------------------------
-- funk_debug.warn(message, ...)
-- Prints a warning in orange/yellow.  Similar to console.warn().
-- -----------------------------------------------------------------------------
function funk_debug.warn(message, ...)
    local text = fmt(tostring(message), ...)
    _printLine(_colorize("orange", "[WARN] ") .. _colorize("yellow", text))
end

-- -----------------------------------------------------------------------------
-- funk_debug.info(message, ...)
-- Prints an informational message in cyan/green.  Similar to console.info().
-- -----------------------------------------------------------------------------
function funk_debug.info(message, ...)
    local text = fmt(tostring(message), ...)
    _printLine(_colorize("cyan", "[INFO] ") .. _colorize("green", text))
end

-- -----------------------------------------------------------------------------
-- funk_debug.whisper(target, message, ...)
-- Sends a whisper to `target` with the formatted message.
-- Useful for reporting computed values to yourself during play.
--
-- Example:
--   funk_debug.whisper("Arthas", "HP = %d / %d", UnitHealth("player"), UnitHealthMax("player"))
--
-- Note: SendChatMessage is the WoW API function for sending chat messages.
--   The third argument is the language (nil = default), fourth is the target.
-- -----------------------------------------------------------------------------
function funk_debug.whisper(target, message, ...)
    if SendChatMessage then
        local text = fmt(tostring(message), ...)
        SendChatMessage("[funk] " .. text, "WHISPER", nil, target)
    else
        -- Not in WoW — fall back to log
        funk_debug.log("whisper→" .. target, message)
    end
end

-- -----------------------------------------------------------------------------
-- funk_debug.say(message, ...)
-- Sends a /say message in the game world.
-- Useful for quick debugging where a whisper target is not available.
-- -----------------------------------------------------------------------------
function funk_debug.say(message, ...)
    if SendChatMessage then
        local text = fmt(tostring(message), ...)
        SendChatMessage("[funk] " .. text, "SAY")
    else
        funk_debug.log("say", message)
    end
end

-- -----------------------------------------------------------------------------
-- funk_debug.assert(condition, message, ...)
-- Like Lua's built-in assert but outputs to chat instead of raising an error.
-- Returns true/false so callers can branch.
--
-- JS equivalent: console.assert(condition, message)
-- -----------------------------------------------------------------------------
function funk_debug.assert(condition, message, ...)
    if condition then
        return true
    end
    local text = message and fmt(tostring(message), ...) or "assertion failed"
    funk_debug.error("ASSERT FAILED: " .. text)
    return false
end

-- -----------------------------------------------------------------------------
-- funk_debug.table(tbl, title)
-- Prints every key-value pair of a flat table, one per line.
-- Great for inspecting WoW item/spell/unit info tables.
--
-- JS equivalent: console.table(obj)
-- -----------------------------------------------------------------------------
function funk_debug.table(tbl, title)
    if title then _printLine(_colorize("yellow", "── " .. title .. " ──")) end
    if type(tbl) ~= "table" then
        funk_debug.warn("funk_debug.table: expected a table, got %s", type(tbl))
        return
    end
    for k, v in pairs(tbl) do
        _printLine(
            "  " .. _colorize("cyan",  tostring(k)) ..
            _colorize("grey",  " : ") ..
            _colorize("white", _serialize(v, "", 0, 2))
        )
    end
end

-- -----------------------------------------------------------------------------
-- funk_debug.time(label, fn)
-- Measures the wall-clock execution time of `fn` and logs it.
-- Similar to console.time() / console.timeEnd() in JavaScript.
--
-- Note: GetTime() is a WoW API function returning seconds since session start.
-- Falls back to os.clock() when not in WoW.
-- -----------------------------------------------------------------------------
function funk_debug.time(label, fn)
    local getTime = GetTime or os.clock
    local start = getTime()
    local result = fn()
    local elapsed = getTime() - start
    _printLine(
        _colorize("grey",   "[timer] ") ..
        _colorize("cyan",   label) ..
        _colorize("grey",   " took ") ..
        _colorize("yellow", fmt("%.4f", elapsed)) ..
        _colorize("grey",   "s")
    )
    return result
end

-- -----------------------------------------------------------------------------
-- funk_debug.serialize(value, maxDepth)
-- Exposes the internal serializer for external use.
-- Equivalent to JSON.stringify(value, null, 2).
-- -----------------------------------------------------------------------------
function funk_debug.serialize(value, maxDepth)
    return _serialize(value, "", 0, maxDepth)
end

-- Share via the WoW per-addon namespace table when available (no _G pollution).
if _ns ~= nil then
    _ns.funk_debug = funk_debug
end
return funk_debug
