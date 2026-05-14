-- ship.lua
-- Save as /startup.lua on the ship computer
-- LEFT = turn left, RIGHT = turn right, BACK = forward thrust

local TARGET_CHANNEL = 42
local SHIP_CHANNEL = 50
local TURN_LEFT = "left"
local TURN_RIGHT = "right"
local FORWARD = "back"
local PULSE_TIME = 0.1
local DEAD_ZONE = 5
local INTERVAL = 0.5
local CALIBRATION_TIME = 3  -- seconds to burn forward on startup

local modem = peripheral.find("modem")
if not modem then print("No modem!") return end

modem.open(TARGET_CHANNEL)
modem.open(SHIP_CHANNEL)

local target = nil
local ship = nil
local lastShip = nil
local calibrated = false

local function getBearing(x1, z1, x2, z2)
  local dx = x2 - x1
  local dz = z2 - z1
  local angle = math.deg(math.atan2(dx, -dz))
  return (angle + 360) % 360
end

local function getTurnDelta(current, target)
  local delta = (target - current + 360) % 360
  if delta > 180 then delta = delta - 360 end
  return delta
end

local function getHeading()
  if not ship or not lastShip then return nil end
  local dx = ship.x - lastShip.x
  local dz = ship.z - lastShip.z
  if math.abs(dx) < 1 and math.abs(dz) < 1 then return nil end
  return (math.deg(math.atan2(dx, -dz)) + 360) % 360
end

local function stopAll()
  redstone.setOutput(TURN_LEFT, false)
  redstone.setOutput(TURN_RIGHT, false)
  redstone.setOutput(FORWARD, false)
end

local function pulseLeft()
  redstone.setOutput(TURN_LEFT, true)
  os.sleep(PULSE_TIME)
  redstone.setOutput(TURN_LEFT, false)
end

local function pulseRight()
  redstone.setOutput(TURN_RIGHT, true)
  os.sleep(PULSE_TIME)
  redstone.setOutput(TURN_RIGHT, false)
end

-- Listen for both ship and target positions
local function listenLoop()
  while true do
    local event, side, ch, repCh, msg = os.pullEvent("modem_message")
    if type(msg) == "table" then
      if ch == TARGET_CHANNEL and msg.label then
        target = {x = msg.x, y = msg.y, z = msg.z}
      elseif ch == SHIP_CHANNEL and msg.label then
        lastShip = ship
        ship = {x = msg.x, y = msg.y, z = msg.z}
      end
    end
  end
end

-- Calibration: burn forward until we have two distinct GPS positions
local function calibrate()
  print("Calibrating heading...")
  redstone.setOutput(FORWARD, true)

  -- Wait until we get two GPS reads with meaningful movement
  local attempts = 0
  while attempts < 20 do
    os.sleep(0.5)
    attempts = attempts + 1
    if getHeading() then
      break
    end
  end

  redstone.setOutput(FORWARD, false)

  if getHeading() then
    print("Calibrated! Heading: " .. math.floor(getHeading()) .. "°")
    calibrated = true
  else
    print("Calibration failed - ship may not be moving.")
    print("Steering will activate once movement detected.")
  end
end

-- Steering loop
local function steerLoop()
  -- Wait for first GPS fix from ship channel
  print("Waiting for ship GPS...")
  while not ship do
    os.sleep(0.5)
  end

  calibrate()

  print("Steering active, tracking ch." .. TARGET_CHANNEL)

  while true do
    if target and ship then
      local bearing = getBearing(ship.x, ship.z, target.x, target.z)
      local heading = getHeading()

      if heading then
        local delta = getTurnDelta(heading, bearing)
        if math.abs(delta) > DEAD_ZONE then
          if delta < 0 then
            pulseLeft()
          else
            pulseRight()
          end
        else
          stopAll()
        end
      end
    end
    os.sleep(INTERVAL)
  end
end

stopAll()
print("Ship steering online")
print("Target ch." .. TARGET_CHANNEL .. " | Ship GPS ch." .. SHIP_CHANNEL)
parallel.waitForAll(listenLoop, steerLoop)