local sfmt    = string.format
local sgsub   = string.gsub
local LOG     = require("go.logger")
local modules = {}

local function clone(t)
  local res = {}
  for k, v in pairs(t) do
    res[k] = v
  end
  return res
end

function loadfileEX(path, mode, env)
  mode = mode or "bt"
  env = env or _ENV
  local file, err = io.open(path, "rb")
  assert(file, sfmt("open file %s failed: %s", path, err))
  local source    = file:read("*a")
  file:close()
  return load(source, path, mode, env)
end

---Use import we must set the module from the root dir.
---It will not use the lua's package.path to serach modules.
---@param module string like service.auth.test or auth.test
---@return table
function import(module)
  if modules[module] then
    return modules[module]
  end
  local path   = sgsub(module, "%.", "/") .. ".lua"
  local env    = setmetatable({}, { __index = _G })
  --- do this, the env only modified by the global vars.
  local f, err = loadfileEX(path, "bt", env)
  assert(f, sfmt("import file %s err:%s", module, err))
  f()
  modules[module] = env
  return env
end

local function merge(dst, src, cache)
  if cache[dst] then
    return
  end
  cache[dst] = true
  for k, v in pairs(src) do
    local oldValue = dst[k]
    -- type changed
    if type(oldValue) ~= type(v) then
      LOG.debug("\t\t[%s][typechange]: %s <- %s", k, type(oldValue), type(v))
      dst[k] = v
    else
      local tt = type(v)
      -- is not a table
      if tt ~= "table" then
        if tt == "function" then
          LOG.debug("\t\t[%s][%s]: %p <- %p", k, tt, oldValue, v)
        else
          LOG.debug("\t\t[%s][%s]: %q <- %q", k, tt, oldValue, v)
        end
        dst[k] = v
      else
        LOG.debug("\t\t[%s][table]: %p <- %p", k, oldValue, v)
        merge(oldValue, v, cache)
      end
    end
  end
  -- clear element not in the new table
  for k, _ in pairs(dst) do
    if not rawget(src, k) then
      dst[k] = nil
    end
  end
end
---Reload a module from lua files.
---Local vars will not be update.
---Functions's upvalue will not be update.
---Other module referent modules' element(except table) directly should more carefully.
---Table address will not change.
---@param module any
function reload(module)
  assert(modules[module], sfmt("%s is not a reload module", module))
  local current = modules[module]
  local path    = sgsub(module, "%.", "/") .. ".lua"
  --- now the back table referent all the objects in current module.
  local back    = clone(current)
  --- now current module will by modified, so it is a new module, but the module address it not changed.
  loadfileEX(path, "bt", current)()
  LOG.debug("--------------------------------")
  for k, v in pairs(current) do
    local oldvalue = back[k]
    -- update module's tables, keep table address.
    if type(oldvalue) == type(v) and type(v) == "table" then
      -- use the new value to update the oldtable
      LOG.debug("RELOAD:[%s][table] %p <- %p", k, oldvalue, v)
      merge(oldvalue, v, {})
      -- then set as new module element.
      current[k] = oldvalue
    else
      local tt = type(v)
      if tt == "function" then
        LOG.debug("RELOAD:[%s][%s] %p <- %p", k, tt, oldvalue, v)
      else
        LOG.debug("RELOAD:[%s][%s] %q <- %q", k, tt, oldvalue, v)
      end
    end
  end
end
