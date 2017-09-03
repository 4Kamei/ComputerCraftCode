args = {...}

local write = nil
if io.write then
  write = io.write
elseif term.write then
  write = term.write
end

if args[1] == "help" then
  print("usage excavate <shape> <parameters>")
  print("shapes include: ")
  print("   cylinder <radius> <depth>")
  print("   hemisphere <radius>")
  return
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function sign (int)
  if int >= 0 then
    return 1
  else
    return -1
  end
end

local function move_position (x_t, z_t)
  deltaX = x_t - x
  deltaZ = z_t - z
  if deltaX == 0 and deltaZ == 0 then
    write("Error MOVING")
  else
    toDir = math.abs((3-deltaX)*deltaX + (2 - deltaZ)*deltaZ)
    deltaDir = toDir - dir
    if math.abs(deltaDir) > 2 then
      deltaDir = -sign(deltaDir)
    end
    while deltaDir ~= 0 do
      if deltaDir < 0 then
        turtle.turnLeft()
        deltaDir = deltaDir + 1
      end
      if deltaDir > 0 then
        turtle.turnRight()
        deltaDir = deltaDir - 1
      end
    end
    turtle.dig()
    if turtle.forward() then
      x = x + deltaX
      z = z + deltaZ
    end
    dir=toDir
  end
end

local function get_next(x, z)
  if dir == 1 then
    z = z + 1
  elseif dir == 2 then
    x = x + 1
  elseif dir == 3 then
    z = z - 1
  elseif dir == 4 then
    x = x - 1
  end
  return x, z
end

local function forward()
  if turtle.forward() then
    x, z = get_next(x, z)
  end
end

local function turnLeft()
  dir = dir - 1
  if dir == 0 then
    dir = 4
  end
  turtle.turnLeft()
end

local function turnRight()
  dir = dir + 1
  if dir == 5 then
    dir = 1
  end
  turtle.turnRight()
end

local function checkInSphere(x, z, radius)
  return x*x + z*z < radius*radius
end

local function sphereY(x, z, radius)
  return math.sqrt(radius * radius - x*x - z*z)
end

local function hemisphere (radius)
  local diam = radius * 2 + 1
  local limx = x
  local limx2 = diam-(x+1)
  local diffx = sign(limx2 - limx)
  local yOffset = 0
  for nextX =limx,limx2,diffx do
    local limz  = z
    local limz2 = diam-(z+1)
    local diffz = sign(limz2 - limz)
    for nextZ =limz,limz2,diffz do
      move_position(nextX, nextZ)
      if checkInSphere(x, z, radius) then
        local distY = sphereY(x, z, radius) + yOffset
        for i=1,distY do
          turtle.digDown()
          turtle.down()
        end
        for i=1,distY do
          turtle.up()
        end
      end
    end
  end
end

x = 0
y = 0
z = 0
dir = 1

lookup = {
  ["cylinder"] = cylinder,
  ["hemisphere"] = hemisphere,
}

lookup[args[1]](args[2], args[3])
