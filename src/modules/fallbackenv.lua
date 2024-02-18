return function(loadedModules)

local envManager = {}
function envManager.getEnv()
  local env = {}
  for k, v in pairs(_G) do
    env[k] = v
  end
  env.require = function(module)
    if loadedModules[module] then
      return loadedModules[module]
    end
    error("module not found: " .. module)
  end

  return env
end

return envManager

end