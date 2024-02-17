local lfs = require("lfs")

local arguments = {...}

local version, out
for i = 1, #arguments do
  if arguments[i] == "--version" or arguments[i] == "-v" then
    version = arguments[i + 1]
    i = i + 1
  elseif arguments[i] == "--out" or arguments[i] == "-o" then
    out = arguments[i + 1]
    i = i + 1
  end
end
if not version then
  error("no version specified")
end
if not out then
  out = "out/kernel-" .. version .. ".lua"
end

local function readModules(directory, moduleName, moduleTable)
  for file in lfs.dir(directory) do
    local path = directory .. "/" .. file
    if file == "." or file == ".." then
      -- do nothing
    elseif lfs.attributes(path).mode == "directory" then
      readModules(path, moduleName .. file .. ".", moduleTable)
    elseif file:sub(-4) == ".lua" then
      local name = file:sub(1, -5)
      local file, err = io.open(path, "r")
        if not file then
          error("error reading file " .. path .. ": " .. err)
        end
      local code = file:read("*a")
      file:close()
      moduleTable[moduleName .. name] = code
    end
  end
end

local modules = {}
readModules("src", "", modules)

local buildModules = ""
for k, v in pairs(modules) do
  local numEscapes = 0;
  local escapes = string.rep("=", numEscapes)
  while v:find("%[" .. escapes .. "%[") or v:find("%]" .. escapes .. "%]") do
    numEscapes = numEscapes + 1
    escapes = string.rep("=", numEscapes)
  end
  buildModules = buildModules .. "[\"" .. k .. "\"]" .. " = [" .. escapes .. "[" .. v .. "]" .. escapes .. "],\n"
end
if #buildModules > 0 then
  buildModules = buildModules:sub(1, -3)
end

local buildTemplateFile, err = io.open("buildtemplate.lua", "r")
if not buildTemplateFile then
  error("error reading file buildtemplate.lua: " .. err)
end
local buildTemplate = buildTemplateFile:read("*a")
buildTemplateFile:close()

local buildTemplateVariables = {}
buildTemplateVariables["build-info"] = "version = \"" .. version .. "\""
buildTemplateVariables["build-modules"] = buildModules

local nextPos = 1
while true do
  local firstPattern, firstPatternPos, firstPatternEnd = nil, nil, nil
  for k, v in pairs(buildTemplateVariables) do
    local pattern = "--% " .. k
    local start, finish = buildTemplate:find(pattern, nextPos, true)
    if start and (not firstPattern or start < firstPatternPos) then
      firstPattern = pattern
      firstPatternPos = start
      firstPatternEnd = finish
    end
  end
  if not firstPattern then
    break
  end

  local v = buildTemplateVariables[firstPattern:sub(5)]
  buildTemplate = buildTemplate:sub(1, firstPatternPos - 1) .. v .. buildTemplate:sub(firstPatternEnd + 1)
  nextPos = firstPatternPos + #v
end

local outFile, err = io.open(out, "w")
if not outFile then
  error("error writing file " .. out .. ": " .. err)
end
outFile:write(buildTemplate)
outFile:close()

print("Wrote build to " .. out)