local print = print

-- Lua's format has %q, but it doesn't escape nonprintable chars for example
local escapePattern = "[%c\"\\]"
local escapeFrom = "\"\\\a\b\e\f\n\t\r\v"
local escapeTo   = "\"\\abefntrv"
local escapes = {}
for i = 1, #escapeTo do
    escapes[escapeFrom:sub(i, i)] = escapeTo:sub(i, i)
end

local function escapeHelper(s)
    local e = escapes[s]
    if e then return '\\' .. e
    else return ('\\%03o'):format(string.byte(s))
    end
end

local _stringify
local function _stringifyKeyValuePairs(visitedTables, result, tab, keys)
    for _, k in ipairs(keys) do
        local prettyKey
        if tostring(k):match('^[%a_][%w_]*$') then
            prettyKey = k -- TODO: this allows lua keywords
        else
            prettyKey = '[' .. str(k) .. ']'
        end
        table.insert(result, prettyKey .. ' = ' .. _stringify(visitedTables, tab[k]))
    end
end

local function _stringifyTable(visitedTables, tab)
    local arrayKeys, hashKeys = {}, {}
    for k,v in pairs(tab) do
        if type(k) == 'number' then
            table.insert(arrayKeys, k)
        else
            table.insert(hashKeys, k)
        end
    end
    table.sort(arrayKeys)
    table.sort(hashKeys)

    local parts = {}
    -- Too sparse array or non-positive indices -> stringify as key-value pairs
    if #arrayKeys == 0 or arrayKeys[1] <= 0 or arrayKeys[#arrayKeys] > 2 * #arrayKeys then
        _stringifyKeyValuePairs(visitedTables, parts, tab, arrayKeys)
    else
        for i = 1, arrayKeys[#arrayKeys] do
            table.insert(parts, _stringify(visitedTables, tab[i]))
        end
    end

    -- Hash part
    _stringifyKeyValuePairs(visitedTables, parts, tab, hashKeys)

    -- Split into lines
    local lineParts = {}
    local lineLength = 0
    local lines = {}

    for i, v in ipairs(parts) do
        table.insert(lineParts, v)
        lineLength = lineLength + #v
        if lineLength >= 120 then
            table.insert(lines, table.concat(lineParts, ', '))
            lineLength = 0
            lineParts = { }
        end
    end

    if #lineParts > 0 then
        table.insert(lines, table.concat(lineParts, ', '))
    end
    local prefix, suffix = '{ ', ' }'
    if #lines > 1 then
        prefix = "{\n  "
        suffix = "\n}"
    end

    return prefix .. table.concat(lines, "\n  ") .. suffix
end

function _stringify(visitedTables, x)
    local typ = type(x)
    if typ == 'string' then
        local escaped = x:gsub(escapePattern, escapeHelper)
        return '"' .. escaped .. '"'
    elseif typ == 'function' then
        -- TODO: it might be possible to actually get the function name
        -- (even though debug.getinfo won't provide it)
        return '<' .. tostring(x) .. '>'
    elseif typ == 'table' then
        -- Prevent infinite recursion
        local ptr = tostring(x)
        if visitedTables[ptr] then
            return '<' .. ptr .. '>'
        end
        visitedTables[ptr] = true
        return _stringifyTable(visitedTables, x)
    else
        return tostring(x)
    end
end

function str(x)
    return _stringify({}, x)
end

function p(x)
    if debug == nil then
        print(str(x) .. "\n")
    else
        local debuginfo = debug.getinfo(2, "lS")
        local prefix = debuginfo.short_src .. ":" .. debuginfo.currentline  .. ": "
        print(prefix .. str(x))
    end
end

-- Drawing stuff

DEFAULT_COLOR = "red"
function drawLine(startPoint, endPoint, color)
    HoN.DrawDebugLine(startPoint, endPoint, false, color or DEFAULT_COLOR)
end

function drawCross(pos, color, size)
  size = size or 50
  local tl = Vector3.Create(0.5, -0.5) * size
  local bl = Vector3.Create(0.5, 0.5) * size

  drawLine(pos - tl, pos + tl, color)
  drawLine(pos - bl, pos + bl, color)
end
