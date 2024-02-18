return function(initfs, rootfs, command)

local buildinfo = require("buildinfo")

local loadedModules = {}
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

  xpcall(function()
    if type(rootfs) == "table" then
      earlyLogger.info("rootfs instance was passed through kernel arguments")
    else
      local rootfsId = rootfs or initfs.guessedRootFs
      rootfs = loadRamFsModule("init.rootfs").load(rootfsId)
    end

    earlyLogger.info("Creating VFS tree")
    local vfs = require("modules.vfs")
    loadedModules["system.vfs"] = vfs

    earlyLogger.info("Mounting rootfs")
    vfs.mount("/", rootfs)
  end, function(err)
    earlyLogger.error("error during kernel init: " .. err)
    if debug then earlyLogger.error(debug.traceback()) end
    while true do
      coroutine.yield()
    end
  end)
end

while true do
  coroutine.yield()
end

end