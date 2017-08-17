function send(interface, channel, message)
  --uses reply channel as message 'id'
  local token = math.random(0, 65536)
  interface.open(channel)
  interface.transmit(channel, token, message)
  local timer = os.startTimer(1)

  while true do
    local sEvent, p1, p2, p3, p4 = os.pullEvent()
    if sEvent == "modem_message" then
      if p2 == channel and p3 == token then
        if p4 == "OK"  then
          interface.close(channel)
          return true
        end
      end
    elseif sEvent == "timer" then
      if timer == p1 then
        interface.close(channel)
        return false, "timeout"
      end
    end
  end
end

function listen(interface, channel, timeout)
  if interface.isOpen(channel) then
    return false, "already listening on " .. tostring(channel)
  end
  interface.open(channel)
  local timer = nil
  if timeout then
    timer = os.startTimer(timeout)
  end

  while true do
    local sEvent, p1, p2, p3, p4 = os.pullEvent()
    if sEvent == "modem_message" then
      if p2 == channel then
        interface.transmit(channel, p3, "OK")
        interface.close(channel)
        return true, p4
      end
    elseif sEvent == "timer" then
      if timer == p1 then
        interface.close(channel)
        return false, "timeout"
      end
    end
  end
end
