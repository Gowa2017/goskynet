local skynet = require("skynet")
--- Used to gen different handlers
---@alias Handler fun(session:integer, source:integer,...)
---To get a field like  a.b.c.d.e.f from a table
---@param T table
---@param k string a.b.c.d.e.f
local function getfield(T, k)
  local v = T -- start with the table of globals
  for w in string.gmatch(k, "[%a_][%w_]*") do
    v = v[w]
    if not v then return v end
  end
  return v
end
---To set a field like  a.b.c.d.e.f on a table
---@param T table
---@param k string a.b.d.c
---@param v any
local function setfield(T, k, v)
  local base = T
  for w, d in string.gmatch(k, "([%a_][%w_]*)(%.?)") do
    if d == "." then -- not last item
      base[w] = base[w] or {}
      base = base[w]
    else
      base[w] = v
    end
  end
end

---@return Handler
return function(cmdTable, ret, session)
  ---@param id integer @session id
  ---@param source any @source service
  ---@param cmd string @command, like a.b.c
  local function handler(id, source, cmd, ...)
    local f = assert(getfield(cmdTable, cmd),
                     string.format("CMD %s not found", cmd))
    local r
    --- need session as first arg, like gate send to other service
    if session then
      r = f(id, ...)
    else
      r = f(...)
    end
    --- if I need to ret to the source service.
    if ret then
      skynet.retpack(r)
    else
      skynet.ignoreret()
    end
  end
  return handler
end
