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
    else return ('\\%o'):format(string.byte(s))
    end
end

local function _stringifyKeyValuePairs(result, tab, keys)
    for _, k in ipairs(keys) do
        local prettyKey
        if tostring(k):match('^[%a_][%w_]*$') then
            prettyKey = k -- TODO: this allows lua keywords
        else
            prettyKey = '[' .. str(k) .. ']'
        end
        table.insert(result, prettyKey .. ' = ' .. str(tab[k]))
    end
end

local function _stringifyTable(tab)
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
        _stringifyKeyValuePairs(parts, tab, arrayKeys)
    else
        for i = 1, arrayKeys[#arrayKeys] do
            table.insert(parts, str(tab[i]))
        end
    end

    -- Hash part
    _stringifyKeyValuePairs(parts, tab, hashKeys)
    return '{ ' .. table.concat(parts, ', ') .. ' }'
end

function str(x)
    local typ = type(x)
    if typ == 'string' then
        local escaped = x:gsub(escapePattern, escapeHelper)
        return '"' .. escaped .. '"'
    elseif typ == 'function' then
        -- TODO: it might be possible to actually get the function name
        -- (even though debug.getinfo won't provide it)
        return '<' .. tostring(x) .. '>'
    elseif typ == 'table' then
        return _stringifyTable(x)
    else
        return tostring(x)
    end
end

function p(x)
    print(str(x))
end

p(42)
p(nil)
p(true)
p('foo')
p('\0\1tro\t"\tlol\r\t\\')
p({})
p({ 1, 2, 4, 8, 16 })
p({ 0, 1, nil, 2, nil, nil, nil, 3, nil, nil, nil, nil, nil, nil, nil, 4 })
p({ 42, foo = 666 })
p({ foo = 'bar', _bar = 42 })
p({ ['return'] = 'bad' })
p({ ["lol wtf"] = 'bar' })
p(print)
