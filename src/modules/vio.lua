local filePrototype = {}
function filePrototype:read(amount)
  if self._mode ~= "r" then
    error("file not open for reading")
  end

  if type(amount) == "number" then
    if amount + self._position - 1 >= #self._file.content then
      return nil, "end of file"
    end
    local result = self._file.content:sub(self._position, self._position + amount - 1)
    self._position = self._position + amount
    return result
  elseif amount == "a" then
    local result = self._file.content:sub(self._position)
    self._position = #self._file.content + 1
    return result
  elseif amount == "l" then
    if self._position >= #self._file.content then
      return nil, "end of file"
    end
    local npos = self._file.content:find("\n", self._position)
    local result = self._file.content:sub(self._position, npos - 1)
    self._position = npos + 1
    return result
  end
end

function filePrototype:close()
  if self._mode == "r" then
    self._file.readReferences = self._file.readReferences - 1
  end
end

function filePrototype:open(mode)
  if self.writeReference then
    error("file already open for writing")
  end

  if mode == "r" then
    self.readReferences = self.readReferences + 1
    return setmetatable({
      _file = self,
      _position = 1,
      _mode = mode
    }, {__index = filePrototype})
  end  
end

local vio = {}

function vio.createFile()
  return setmetatable({
    content = "",
    readReferences = 0,
    writeReference = false
  }, {__index = filePrototype})
end

return vio