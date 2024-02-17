local function loadOpenComputersInitfs()
  local guessedAddress = computer.getBootAddress()
  local guessedFile = "boot/initfs.lua"
  local initfsPath = guessedAddress .. " " .. guessedFile
  local errorAppend = " (initfsguesser guessed OpenComputers " .. initfsPath .. ")"

  local initfsHandle, err = component.invoke(guessedAddress, "open", guessedFile)
  if not initfsHandle then
    error("error opening initfs: " .. err .. errorAppend)
  end
  local initfsBuffer = ""
  repeat
    local data, err = component.invoke(guessedAddress, "read", initfsHandle, math.maxinteger or math.huge)
    if not data and err then
      error("error reading initfs: " .. err .. errorAppend)
    end
    initfsBuffer = initfsBuffer .. (data or "")
  until not data

  local initfsFunc, err = load(initfsBuffer, "=" .. guessedFile, "t", _G)
  if not initfsFunc then
    error("error loading initfs: " .. err  .. errorAppend)
  end

  return initfsFunc(initfsPath)
end

local function loadComputerCraftInitfs()
  local guessedFile = "boot/initfs.lua"
  local errorAppend = " (initfsguesser guessed ComputerCraft " .. guessedFile .. ")"

  local initfsFunc, err = loadfile(guessedFile)
  if not initfsFunc then
    error("error loading initfs: " .. err  .. errorAppend)
  end

  return initfsFunc()
end

return {
  guessInitfs = function()
    if component then
      return loadOpenComputersInitfs()
    elseif term then
      return loadComputerCraftInitfs()
    else
      error("Could not guess how to load the initfs. Please pass it as the first argument to the kernel.")
    end
  end
}