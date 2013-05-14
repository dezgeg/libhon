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

local function indent(s)
    return s:gsub("\n", "\n    ")
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
        local value = _stringify(visitedTables, tab[k])
        local pair = '    ' .. prettyKey .. ' = ' .. indent(value)
        table.insert(result, pair)
    end
end

-- need this since can't compare two userdatas directly
local function comparator(a, b)
    local typA, typB = type(a), type(b)

    if typA == 'userdata' then
        if typB ~= 'userdata' then
            return true
        else
            return tostring(a) < tostring(b)
        end
    end

    return a < b
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
    table.sort(arrayKeys, comparator)
    table.sort(hashKeys, comparator)

    local parts = {}
    -- Too sparse array or non-positive indices -> stringify as key-value pairs
    if #arrayKeys == 0 or arrayKeys[1] <= 0 or arrayKeys[#arrayKeys] > 2 * #arrayKeys then
        _stringifyKeyValuePairs(visitedTables, parts, tab, arrayKeys)
    else
        for i = 1, arrayKeys[#arrayKeys] do
            table.insert(parts, '    ' ..
                indent(_stringify(visitedTables, tab[i])))
        end
    end

    -- Hash part
    _stringifyKeyValuePairs(visitedTables, parts, tab, hashKeys)
    -- Metatable
    local meta = getmetatable(tab)
    if meta then
        table.insert(parts, '    getmetatable() = ' ..
            indent(_stringify(visitedTables, meta)))
    end

    if #parts == 0 then
        return "{ }"
    end
    local prefix, suffix = "{\n", "\n}"

    return prefix .. table.concat(parts, ",\n") .. suffix
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
        local meta = getmetatable(x)
        local ptr
        if meta and meta.__tostring then
            -- Fuck you, Lua
            local old = meta.__tostring
            meta.__tostring = nil
            ptr = tostring(x)
            meta.__tostring = old
        else
            ptr = tostring(x)
        end

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
