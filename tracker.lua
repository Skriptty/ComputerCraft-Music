-- tracker.lua
-- Run this on the pocket computer

local CHANNEL = 42  -- must match display.lua
local LABEL = os.getComputerLabel() or ("Unit-" .. os.getComputerID())

local modem = peripheral.find("modem")
if not modem then
  print("No modem found!")
  return
end

local function getGPS()
  local x, y, z = gps.locate(5)
  return x, y, z
end

print("GPS Tracker: " .. LABEL)
print("Press [T] to transmit location")
print("Press [Q] to quit")
print("")

while true do
  local event, key = os.pullEvent("key")

  if key == keys.t then
    local x, y, z = getGPS()
    if x then
      local data = {
        label = LABEL,
        x = math.floor(x),
        y = math.floor(y),
        z = math.floor(z),
        time = os.time()
      }
      modem.transmit(CHANNEL, CHANNEL, data)
      print(string.format("[SENT] %s @ %d, %d, %d", LABEL, x, y, z))
    else
      print("[ERROR] GPS signal not found!")
    end

  elseif key == keys.q then
    print("Tracker stopped.")
    break
  end
end
