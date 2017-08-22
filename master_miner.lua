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
  r["regionID"] = index
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

--gets region data as table from regionID
local function get_region(regionID)
  local f = fs.open("regions", "r")
  local data = JSON.decode(f.readAll())
  f.close()
  for i,v in ipairs(table_name) do
    if regionID == v["regionID"] then
      return v
    end
  end
  print("error")
  error("region with ID " .. tostring(regionID) .. " doesn't exist?")
end
--assigns a job to turtle
--job contains data from 'jobs' to be serialized
local function assign_job(t_id, job)
  print("assigning turtle with id " .. tostring(t_id) .. " job with ID " .. tostring(job["regionID"]))
  local job_data = {}
  job_data["progress"] = job["progress"]
  job_data["region"] = get_region(job["regonID"])
  local message = textutils.serialize(job_data)
  repeat
    local res, message = CTMP.send(w, 155, t_id, message)
    if res == false then
      print("unable to send message : " .. message)
    end
  until res
  print("assigned")
end

--checks if there are any workers that can be assigned a job
local function check_jobs()
  print("checking jobs")
  local f_w = fs.open("workers", "r")
  local jobs = fs.open("jobs", "r")
  local workers = {}
  local index = 1
  repeat
    id = f_w.readLine()
    workers[index] = id
    index = index + 1
  until id
  local j = JSON.decode(jobs)

  jobs.close()
  f_w.close()
  local jobNum = j["jobNum"]

  local num = 1

  for i,v in ipairs(workers) do
    assgin_job(v, j[i])
    j[i] = nil
    workers[i] = nil
    jobNum = jobNum - 1
    num = num + 1
    if jobNum == 0 then
      return
    end
  end


  jobs = fs.open("jobs", "w")
  jobs.write(JSON.enocde(j))
  jobs.close()

  f_w = fs.open("workers", "w")
  for i,v in ipairs(workers) do
    f_w.write(v)
  end
  f_w.close()

  print("job check finished")
  print(tostring(num) .. " workers given jobs")

end

--adds a turtle to the workers list
local function new_turtle(data)
  local id = data["id"]
  local t_ids = fs.open("workers", "r")
  local ids = JSON.decode(t_ids.readAll())
  if ids[id] == nil then
    ids[id] = true
    print("added ID " .. tostring(id) .. " to workers list")
  else
    print("computer with ID " .. id .. " already a worker?")
  end
  t_ids.close()
  local t_ids = fs.open("workers", "w")
  t_ids.write(JSON.encode(t_ids))
  t_ids.close()
  check_jobs()
end

--[[
  wifi message format:
  new_turtle:
    id - id of the turtle
]]

local function main()
  local lookup = {
    ["new_turtle"] = new_turtle ,
  }
  print("main loop")
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
  if text["needsGPS"] == true then
    setup_gps_cube(x, y, z)
  end

  --Compute Regions
  print("computing regions")
  regions = compute_regions(x1, y1, z1, x2, y2, z2, segSize)
  file = fs.open("regions", "w")
  file.write(JSON.encode(regions))
  file.close()
  --Main routine

  main()
end
