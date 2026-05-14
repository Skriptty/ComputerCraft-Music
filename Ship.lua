-- ship.lua
local TARGET_CHANNEL = 42
local SHIP_CHANNEL = 50
local TURN_LEFT = "left"
local TURN_RIGHT = "right"
local FORWARD = "back"

local DEAD_ZONE = 12
local COAST_ZONE = 45
local STOP_DISTANCE = 5
local INTERVAL = 0.2
local HEADING_SMOOTH = 4

local modem = peripheral.find("modem")
if not modem then print("No modem!") return end

modem.open(TARGET_CHANNEL)
modem.open(SHIP_CHANNEL)

local target = nil
local ship = nil
local shipHistory = {}

local function addShipPos(x, z)
  table.insert(shipHistory, {x = x, z = z})
  if #shipHistory > HEADING_SMOOTH then
    table.remove(shipHistory, 1)
  end
end

local function getDistance(x1, z1, x2, z2)
  local dx = x2 - x1
  local dz = z2 - z1
  return math.sqrt(dx*dx + dz*dz)
end

local function getBearing(x1, z1, x2, z2)
  local angle = math.deg(math.atan2(x2-x1, -(z2-z1)))
  return (angle + 360) % 360
end

local function getTurnDelta(current, tgt)
  local delta = (tgt - current + 360) % 360
  if delta > 180 then delta = delta - 360 end
  return delta
end

local function getHeading()
  if #shipHistory < 2 then return nil end
  local first = shipHistory[1]
  local last = shipHistory[#shipHistory]
  local dx = last.x - first.x
  local dz = last.z - first.z
  if math.abs(dx) < 1 and math.abs(dz) < 1 then return nil end
  return (math.deg(math.atan2(dx, -dz)) + 360) % 360
end

local function stopAll()
  redstone.setOutput(TURN_LEFT, false)
  redstone.setOutput(TURN_RIGHT, false)
  redstone.setOutput(FORWARD, false)
end

local function listenLoop()
  while true do
    local event, side, ch, repCh, msg = os.pullEvent("modem_message")
    if type(msg) == "table" then
      if ch == TARGET_CHANNEL and msg.label then
        target = {x = msg.x, y = msg.y, z = msg.z}
      elseif ch == SHIP_CHANNEL and msg.label then
        ship = {x = msg.x, y = msg.y, z = msg.z}
        addShipPos(msg.x, msg.z)
      end
    end
  end
end

local function calibrate()
  print("Calibrating...")
  redstone.setOutput(FORWARD, true)
  local attempts = 0
  while attempts < 30 do
    os.sleep(0.5)
    attempts = attempts + 1
    if getHeading() then break end
  end
  redstone.setOutput(FORWARD, false)
  os.sleep(1)
  if getHeading() then
    print("Heading: " .. math.floor(getHeading()) .. " deg")
  else
    print("Calibration failed - waiting for movement.")
  end
end

local lastDelta = 0

local function steerLoop()
  print("Waiting for ship GPS...")
  while not ship do os.sleep(0.5) end
  calibrate()
  print("Steering active.")

  while true do
    os.sleep(INTERVAL)

    if target and ship then
      local dist = getDistance(ship.x, ship.z, target.x, target.z)

      if dist <= STOP_DISTANCE then
        stopAll()
        print("Arrived.")

      else
        local bearing = getBearing(ship.x, ship.z, target.x, target.z)
        local heading = getHeading()

        if heading then
          local delta = getTurnDelta(heading, bearing)
          local overshooting = (lastDelta > 0 and delta < 0) or (lastDelta < 0 and delta > 0)
          lastDelta = delta

          print(string.format("Dist:%dm Hdg:%d Tgt:%d Dlt:%d %s",
            math.floor(dist), math.floor(heading), math.floor(bearing),
            math.floor(delta), overshooting and "[OVERSHOOT]" or ""))

          if math.abs(delta) <= DEAD_ZONE then
            redstone.setOutput(TURN_LEFT, false)
            redstone.setOutput(TURN_RIGHT, false)
            redstone.setOutput(FORWARD, true)

          elseif math.abs(delta) <= COAST_ZONE or overshooting then
            redstone.setOutput(TURN_LEFT, false)
            redstone.setOutput(TURN_RIGHT, false)
            redstone.setOutput(FORWARD, false)

          else
            redstone.setOutput(FORWARD, false)
            if delta < 0 then
              redstone.setOutput(TURN_RIGHT, false)
              redstone.setOutput(TURN_LEFT, true)
            else
              redstone.setOutput(TURN_LEFT, false)
              redstone.setOutput(TURN_RIGHT, true)
            end
          end

        else
          print("No heading...")
        end
      end
    end
  end
end

stopAll()
print("Ship steering online")
print("Target ch." .. TARGET_CHANNEL .. " | Ship GPS ch." .. SHIP_CHANNEL)
parallel.waitForAll(listenLoop, steerLoop)