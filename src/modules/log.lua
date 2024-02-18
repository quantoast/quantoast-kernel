local TRACE_LEVEL = 1
local INFO_LEVEL = 2
local WARN_LEVEL = 3
local ERROR_LEVEL = 4

local logs, log, listeners = {}, {}, {}
local backend

local function addToLog(level, message, timestamp)
  local logEntry = { level, message, timestamp }
  table.insert(logs, logEntry)
  for i = 1, #listeners do
    listeners[i](logEntry)
  end
end

function log.trace(message)
  if backend then
    backend.trace(message)
  end
  addToLog(TRACE_LEVEL, message, os.clock())
end

function log.info(message)
  if backend then
    backend.info(message)
  end
  addToLog(INFO_LEVEL, message, os.clock())
end

function log.warn(message)
  if backend then
    backend.warn(message)
  end
  addToLog(WARN_LEVEL, message, os.clock())
end

function log.error(message)
  if backend then
    backend.error(message)
  end
  addToLog(ERROR_LEVEL, message, os.clock())
end

function log.setBackend(newBackend)
  backend = newBackend
end

function log.addListener(listener)
  table.insert(listeners, listener)
end

function log.removeListener(listener)
  for i = 1, #listeners do
    if listeners[i] == listener then
      table.remove(listeners, i)
      return
    end
  end
end

function log.getLogs()
  return logs
end

return log