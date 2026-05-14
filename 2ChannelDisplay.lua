local CHANNELS = {42, 50}
local modem = peripheral.find("modem")
local monitor = peripheral.find("monitor")

modem.open(42)
modem.open(50)

monitor.setTextScale(0.5)

local players = {}

local function drawMonitor()
  monitor.clear()
  monitor.setCursorPos(1, 1)
  local w, h = monitor.getSize()

  monitor.setBackgroundColor(colors.blue)
  monitor.setTextColor(colors.white)
  monitor.clearLine()
  local title = " GPS TRACKER "
  monitor.setCursorPos(math.floor((w - #title) / 2) + 1, 1)
  monitor.write(title)
  monitor.setBackgroundColor(colors.black)

  monitor.setCursorPos(1, 3)
  monitor.setTextColor(colors.yellow)
  monitor.write(string.format("%-16s %6s %4s %6s  %s", "Player", "X", "Y", "Z", "Time"))

  monitor.setTextColor(colors.gray)
  monitor.setCursorPos(1, 4)
  monitor.write(string.rep("-", w))

  local row = 5
  local count = 0
  for label, data in pairs(players) do
    if row > h then break end
    monitor.setCursorPos(1, row)
    monitor.setTextColor(colors.white)
    local timeStr = string.format("%05.1f", data.time)
    monitor.write(string.format("%-16s %6d %4d %6d  %s",
      label:sub(1,16), data.x, data.y, data.z, timeStr))
    row = row + 1
    count = count + 1
  end

  if count == 0 then
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.gray)
    monitor.write("  Waiting for signals...")
  end

  monitor.setCursorPos(1, h)
  monitor.setTextColor(colors.gray)
  monitor.write("Ch:42/50  Players:" .. count)
end

drawMonitor()

while true do
  local event, side, ch, repCh, msg = os.pullEvent("modem_message")
  if type(msg) == "table" and msg.label then
    players[msg.label] = {
      x = msg.x,
      y = msg.y,
      z = msg.z,
      time = msg.time
    }
    drawMonitor()
  end
end
