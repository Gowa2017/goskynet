local traceback   = debug.traceback
local skynet      = require("skynet")
require "skynet.manager"
local timer       = require("go.timer")
local cmdloader   = require("go.cmdloader")
local handler     = require("go.handler")
local LOG         = require("go.logger")
require("go.reload")

local MESSAGES    = require("conf.message")

---@class ServiceMessageConfig
---@field cmds string|string[]  @a module or module list
---@field ret boolean @need call skynet.ret? default true
---@field session boolean @need call command function's with sessionid? default false

---@type table<string, ServiceMessageConfig>
local msgConf    
local running     = false
local service     = {}
local serviceName

function service.name(name) serviceName = name end
---Start the service, which call the start_func in skynet.start
---@param func? fun() @start_func
function service.start(func)
  if msgConf then
    for msg, conf in pairs(msgConf) do
      service.setMessageModules(msg, conf.cmds, conf.ret, conf.session)
    end
  end
  skynet.start(function()
    running = true
    if func then func() end
    if serviceName then skynet.register(serviceName) end
  end)
end

---Register the service's message config.
---@param conf table
function service.register(conf) msgConf = conf end

---Set this service can send a message of type **msgType**.
---@param msgType string @message type
function service.enableMessage(msgType)
  --- lua is enabled by skynet default
  if msgType ~= "lua" then
    local proto = MESSAGES[msgType]
    proto.pack = proto.pack or skynet.pack
    proto.unpack = proto.unpack or skynet.unpack
    skynet.register_protocol(proto)
  end
end

---User command modules to generate a handler, then set it as the message's handler.
---@param msgType string @message type
---@param cmdConf table  @modules to handle the message
---@param ret? boolean @default is true, whether to respond to source
---@param session? boolean @default is false, whether to call command function with sessionid
function service.setMessageModules(msgType, cmdConf, ret, session)
  service.enableMessage(msgType)
  ret = ret == nil and true or ret -- default is true
  session = session ~= nil and session or false -- default is true
  skynet.dispatch(msgType, handler(cmdloader(msgType, cmdConf), ret, session))
end

---User command tables to generate a handler, then set it as the message's handler.
---@param msgType string @message type
---@param cmds table  @table of command functions to handle the message
---@param ret? boolean @default is true, whether to respond to source
---@param session? boolean @default is false, whether to call command function with sessionid
function service.setMessageCmds(msgType, cmds, ret, session)
  ret = ret == nil and true or ret -- default is true
  session = session ~= nil and session or false -- default is true
  skynet.dispatch(msgType, handler(cmds, ret, session))
end

function service.enableReload()
  service.enableMessage("reload")
  skynet.dispatch("reload", function(_, _, module)
    local ok, err = pcall(reload, module)
    if not ok then
      LOG.error("RELOAD module %s failed: %s", module, err)
      traceback(err)
    end
    skynet.retpack(ok, err)
  end)
end

---timeout once
---@param delay integer @0.01 second unit
---@param callback fun()    @callback
function service.timerOnce(delay, callback)
  assert(running, "service is not running")
  if not timer.isStart() then timer.create() end
  timer.once(delay, callback)

end
---timeout period
---@param interval integer  @period 0.01 second unit
---@param callback fun()        @callback
function service.timerPeriod(interval, callback)
  assert(running, "service it not running")
  if not timer.isStart() then timer.create() end
  timer.period(interval, callback)
end
return service
