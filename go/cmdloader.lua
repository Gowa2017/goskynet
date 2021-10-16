---Used to load a services'a all cmds
---May the cmds will be grouped or not
---A service's cmd must in the service's cmds dir
---Also, we can use lfs libary to get a dir's files, but now, I don't want to
---use it.
local CMDDIR = "cmds"
local function loadmodule(...)
  local path = table.concat({ CMDDIR, ... }, ".")
  return require(path)
end

return function(msg, t)
  if not t then return {} end
  if type(t) == "string" then return loadmodule(msg, t) end
  local m = {}
  for _, module in pairs(t) do m[module] = loadmodule(msg, module) end
  return m
end
