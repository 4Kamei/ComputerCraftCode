local function setup_gps_cube(x, y, z)
  print("setting up cube around " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))
  turtle.back()
  turtle.select(1)
  turtle.place()
  turtle.select(2)
  turtle.drop()
  turtle.up()
  local positions = {}
  positions[1] = {2, 5, -2}
  positions[2] = {2, 5, 2}
  positions[3] = {-2, 5, -2}
  positions[4] = {-2, 5, 2}
  positions[5] = {0, 7, 0}
  ids = fs.open("gpshosts", "w")
  for i,v in ipairs(positions) do
    turtle.select(3)
    turtle.place()
    local data = {}
    data["type"] = "order"
    data["pos_x"] = x
    data["pos_y"] = y
    data["pos_z"] = z
    data["to_x"] = v[1]
    data["to_y"] = v[2]
    data["to_z"] = v[3]
    local id = peripheral.call("front", "getID")
    ids.write(id)
    ids.write("\n")
    turtle.select(4)
    turtle.drop(1)
    print("turning on")
    peripheral.call("front", "turnOn")
    print("adding fuel")
    local result = nil
    local err = nil
    repeat
      result, err = CTMP.send(w, 155, id, textutils.serialize(data))
      print("result=" .. tostring(result) .. " - " .. tostring(err))
    until result == true
    sleep(1.5)
  end
  ids.close()
  turtle.down()
  turtle.select(2)
  turtle.suck()
  turtle.select(1)
  turtle.dig()
  turtle.forward()
end

local function get_region (x1, z1, s_x, s_z, index)
  local r = {}
  r["x"] = x1
  r["z"] = z1
  r["s_x"] = s_x
  r["s_z"] = s_z
  r["i"] = index
  return r
end

local function compute_regions (x1, y1, z1, x2, y2, z2, segSize)
    regions = {}

    local s_x = math.abs(x1 - x2)
    local s_z = math.abs(z1 - z2)
    local extra_X = s_x % segSize
    local extra_Z = s_z % segSize
    print(extra_X)
    print(extra_Z)
    index = 1

    for z=0,s_z-(1+extra_Z),segSize do
        for x=0,s_x-(1+extra_X),segSize do
          regions[index] = get_region(x, z, segSize, segSize, index)
          index = index + 1
        end
        if extra_X > 0 then
          regions[index] = get_region(s_x - extra_X, z, extra_X, segSize, index)
          index = index + 1
        end
    end
    if extra_Z > 0 then
      regions[index] = get_region(s_x - extra_X, s_z - extra_Z, extra_X, extra_Z, index)
    end

    return regions
end

local function contains(data, array)
  --binary search
end

local function new_turtle(data)
  local id = data["id"]
  local t_ids = fs.open("workers", "wr")
  local ids = JSON.decode(t_ids)
  if ~ids[id] then
    ids[id] = true
  else
    print("computer with ID " .. id .. " already a worker?")
  end
  t_ids.write(JSON.encode(t_ids))
  t_ids.close()
end

--[[
  wifi message format:
  new_turtle:
    id - id of the turtle
]]

local function main()
  local lookup = {
    ["new_turtle"] = new_turtle(x),
  }
  while true do
    local res, message = CTMP.listen(w, 155)
    print(tostring(res) .. " : " .. message)
    if res then
      local data = textutils.unserialize(message)
      if data then
        type = data["order"]
        local f = lookup[type]
        if f then
          f(data["data"])
        end
        print("unknown data type \"" .. type .. "\"")
      end
      print("recieved unknown message \"" .. message .. "\"")
    end
  end
end

os.loadAPI("CTMP")
os.loadAPI("JSON")
shell.setDir(".")
w = peripheral.wrap("right")
args = {...}
local x = 0
local y = 0
local z = 0
local dir = 1

shell.setDir("miner")

if args[1] == "manual" then
  x = args[2]
  y = args[3]
  z = args[4]
  setup_gps_cube(x, y, z)
elseif args[1] == "auto" then
  local f
  if args[2] then
    f = args[2]
  else
    print("using default config")
    f = "config.miner"
  end
  if fs.exists(f) == false then
    print("Config file \"" .. f .. "\" doesn't exist")
    return
  end
  local fi = fs.open(f, "r")
  local text = JSON.decode(fi.readAll())
  fi.close()

  --Setup GPS
  local x1 = text["region"]["x1"]
  local y1 = text["region"]["y1"]
  local z1 = text["region"]["z1"]
  local x2 = text["region"]["x2"]
  local y2 = text["region"]["y2"]
  local z2 = text["region"]["z2"]
  local segSize = text["segments"]
  local x = text["master"]["x"]
  local y = text["master"]["y"]
  local z = text["master"]["z"]
  local masterID = os.getComputerID()
  setup_gps_cube(x, y, z)

  --Compute Regions
  regions = compute_regions(x1, y1, z1, x2, y2, z2, segSize)
  file = fs.open("regions", "w")
  file.write(JSON.encode(regions))
  file.close()
  --Main routine

  main()
end
