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
        -- TODO: use these to decide if the array part is sparse or not
        local minArrayKey, maxArrayKey = math.huge, -math.huge
        local numArrayKeys, numHashKeys = 0, 0
        local parts = {}
        for k,v in pairs(x) do
            if type(k) == 'number' then
                minArrayKey = math.min(k, minArrayKey)
                maxArrayKey = math.max(k, maxArrayKey)
                numArrayKeys = numArrayKeys + 1
            else
                numHashKeys = numHashKeys + 1
            end
        end
        -- Hash part
        for k, v in pairs(x) do
            local prettyKey
            if k:match('^[%a_][%w_]*$') then
                prettyKey = k -- TODO: this allows lua keywords
            else
                prettyKey = '[' .. str(k) .. ']'
            end
            table.insert(parts, prettyKey .. ' = ' .. str(v))
        end
        return '{ ' .. table.concat(parts, ', ') .. ' }'
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
p({ foo = 'bar', _bar = 42 })
p({ ['return'] = 'bad' })
p({ ["lol wtf"] = 'bar' })
p(print)
