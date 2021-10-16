local skynet    = require("skynet")
local Ltimer    = require "ltimer"
local M         = {}
---@type timer
local T        

---@class Timer
---@field id integer timerid
---@field cb function callback
---@field loop boolean isLoop
---@field ti number delay or interval
local expired   = {}
local timers    = {} -- handle -> {function,period,interval}

local handleNum = 0
local function genHandle()
  handleNum = handleNum + 1
  return handleNum
end

local function update()
  T:update(skynet.now(), expired)
  if #expired < 1 then return end
  for i = #expired, 1, -1 do
    local t = timers[expired[i]]
    pcall(t.cb)
    if t.loop then
      T:add(t.id, t.ti)
    else
      timers[t.id] = nil
      timerCount = timerCount - 1
    end
    expired[i] = nil
  end
end

function M.create()
  if T then return end
  timerCount = 0
  T = Ltimer.create(skynet.now())
  local function cb()
    update()
    skynet.timeout(1, cb)
  end
  cb()
end

local function addTimer(ti, cb, loop)
  local t = {
    id   = genHandle(),
    ti   = ti,
    cb   = cb,
    loop = loop
  }
  timers[#timers + 1] = t
  T:add(t.id, t.ti)
end

---添加间隔执行的定时器
---@param interval integer 单位是1/100秒
---@param func fun()
function M.period(interval, func) addTimer(interval, func, true) end

---@param delay integer 单位是1/100秒
---@param func fun()
function M.once(delay, func) addTimer(delay, func, false) end

function M.count() return timerCount end

function M.isStart() return T end
return M
