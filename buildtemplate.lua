local initfs, command = ...

local modules = {
--% build-modules
}

local loadedModules = {}
loadedModules["buildinfo"] = {
--% build-info
}

local moduleEnv = {}
for k, v in pairs(_G) do
  moduleEnv[k] = v
end

local function requireUnshared(module)
  if modules[module] then
    local codeString = modules[module]
    local code, err = load(codeString, "=" .. module, "t", moduleEnv)
    if code then
      local result = code()
      return result
    end
    error("error loading module " .. module .. ": " .. err)
  end
  error("module not found: " .. module)
end
local function require(module)
  if loadedModules[module] then
    return loadedModules[module]
  end
  local result = requireUnshared(module)
  loadedModules[module] = result
  return result
end
moduleEnv["requireUnshared"] = requireUnshared
moduleEnv["require"] = require

local init = require("init")
init(initfs, command)