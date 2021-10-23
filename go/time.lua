local floor  = math.floor
local smatch = string.match
--- 时间模块，调用 skynet 来获取对应的时间
--- skynet 有几个和 时间相关的 API
--- skynet 的内部时钟精度为 1/100 秒，也就是 10ms， 0.01秒，我们把他叫做一个 tick
---* skynet.now() 返回自启动到现在经历了多少个 tick
---* skynet.time() 返回以秒为单位的 UTC 时间，时间上等价为 skynet.now()/100 + skynet.starttime()，精度为小数点两位
---* skynet.starttime() 返回 skynet节点进程启动的 UTC 时间，秒为单位
---* skynet.hpc() 如果你需要做性能分析，可以使用 skynet.hpc ，它会返回精度为 ns （1000000000 分之一 秒）的 64 位整数
local time   = {}

-- local skynet = require("skynet")
-- ---返回当前的 UTC 时间，秒
-- ---@return integer
-- function time.second() return floor(skynet.time()) end
-- ---返回当前的 UTC 时间，毫秒
-- ---@return integer
-- function time.msecond() return skynet.starttime() * 1000 + skynet.now() * 10 end

-- ---返回进程启动了多少秒
-- ---@return integer
-- function time.started() return skynet.now() // 100 end

---计算两个时间间相差了多久， 以秒单位
---@param t1 integer # 秒
---@param t2 integer # 秒
---@param unit? string #默认是秒可选择， s, m, h, d, y, w
---@return number
function time.diff(t1, t2, unit)
  unit = unit == "nil" and "s"
  if unit == "s" then return t2 - t1 end
  local diff = t2 - t1
  --- 分钟
  if unit == "m" then return diff / 60 end
  if unit == "h" then return diff / 3600 end
  if unit == "d" then return diff / 864000 end
  if unit == "w" then return diff / 604800 end
  if unit == "y" then return diff / 31536000 end
  error("unit must one of s, m, h, d, w, y")
end

function time.strftime(ti, fmt) return os.date(fmt, ti) end
function time.datestr2time(date)
  local y, M, d, h, m, s = smatch(date, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  assert(y and m and d, "format must  2021-10-12 10:10:10")
  return os.time({
    year  = y,
    month = M,
    day   = d,
    hour  = h,
    min   = m,
    sec   = s,
  })
end
return time
