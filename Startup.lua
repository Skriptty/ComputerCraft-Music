rednet.open("back")
shell.openTab(function()
    while true do
        -- Listen for the base server searching for them
        local id, msg, prot = rednet.receive("locate_player")
        local x, y, z = gps.locate(5)
        if x then
            rednet.broadcast({x=math.floor(x), y=math.floor(y), z=math.floor(z)}, "found_player")
        end
    end
end)
 
print("--- GLOBAL GPS POCKET SYSTEM ---")
print("Type 'track' to send your location to base.")
print("---------------------------------")
 
while true do
    write("> ")
    local input = read()
    if input == "track" then
        print("Locating satellites...")
        local x, y, z = gps.locate(5)
        if x then
            rednet.broadcast({x=math.floor(x), y=math.floor(y), z=math.floor(z)}, "found_player")
            print("Location sent to base!")
        else
            print("Error: Out of GPS host range.")
        end
    end
end
