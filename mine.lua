args = {...}
x_size = args[1]
z_size = args[2]
x = 0
y = 0
z = 0
dir = 1

w = peripheral.wrap("right")
os.loadAPI("CTMP")

function sign (int)
  if int >= 0 then
    return 1
  else
    return -1
  end
end

function layer()

  limx = x
  limx2 = x_size-(x+1)
  diffx = sign(limx2 - limx)
  for x_t=limx,limx2,diffx do
    limz  = z
    limz2 = z_size-(z+1)
    diffz = sign(limz2 - limz)
    for z_t=limz,limz2,diffz do
      goto(x_t, z_t)
      turtle.digDown()
    end
  end
end

function goto(x_t, z_t)
  deltaX = x_t - x
  deltaZ = z_t - z
  if deltaX == 0 and deltaZ == 0 then
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

function send_update (type)
  local m = {}
  if type == "layer_done" then
    m["sender"] = "turtle"
    m["type"] = "mine_progress"
    m["data"] = tostring(y)
    term.write("sending layer done update")
  else
    return
  end
  c = coroutine.create(function ()
    r, reason = CTMP.send(w, 155, _MASTER_ID .. "sytax error", textutils.serialize(m))
    if r == false then
      term.write("couldn't send update because " .. reason)
    else
      term.write("success")
    end
  end)
  print(coroutine.resume(c))
end

for i=1,args[3] do
  layer()
  turtle.down()
  y = y - 1
  send_update("layer_done")
end
