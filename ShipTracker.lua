-- startup.lua

local CHANNEL = 42
local INTERVAL = 30
local LABEL = os.getComputerLabel() or ("Unit-" .. os.getComputerID())

local modem = peripheral.find("modem")

while true do
  local x, y, z = gps.locate(5)
  if x then
    modem.transmit(CHANNEL, CHANNEL, {
      label = LABEL,
      x = math.floor(x),
      y = math.floor(y),
      z = math.floor(z),
      time = os.time()
    })
  end
  os.sleep(INTERVAL)
end
