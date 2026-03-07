-- =============================================================================
-- FunkDemo.lua — Interactive in-game test harness / demo window
-- =============================================================================
-- Provides a movable UI frame that lets you run live demos of every funk.lua
-- function from inside TurtleWoW without typing /run commands.
--
-- USAGE:
--   /funkdemo   — opens the demo window
--
-- Each button runs a demo function and prints its label + result to the chat
-- frame via funk_debug.log.  Results are paginated (12 per page).
-- =============================================================================

local ns = FunkDemo
local F = ns.funk
local D = ns.funk_debug

-- Slash command
SLASH_FUNKDEMO1 = "/funkdemo"
SlashCmdList["FUNKDEMO"] = function()
  if FunkDemoFrame then
    FunkDemoFrame:Show()
  end
end

-- Sample data for demos
local samples = {
  nums = {1,2,3,4,5,6},
  players = {
    {name="Arthas", lvl=60},
    {name="Jaina", lvl=55},
    {name="Thrall", lvl=60}
  },
  mixed = {1, nil, "two", false, 3},
  obj = {a=1, b=2, c=3},
  str = "  hello   world  ",
}

-- Demo functions
local demo_fns = {
  map = function()
    local input = samples.nums
    local res = F.map(input, function(x) return x * 2 end)
    D.log("map *2", {input=input, output=res})
  end,
  filter = function()
    local input = samples.nums
    local res = F.filter(input, function(x) return math.mod(x, 2) == 0 end)
    D.log("filter even", {input=input, output=res})
  end,
  reduce = function()
    local input = samples.nums
    local res = F.reduce(input, 0, function(acc, x) return acc + x end)
    D.log("reduce sum", res)
  end,
  sortBy = function()
    local input = samples.players
    local res = F.sortBy(input, "lvl")
    D.log("sortBy lvl", res)
  end,
  groupBy = function()
    local input = samples.nums
    local res = F.groupBy(input, function(x) return math.mod(x, 2) == 0 and "even" or "odd" end)
    D.log("groupBy parity", res)
  end,
  pluck = function()
    local input = samples.players
    local res = F.pluck(input, "name")
    D.log("pluck name", res)
  end,
  find = function()
    local input = samples.nums
    local res = F.find(input, function(x) return x > 4 end)
    D.log("find >4", res)
  end,
  every = function()
    local input = samples.nums
    local res = F.every(input, F.isNumber)
    D.log("every number?", res)
  end,
  some = function()
    local input = samples.mixed
    local res = F.some(input, F.isNil)
    D.log("some nil?", res)
  end,
  partition = function()
    local input = samples.nums
    local res = F.partition(input, function(x) return math.mod(x, 2) == 0 end)
    D.log("partition even", res)
  end,
  countBy = function()
    local input = samples.nums
    local res = F.countBy(input, function(x) return math.mod(x, 2) end)
    D.log("countBy %2", res)
  end,
  flatten = function()
    local input = {{1,2}, {3,4}, {5}}
    local res = F.flatten(input)
    D.log("flatten", {input=input, output=res})
  end,
  first = function()
    local input = samples.nums
    local res = F.first(input, 2)
    D.log("first 2", res)
  end,
  compact = function()
    local input = samples.mixed
    local res = F.compact(input)
    D.log("compact", {input=input, output=res})
  end,
  uniq = function()
    local input = {1,2,2,3,3,1}
    local res = F.uniq(input)
    D.log("uniq", {input=input, output=res})
  end,
  reverse = function()
    local input = samples.nums
    local res = F.reverse(input)
    D.log("reverse", {input=input, output=res})
  end,
  range = function()
    local res = F.range(1, 6)
    D.log("range(1,6)", res)
  end,
  zip = function()
    local res = F.zip(samples.nums, {"a","b","c","d","e","f"})
    D.log("zip nums+letters", res)
  end,
  chunk = function()
    local input = samples.nums
    local res = F.chunk(input, 3)
    D.log("chunk 3", {input=input, output=res})
  end,
  slice = function()
    local input = samples.nums
    local res = F.slice(input, 2, 3)
    D.log("slice(2,3)", {input=input, output=res})
  end,
  keys = function()
    local input = samples.obj
    local res = F.keys(input)
    D.log("keys", {input=input, output=res})
  end,
  values = function()
    local input = samples.obj
    local res = F.values(input)
    D.log("values", {input=input, output=res})
  end,
  clone = function()
    local input = samples.obj
    local res = F.clone(input)
    D.log("clone", {input=input, output=res})
  end,
  pick = function()
    local input = samples.obj
    local res = F.pick(input, {"a", "c"})
    D.log("pick a,c", {input=input, output=res})
  end,
  omit = function()
    local input = samples.obj
    local res = F.omit(input, {"b"})
    D.log("omit b", {input=input, output=res})
  end,
  merge = function()
    local dst = {x=99}
    F.merge(dst, samples.obj)
    D.log("merge {x=99} + obj", dst)
  end,
  size = function()
    local input = samples.obj
    local res = F.size(input)
    D.log("size obj", res)
  end,
  isEmpty = function()
    local res = F.isEmpty({})
    D.log("isEmpty {}?", res)
  end,
  compose = function()
    local add1 = function(x) return x + 1 end
    local mul2 = function(x) return x * 2 end
    local comp = F.compose(mul2, add1)
    local res = comp(5)
    D.log("compose mul2(add1(5))", res)
  end,
  pipe = function()
    local add1 = function(x) return x + 1 end
    local mul2 = function(x) return x * 2 end
    local pip = F.pipe(add1, mul2)
    local res = pip(5)
    D.log("pipe mul2(add1(5))", res)
  end,
  curry = function()
    local add = function(a,b) return a + b end
    local add5 = F.curry(add, 5)
    local res = add5(7)
    D.log("curry add(5,7)", res)
  end,
  memoize = function()
    local fib = F.memoize(function(n)
      if n < 2 then return n end
      return fib(n-1) + fib(n-2)
    end)
    local res1, res2 = fib(10), fib(10)
    D.log("memoize fib(10)", res1 .. " (cached same)")
  end,
  trim = function()
    local input = samples.str
    local res = F.trim(input)
    D.log("trim", {input=input, output=res})
  end,
  split = function()
    local res = F.split("one,two,three", ",")
    D.log("split ','", res)
  end,
  capitalize = function()
    local res = F.capitalize("hello world")
    D.log("capitalize", res)
  end,
  random = function()
    local res = F.random(1, 10)
    D.log("random(1,10)", res)
  end,
  isArray = function()
    local res = F.isArray(samples.nums)
    D.log("isArray nums?", res)
  end,
  chain = function()
    local input = samples.nums
    local res = F.chain(input)
      :filter(function(x) return math.mod(x, 2) == 0 end)
      :map(function(x) return x * 10 end)
      :sort()
      :value()
    D.log("chain even*10+sort", {input=input, output=res})
  end,
  debug = function()
    D.log("debug demo", samples.obj)
  end,
  runtests = function()
    ns.funk_test.run()
    D.log("All 168+ tests run!", "Scroll up in chat for full results")
  end,
}

