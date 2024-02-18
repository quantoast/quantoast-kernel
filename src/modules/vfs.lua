local function getVfsNode(parent, name)
    if parent.children[name] then
      return parent.children[name]
    end
    local node = {
      parent = parent
    }
    if parent.backing:isDirectory(name) then
      node.children = {}
    end
    if parent then
      parent.children[name] = node
      if parent.backing then
        node.backing = parent.backing:getChild(name)
      end
    end
end

local function getVfsNodeLink(parent, name)
  local node = getVfsNode(parent, name)
  while node.link do
    node = node.link
  end

  return node
end

local function createVfsNode(parent, name, nodeType)
  local node = {
    parent = parent
  }
  if nodeType == "directory" then
    node.children = {}
  end
  if parent then
    if parent.children[name] or parent.backing:hasChild(name) then
      error("File or directory already exists")
    end
    parent.children[name] = node
    if parent.backing then
      if nodeType == "file" then
        node.backing = parent.backing:createFile(name)
      elseif nodeType == "directory" then
        node.backing = parent.backing:createDirectory(name)
      elseif type(nodeType) == "table" then
        node.link = nodeType
      end
    end
  end
  return node
end

local vfsTree = createVfsNode(nil, nil, "directory")

local function resolvePath(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part == ".." then
      table.remove(parts)
    elseif part ~= "." then
      table.insert(parts, part)
    end
  end
  return parts
end

local function traverse(node, name, requireVfs)
  if not node.children[name] and not requireVfs then
    return nil
  end
  local child = node.children[name]
  child = child or getVfsNodeLink(node, name)
  if requireVfs then
    node.children[name] = child
  end

  return child
end

local function traverseToFile(file, requireVfs)
  local parts = resolvePath(file)
  local node = vfsTree
  for i = 1, #parts do
    node = traverse(node, parts[i], requireVfs)
    if not node then
      return nil
    end
  end
  return node
end

local function traverseToParent(file, requireVfs)
  local parts = resolvePath(file)
  if #parts == 0 then
    return nil
  end
  local node = vfsTree
  for i = 1, #parts - 1 do
    node = traverse(node, parts[i], requireVfs)
    if not node then
      return nil
    end
  end
  return node, parts[#parts]
end

local function remove(node, name, recursive)
  local child = node.children[name]
  if not child then
    return
  end

  if recursive then
    for rname in pairs(child.children) do
      remove(child, rname, true)
    end
  end

  node.children[name] = nil
  if type(child.backing) == "table" then
    child.backing:delete()
  end
end

function vfsTree.mount(path, backing)
  local node = traverseToFile(path, true)
  if node == nil then
    error("No such file or directory")
  end
  if node.backing then
    error("Mount point is already in use")
  end
  if not node.children then
    error("Not a directory")
  end
  if #node.children > 0 then
    error("Directory is not empty")
  end

  node.backing = backing
end

function vfsTree.remove(file, recursive)
  local node, name = traverseToParent(file, false)
  if not node then
    error("No such file or directory")
  end
  remove(node, name, recursive)
end

function vfsTree.list(file)
  local node = traverseToFile(file, false)
  if not node then
    error("No such file or directory")
  end

  local found = {
    ["."] = true,
    [".."] = true
  }
  for name in pairs(node.children) do
    if name:sub(-1) == "/" then
      name = name:sub(1, -2)
    end
    found[name] = true
  end
  if node.backing then
    for _, name in ipairs(node.backing:list()) do
      found[name] = true
    end
  end

  local result = {}
  for name in pairs(found) do
    table.insert(result, name)
  end

  return result
end

function vfsTree.exists(file)
  return traverseToFile(file, false) ~= nil
end

function vfsTree.isDirectory(file)
  local node = traverseToFile(file, false)

  return node and node.children ~= nil
end

function vfsTree.link(target, link)
  local node, name = traverseToParent(link, true)
  if not node then
    error("No such file or directory")
  end
  if node.children[name] then
    error("File or directory already exists")
  end
---@diagnostic disable-next-line: need-check-nil
  node.children[name] = createVfsNode(node, name, traverse(vfsTree, target, false))
end

return vfsTree