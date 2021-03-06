os.loadAPI("CTMP")
w = peripheral.wrap("left")
turtle.refuel()
local serveX = 0
local serveY = 0
local serveZ = 0
function waitForStop()
  print("waiting for stop")
  while true do
    local state, message = CTMP.listen(w, 155)
    local data = textutils.unserialize(message)
    if data["message"] == "stop" then
      print("got stop")
      return
    end
  end
end

function serveGPS()
  print("serving GPS at x=" .. tostring(serveX) .. " y=" .. tostring(serveY) .. " z=" .. tostring(serveZ))
  shell.run("gps", "host", tostring(serveX), tostring(serveY-1), tostring(serveZ))
end

function move_position(x, y, z)
  print("moving")
  print("x=" .. tostring(x) .. " y=" .. tostring(y) .. " z=" .. tostring(z))
  for i=1,y do
    turtle.up()
  end
  dir = "x+"
  if x < 0 then
    print("turning around")
    turtle.turnRight()
    turtle.turnRight()
    dir = "x-"
  end
  for i=1,math.abs(x) do
    print("moving forward in X")
    turtle.forward()
  end
  if z < 0 then
    print("negative z")
    if dir == "x+" then
      print("turn left")
      turtle.turnLeft()
    else
      print("turn right")
      turtle.turnRight()
    end
    dir = "z-"
  else
    print("positive z")
    if dir == "x+" then
      print("turn right")
      turtle.turnRight()
    else
      print("turn left")
      turtle.turnLeft()
    end
    dir = "z+"
  end
  print(dir)
  for i=1,math.abs(z) do
    turtle.forward()
  end
  if dir == "z-" then
    turtle.turnRight()
  else
    turtle.turnLeft()
  end
end

function move_position_back(x, y, z)
  print("moving")
  local func = turtle.forward()
  if x > 0 then
    func = turtle.back()
  end
  for i=1,math.abs(x) do
    func()
  end

  if z > 0 then
    turtle.turnLeft()
  else
    turtle.turnRight()
  end

  for i=1,math.abs(z) do
    turtle.forward()
  end

  for i=1,math.abs(y) do
    while turtle.down() do end
  end
end

while true do
  print("init")
  local state, mess = CTMP.listen(w, 155)
  local data = textutils.unserialize(mess)
  print(data)
  local type = data["type"]
  if type == "order" then
    local x = data["pos_x"]
    local y = data["pos_y"]
    local z = data["pos_z"]
    local to_x = data["to_x"]
    local to_y = data["to_y"]
    local to_z = data["to_z"]
    serveX = tonumber(x) + tonumber(to_x)
    serveY = tonumber(y) + tonumber(to_y)
    serveZ = tonumber(z) + tonumber(to_z)
    move_position(to_x, to_y, to_z)
    parallel.waitForAny(serveGPS, waitForStop)
    move_position_back(to_x, to_y, to_z)
    print("exiting")
    return
  end
end