-- Function list (ordered for pagination)
local func_list = {
  "map", "filter", "reduce", "sortBy", "groupBy",
  "pluck", "find", "every", "some", "partition",
  "countBy", "flatten", "first", "compact", "uniq",
  "reverse", "range", "zip", "chunk", "slice",
  "keys", "values", "clone", "pick", "omit",
  "merge", "size", "isEmpty", "compose", "pipe",
  "curry", "memoize", "trim", "split", "capitalize",
  "random", "isArray", "chain", "debug", "runtests"
}

local frame, page, slots, prev_btn, next_btn, pageText
local funcs_per_page = 12
local total_pages = math.ceil(table.getn(func_list) / funcs_per_page)

local function run_demo(name)
  local fn = demo_fns[name]
  if fn then
    fn()
  else
    D.log(name, "No demo yet (see README)")
  end
end

local function update_page()
  local start_idx = (page - 1) * funcs_per_page + 1
  for i = 1, funcs_per_page do
    local fname = func_list[start_idx + i - 1]
    local btn = slots[i]
    if fname then
      btn:Show()
      btn:SetText(fname)
      btn:SetScript("OnClick", function() run_demo(fname) end)
    else
      btn:Hide()
    end
  end
  pageText:SetText(format("Page %d / %d", page, total_pages))
  if page > 1 then
    prev_btn:Enable()
  else
    prev_btn:Disable()
  end
  if start_idx + funcs_per_page - 1 < table.getn(func_list) then
    next_btn:Enable()
  else
    next_btn:Disable()
  end
end

local function create_ui()
  if FunkDemoFrame then return end

  frame = CreateFrame("Frame", "FunkDemoFrame", UIParent)
  frame:SetWidth(480)
  frame:SetHeight(520)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetScript("OnMouseUp", frame.StopMovingOrSizing)
  frame:SetScript("OnShow", update_page)
  frame:Hide()  -- Start hidden

  frame:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = { left = 11, right = 12, top = 12, bottom = 11 },
  })

  frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.TitleText:SetPoint("TOP", frame, "TOP", 0, -15)
  frame.TitleText:SetText("Funk Test Harness")  -- Title

  frame.Close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  frame.Close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
  frame.Close:SetScript("OnClick", function() frame:Hide() end)

  -- Page text
  pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
  pageText:SetText("Page 1 / 4")

  -- Button slots (2 cols x 6 rows)
  slots = {}
  for i = 1, funcs_per_page do
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetWidth(220)
    btn:SetHeight(28)
    btn:SetFrameLevel(frame:GetFrameLevel() + 10)
    local row = math.ceil(i / 2)
    local col_offset = ((math.mod(i, 2) == 0) and 255 or 15)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", col_offset, -65 - (row - 1) * 32)
    if btn.SetNormalFontObject then
      btn:SetNormalFontObject("GameFontNormalSmall")
    end
    btn:SetText("Button " .. i)
    slots[i] = btn
  end

  -- Prev/Next
  prev_btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  prev_btn:SetWidth(80)
  prev_btn:SetHeight(25)
  prev_btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 15)
  prev_btn:SetText("Previous")
  prev_btn:SetScript("OnClick", function()
    page = page - 1
    update_page()
  end)
  prev_btn:Disable()

  next_btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  next_btn:SetWidth(80)
  next_btn:SetHeight(25)
  next_btn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 15)
  next_btn:SetText("Next")
  next_btn:SetScript("OnClick", function()
    page = page + 1
    update_page()
  end)

  page = 1
end

-- Init on load
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
  if arg1 == "FunkDemo" then
    create_ui()
    this:UnregisterEvent("ADDON_LOADED")
  end
end)
