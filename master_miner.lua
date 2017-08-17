function setup_gps_cube(x, y, z)
  print("setting up cube around " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))
  turtle.back()
  turtle.select(1)
  turtle.place()
  turtle.select(2)
  turtle.drop()
  turtle.up()
  local positions = {}
  positions[1] = {20, 10, -20}
  positions[2] = {20, 10, 20}
  positions[3] = {-20, 10, -20}
  positions[4] = {-20, 10, 20}
  positions[5] = {0, 20, 0}
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
    data["id"] = peripheral.call("front", "getID")
    turtle.select(4)
    turtle.drop(1)
    print("turning on")
    peripheral.call("front", "turnOn")
    print("adding fuel")
    local result = nil
    local err = nil
    repeat
      result, err = CTMP.send(w, 155, textutils.serialize(data))
      print("result=" .. tostring(result) .. " - " .. tostring(err))
    until result == true
    sleep(1.5)
  end
  turtle.down()
  turtle.select(2)
  turtle.suck()
  turtle.select(1)
  turtle.dig()
  turtle.forward()
end


os.loadAPI("CTMP")
shell.setDir(".")
w = peripheral.wrap("right")
args = {...}
local x = 0
local y = 0
local z = 0
local dir = 1
if args[1] == "auto" then
  x = args[2]
  y = args[3]
  z = args[4]
  setup_gps_cube(x, y, z)
end
