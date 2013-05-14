require 'utils'
p(42)
p(nil)
p(true)
p('foo')
p('\0001')
p('\0\1tro\t"\tlol\r\t\\')
p({})
p({ 1, 2, 4, 8, 16 })
p({ 0, 1, nil, 2, nil, nil, nil, 3, nil, nil, nil, nil, nil, nil, nil, 4 })
p({ 42, foo = 666 })
p({ foo = 'bar', _bar = 42 })
p({ ['return'] = 'bad' })
p({ ["lol wtf"] = 'bar' })
p(print)

local loop = {}
loop.loop = loop
p(loop)

p({ 1, { quux = 42 }, 3, 4, baz = 42, xyz = "zy" })
p({foo = { bar = { 1, { quux = 42 }, 3, 4, baz = 42, xyz = "zy" } } })

local meta = { bar = 42 }
local t = { baz = 11 }
setmetatable(t, meta)
p(t)
