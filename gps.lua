os.loadAPI("CTMP")
w = peripheral.wrap("right")
turtle.refuel()

function waitForStop()
  print("waiting for stop")
  while true do
    local data = textutils.unserialize(CTMP.listen(w, 155))
    if data["id"] == os.getComputerID() then
      print("got stop signal")
      return
    end
  end
end

function serveGPS()
  print("serving GPS")
  shell.run("gps", tostring(to_x + x), tostring(to_y + y), tostring(to_z + z))
end

function move_position(x, y, z)
  print("moving")
  for i=1,y do
    turtle.up()
  end
  dir = "x+"
  if x < 0 then
    turtle.turnRight()
    turtle.turnRight()
    dir = "x-"
  end
  for i=1,x do
    turtle.forward()
  end
  if z < 0 then
    if dir == "x+" then
      turtle.turnLeft()
    else
      turtle.turnRight()
    end
    dir = "z-"
  else
    if dir == "x+" then
      turtle.turnRight()
    else
      turtle.turnLeft()
    end
    dir = "z+"
  end
  for i=1,z do
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
  for i=1,x do
    turtle.back()
  end

  if z > 0 then
    turtle.turnLeft()
  else
    turtle.turnRight()
  end

  for i=1,z do
    turtle.forward()
  end

  for i=1,y do
    turtle.dowm()
  end
end

while true do
  print("init")
  local data = textutils.unserialize(CTMP.listen(w, 155))
  local type = data["order"]
  local id = data["id"]
  print("got message id = " .. tostring(id))
  if tonumber(id) == os.getComputerID() then
    local x = data["y_x"]
    local y = data["y_y"]
    local z = data["y_z"]
    local to_x = data["to_x"]
    local to_y = data["to_y"]
    local to_z = data["to_z"]
    move_position(to_x, to_y, to_z)
    parallels.waitForAny(serveGPS, waitForStop)
    move_position_back(to_x, to_y, to_z)
    print("exiting")
    shell.exit()
    return
  end
end
