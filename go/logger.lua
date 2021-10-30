local skynet = require("skynet")
local sfmt   = string.format
local M      = {}
local level  = tonumber(skynet.getenv("logLevel")) or 0
local levels = {
  ALL      = 0,
  DEBUG    = 1,
  INFO     = 2,
  WARING   = 3,
  ERROR    = 4,
  CRITICAL = 5,
}

local function logFile(sSubType, sMsg, ...)
  if level > levels[sSubType] then return end
  local s = sfmt("%-6s [%s]: %s", sSubType, SERVICE_DESC or SERVICE_NAME,
                 sfmt(sMsg, ...))
  skynet.error(s)
end

function M.log(sMsg, ...)
  local s = sfmt("%-6s [%s]: %s", "NOTSET", SERVICE_DESC or SERVICE_NAME,
                 sfmt(sMsg, ...))
  skynet.error(s)
end

function M.error(sMsg, ...)
  logFile("ERROR", sMsg, ...)
end

function M.info(sMsg, ...)
  logFile("INFO", sMsg, ...)
end

function M.warning(sMsg, ...)
  logFile("WARNING", sMsg, ...)
end

function M.debug(sMsg, ...)
  logFile("DEBUG", sMsg, ...)
end

return M
