return function(initfs, rootfs, command)

local buildinfo = require("buildinfo")

do
  local heldLogs = {}
  local HELD_LOGS_WARN = 3

  if not initfs then
    initfs = requireUnshared("init.initfsguesser").guessInitfs()
    table.insert(heldLogs, {
      level = HELD_LOGS_WARN,
      message = "No initfs specified, guessing initfs: " .. initfs.getName()
    })
  end

  local function loadRamFsModule(name)
    local module, err = initfs.read(name:gsub("%.", "/") .. ".lua")
    if not module then
      error("error reading module " .. name .. ": " .. err)
    end
    local func, err = load(module, "=" .. name, "t", _G)
    if not func then
      error("error loading module " .. name .. ": " .. err)
    end
    return func()
  end

  local earlyLogger = loadRamFsModule("init.earlylogger")
  earlyLogger.info("Welcome to Quantoast! Kernel version " .. buildinfo.version)
  earlyLogger.trace("initfs: " .. initfs.getName())
  if #heldLogs > 0 then
    earlyLogger.info("The next " .. #heldLogs .. " message(s) were held before logging init:")
  end
  for i = 1, #heldLogs do
    if heldLogs[i].level == HELD_LOGS_WARN then
      earlyLogger.warn(heldLogs[i].message)
    end
  end
end

while true do
  coroutine.yield()
end

end