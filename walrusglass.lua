    -- WalrusGlass2 (Based upon Plastic Beta v0.12)
    -- A Google Glass like OS/Programs/Whatever you want to call it
    -- That runs on Terminal Glasses in OpenPeripheral
    -- Just stick in a computer with a Terminal Glass Peripheral and run it!
    -- Have fun using it!
         
    local tArgs = {...}
     
    local function searchArgs(text)
            for k,v in pairs(tArgs) do
                    if v == text then return true end
            end
            return false
    end
     
    if not http then print("Sorry, WalrusGlass requires HTTP to run!") return end
     
    local walrusglassInstallation = shell.getRunningProgram()
     
    -- Find glass bridge
    local walrusglass = false
    local worldSensor = false
     
    if fs.exists("/ocs/apis/sensor") then
            os.loadAPI("ocs/apis/sensor")
    end
     
    for k,v in pairs(rs.getSides()) do
            if (peripheral.getType(v) == "openperipheral_glassesbridge") then
                    walrusglass = peripheral.wrap(v)
                    break
            elseif (peripheral.getType(v) == "sensor") and (not worldSensor) then
                    worldSensor = sensor.wrap(v)
                    if not (worldSensor.getSensorName() == "worldCard") then
                            worldSensor = false
                    end
            end
    end
     
    if not walrusglass then print("Could not find Glass Bridge!") error() end
     
    local rootApps = nil
     
    if searchArgs("root") then
            rootApps = {}
            if term.isColor() then
                    term.setTextColor(colors.red)
            end
            print("-- [[ ROOT MODE ENABLED ]] --")
            print("WAlRUSGLASS MAY BECOME UNSTABLE AND")
            print("MAY CRASH. USE AT YOUR OWN RISK!")
            if fs.isDir("/walrusglassApps") then
     
            else
                    print("Creating /walrusglassApps folder")
                    fs.delete("/walrusglassApps")
                    fs.makeDir("/walrusglassApps")
            end
            -- Example walrusglass root app
            --       --[[walrusglass Root App]]--
            --       --NAME: Example App
            --       if cmd == "hello" then
            --       print("HELLO!")
            --       end
     
            print("Searching for apps in /walrusglassApps")
            print("")
            for k,v in pairs(fs.list("/walrusglassApps")) do
                    if not(fs.isDir("/walrusglassApps/"..v)) then
                            local f = io.open("/walrusglassApps/"..v, "r")
                            if f:read("*l") == "--[[walrusglass Root App]]--" then
                                    local name = f:read("*l"):match("%-%-NAME%: (.+)")
                                    dofile("/walrusglassApps/"..v)
                                    print("-- Application registered: ", name, " --")
                                    local data = f:read("*a")
                                    rootApps[name] = data
                            end
                            f:close()
                    end
            end
            print("")
            print("Search completed!")
            print("Starting WalrusGlass...")
    end
     
    if not(searchArgs("nodaemon")) and not(searchArgs("root")) then
            term.clear()
            term.setCursorPos(1,1)
     
            print("walrusglass daemon now running. Use exit to exit")
    end
     
    local function reliableSleep(time)
            sleep(time)
    end
     
     
    -- Setup the actual "glass"
    local gColors = {}
    gColors.red = 0xff3333
    gColors.blue = 0x7dd2e4
    gColors.yellow = 0xffff4d
    gColors.green = 0x4dff4d
    gColors.gray = 0xe0e0e0
    gColors.textGray = 0x818181
    gColors.text = 0x5a5a5a
    gColors.rain = 0x2e679f
    gColors.orange = 0xFF9900
     
    walrusglass.clear()
    local mainBox = walrusglass.addBox(20, 20, 1, 48, gColors.orange, 0.7)
    local outlineT = walrusglass.addBox(18,18,2,2,gColors.white,0.7)
    local outlineB = walrusglass.addBox(18,68,2,2,gColors.white,0.7)
    --Startup Animation
    if not(searchArgs("lite")) then
            -- 120, Edge is 140, Center is 80
            for i = 0, 17 do
                    mainBox.setWidth(i*8)
                    outlineT.setWidth(i*8+4)
                    outlineB.setWidth(i*8+4)
                    reliableSleep(0.01)
            end
    else
            mainBox.setWidth(136)
            outlineT.setWidth(140)
            outlineB.setWidth(140)
            mainBox.setHeight(48)
    end
    local header = walrusglass.addText(75, 25, "", gColors.gray)
    local secondText = walrusglass.addText(50, 40, "", gColors.textGray)
    local thirdText = walrusglass.addText(40, 55, "", gColors.textGray)
    local mainText = walrusglass.addText(40, 27, "", gColors.textGray)
    local forthText = walrusglass.addText(40, 55, "", gColors.text)
    local tempText = walrusglass.addText(40, 70, "", gColors.text)
    header.setZ(5)
    mainText.setZ(5)
    secondText.setZ(5)
    thirdText.setZ(5)
    tempText.setZ(5)
    forthText.setZ(5)
     
    local function closeAnimation()
            if mainBox then
                    pcall(mainText.delete)
                    pcall(secondText.delete)
                    pcall(header.delete)
                    pcall(thirdText.delete)
                    pcall(tempText.delete)
                    pcall(forthText.delete)
                    os.queueEvent("walrusglass_clock_manager", "kill")
                    reliableSleep(0.1)
                    if not(searchArgs("lite")) then
                            pcall(function()
                            for i = 17, 0, -1 do
                                    mainBox.setWidth(i*8)
                                    outlineT.setWidth(i*8+2)
                                    outlineB.setWidth(i*8+2)
                                    reliableSleep(0.01)
                            end
                            end)
                    end
                    pcall(outlineT.delete)
                    pcall(outlineB.delete)
                    pcall(mainBox.delete)
            end
    end
     
    local oldShutdown = os.shutdown
    local oldReboot = os.reboot
     
    function os.shutdown()
            closeAnimation()
            return oldShutdown()
    end
     
    function os.reboot()
            closeAnimation()
            return oldReboot()
    end
     
    local function runwalrusglass()
            -- Variables & Stuff
            local corruption = false
            local firstTime = true
            local showClock = false
     
            -- Fancy functions
            local gWidth = 24
            local extraSupport = 0
     
            local function trimText(s)
                    return s:match("^%s*(.-)%s*$")
            end
     
            local function walrusglassGet(url, noCancel)
                    http.request(url)
                    while true do
                            local e, rUrl, rmsg = os.pullEvent()
                            if (e == "http_success") and (rUrl == url) then
                                    if rmsg then
                                            local data = rmsg.readAll()
                                            rmsg.close()
                                            if data then
                                                    return "success", data
                                            else
                                                    sleep(1)
                                                    http.request(url)
                                            end
                                    else
                                            sleep(1)
                                            http.request(url)
                                    end
                            elseif (e == "http_failure") and (rUrl == url) then
                                    return "failure"
                            elseif (e == "chat_command") and ((trimText(rUrl:lower()) == "cancel") or (trimText(rUrl:lower()) == "home")) and not(noCancel) then
                                    return "cancel"
                            end
                    end
            end
     
            local function slowText(text, object)
                    if not(searchArgs("lite")) then
                            object.setText("")
                            for i = 1, #text do
                                    object.setText(string.sub(text, 1, i))
                                    reliableSleep(0.01)
                            end
                    else
                            object.setText(text)
                    end
            end
     
            local function getCenter(text)
                    return math.ceil(((136/2)-(walrusglass.getStringWidth(text)*(0.65)/2))+20-0.5)
            end
     
            local function centerText(text, object)
                    object.setText("")
                    object.setX(getCenter(text))
                    slowText(text, object)
            end
     
            local function copyTable(tb)
                    local newTable = {}
                    for k,v in pairs(tb) do
                            newTable[k] = v
                    end
                    return newTable
            end
     
            -- Load settings
            local settings = {}
            if fs.exists("/walrusglassOptions") and not(fs.isDir("/walrusglassOptions")) then
                    local f = io.open("/walrusglassOptions", "r")
                    local data = f:read("*a")
                    settings = textutils.unserialize(data)
                    f:close()
                    firstTime = false
            end
     
            if not(settings) or not((type(settings["name"]) == "string") and (type(settings["use12hour"]) == "boolean") and
                    (type(settings["city"]) == "string") and (type(settings["showtime"]) == "string") and
                    ((settings["temperature"] == "c") or (settings["temperature"] == "f"))) and not(firstTime) then
                    corruption = true
                    header.setY(25)
                    header.setColor(gColors.red)
                    centerText("Error: Corruption", header)
                    mainText.setY(37)
                    mainText.setColor(gColors.yellow)
                    centerText("Options data is", mainText)
                    secondText.setY(47)
                    secondText.setColor(gColors.yellow)
                    centerText("corrupted.", secondText)
                    thirdText.setY(57)
                    thirdText.setColor(gColors.yellow)
                    thirdText.setX(40)
                    slowText("Resetting walrusglass...", thirdText)
                    reliableSleep(2)
                    fs.delete("/walrusglassOptions")
                    closeAnimation()
                    reliableSleep(1)
                    shell.run(walrusglassInstallation, "nodaemon", unpack(tArgs))
                    error()
            end
     
            local function getWT(city, canceller)
                    local function getRawWT(city, canceller) --f or c for unit
                            local unit = settings["temperature"]
                            local use12hour = settings["use12hour"]
                            local months = {"Jan", "Feb", "March", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"}
                            local resp, webData = nil
                            if canceller then
                                    resp, webData = walrusglassGet("http://api.worldweatheronline.com/free/v2/weather.ashx?q="..textutils.urlEncode(city).."&format=xml&extra=localObsTime&num_of_days=1&includelocation=yes&key=1699d0a322c182d23419120f9330f", true)
                            else
                                    resp, webData = walrusglassGet("http://api.worldweatheronline.com/free/v2/weather.ashx?q="..textutils.urlEncode(city).."&format=xml&extra=localObsTime&num_of_days=1&includelocation=yes&key=1699d0a322c182d23419120f9330f")
                            end
                            if resp == "cancel" then
                                    return "cancel"
                            elseif resp == "success" then
                            else
                                    error()
                            end
                            if webData:find("<error>") then
                                    return "invalid"
                            end
                            local city, country = webData:match([[<areaName><!%[CDATA%[([^>]+)%]%]></areaName><country><!%[CDATA%[([^>]+)%]%]></country>]])
                            if trimText(country) == "United States Of America" then
                                    country = "USA"
                            end
                            city = trimText(city):gsub(" City", "")
                            local resolvedLocation = city .. ", " .. country
     
                            local currentTemp = nil
                            if unit == "c" then
                                    currentTemp = webData:match([[<current_condition>.+<temp_C>([^<]+)</temp_C>.+</current_condition>]])
                            elseif unit == "f" then
                                    currentTemp = webData:match([[<current_condition>.+<temp_F>([^<]+)</temp_F>.+</current_condition>]])
                            end
                            local currentHumidity = webData:match([[<current_condition>.+<humidity>([^<]+)</humidity>.+</current_condition>]])
                        local currentWeather = trimText(webData:match([[<current_condition>.+<weatherDesc><!%[CDATA%[([^>]+)%]%]></weatherDesc>.+</current_condition>]]))
                        local lowTemp, highTemp = nil
                            if unit == "c" then
                                    highTemp = webData:match([[<weather>.+<tempMaxC>([^<]+)</tempMaxC>.+</weather>]])
                                    lowTemp = webData:match([[<weather>.+<tempMinC>([^<]+)</tempMinC>.+</weather>]])
                            elseif unit == "f" then
                                    highTemp = webData:match([[<weather>.+<tempMaxF>([^<]+)</tempMaxF>.+</weather>]])
                                    lowTemp = webData:match([[<weather>.+<tempMinF>([^<]+)</tempMinF>.+</weather>]])
                            end
                            dayWeather = trimText(webData:match([[<weather>.+<weatherDesc><!%[CDATA%[([^<]+)%]%]></weatherDesc>.+</weather>]]))
     
                            local time = nil
                            local year, month, day, rawTime, timeFormat = webData:match("<localObsDateTime>(%d+)%-(%d+)%-(%d+) (%d+:%d+) (%u+)</localObsDateTime>")
                            local resolvedDate = day .. " " .. months[tonumber(month)] .. " " .. year
                            if not use12hour then
                                    if timeFormat == "AM" then
                                            if rawTime:sub(1,2) == "12" then
                                                    time = "0" .. rawTime:sub(3,-1)
                                            else
                                                    time = rawTime
                                            end
                                    elseif timeFormat == "PM" then
                                            if rawTime:sub(1,2) == "12" then
                                                    time = rawTime
                                            else
                                                    time = tostring(tonumber(rawTime:sub(1,2))+12) .. rawTime:sub(3,-1)
                                            end
                                    else
                                            error()
                                    end
                            else
                                    time = rawTime .. " " .. timeFormat
                            end
                            if time:sub(1,1) == "0" then time = time:sub(2,-1) end
                            local current = {}
                            current["temp"] = currentTemp
                            current["weather"] = currentWeather
                            current["humidity"] = currentHumidity
                            current["time"] = time
                            current["date"] = resolvedDate
                            current["url"] = timeURL
                            current["location"] = resolvedLocation
     
                            local day = {}
                            day["high"] = highTemp
                            day["low"] = lowTemp
                            day["weather"] = dayWeather
     
                            return "success", current, day
                    end
                    local result = nil
                    result = {pcall(getRawWT, city, canceller)}
                    if result[1] then
                            table.remove(result, 1)
                    end
                    if result[1] then
                            return unpack(result)
                    else
                            return "failure"
                    end
            end
     
            -- Get the time and weather!
            local function getTime(city)
                    --local resp, time = getTime(settings["city"])
                    local resp, cur, today = getWT(city)
                    if resp == "success" then
                            return "success", cur["time"]
                    else return "failure" end
            end
     
            local function displayTime(time)
                    if time then
                            if #time == 4 then
                                    mainText.setX(60)
                            elseif #time == 5 then
                                    mainText.setX(50)
                            elseif #time == 7 then
                                    mainText.setX(36)
                            elseif #time == 8 then
                                    mainText.setX(27)
                            end
                            mainText.setText(time)
                    end
            end
     
            local function resetScreen()
                    thirdText.setText("")
                    header.setText("")
                    forthText.setText("")
                    tempText.setText("")
                    mainText.setText("")
                    mainText.setColor(gColors.text)
                    mainText.setScale(3)
                    mainText.setY(32)
                    secondText.setText("")
                    secondText.setColor(gColors.blue)
                    secondText.setY(57)
                    os.queueEvent("walrusglass_clock_manager", "show")
                    centerText("Welcome, " .. settings["name"], secondText)
            end
     
            local function textScreen()
                    thirdText.setText("")
                    header.setText("")
                    mainText.setText("")
                    secondText.setText("")
                    os.queueEvent("walrusglass_clock_manager", "hide")
                    reliableSleep(0.05)
                    header.setScale(1)
                    mainText.setScale(1)
                    secondText.setScale(1)
                    thirdText.setScale(1)
                    header.setColor(gColors.text)
                    mainText.setColor(gColors.text)
                    secondText.setColor(gColors.text)
                    thirdText.setColor(gColors.text)
                    header.setY(25)
                    mainText.setY(37)
                    secondText.setY(47)
                    thirdText.setY(57)
                    reliableSleep(0.1)
            end
     
            local function squeezeScreen()
                    thirdText.setText("")
                    header.setText("")
                    mainText.setText("")
                    secondText.setText("")
                    forthText.setText("")
                    os.queueEvent("walrusglass_clock_manager", "hide")
                    reliableSleep(0.05)
                    header.setScale(1)
                    mainText.setScale(1)
                    secondText.setScale(1)
                    thirdText.setScale(1)
                    forthText.setScale(1)
                    header.setColor(gColors.text)
                    mainText.setColor(gColors.text)
                    secondText.setColor(gColors.text)
                    thirdText.setColor(gColors.text)
                    forthText.setColor(gColors.text)
                    header.setY(22)
                    mainText.setY(31)
                    secondText.setY(40)
                    thirdText.setY(49)
                    forthText.setY(58)
                    reliableSleep(0.1)
            end
     
            -- Setup functions
            local function setupName()
                    thirdText.setY(57)
                    secondText.setText("")
                    mainText.setText("")
                    thirdText.setText("")
                    centerText("What's your name?", mainText)
                    secondText.setY(47)
                    secondText.setScale(1)
                    secondText.setColor(gColors.text)
                    centerText("Ex: $$John", secondText)
                    local e, msg = os.pullEvent("chat_command")
                    local name = msg
                    secondText.setText("")
                    centerText("Your name is", mainText)
                    centerText(name .. "?", secondText)
                    thirdText.setColor(gColors.blue)
                    centerText("Options: $$y/n", thirdText)
                    while true do
                            local e, msg = os.pullEvent("chat_command")
                            msg = trimText(msg:lower())
                            if msg:find("y") then
                                    return name
                            elseif msg:find("n") then
                                    return setupName()
                            end
                    end
            end
     
     
            local function setupTime()
                    thirdText.setY(57)
                    secondText.setText("")
                    thirdText.setText("")
                    centerText("Use 12h Time Format?", mainText)
                    secondText.setColor(gColors.blue)
                    centerText("Options: $$y/n", secondText)
                    while true do
                            local e, msg = os.pullEvent("chat_command")
                            msg = trimText(msg:lower())
                            if msg:find("y") then
                                    return true
                            elseif msg:find("n") then
                                    return false
                            end
                    end
            end
     
            local function setupTemperature()
                    thirdText.setY(57)
                    secondText.setText("")
                    thirdText.setText("")
                    centerText("Celsius or Farenheit?", mainText)
                    secondText.setColor(gColors.blue)
                    centerText("Options: $$c/f", secondText)
                    while true do
                            local e, msg = os.pullEvent("chat_command")
                            msg = trimText(msg:lower())
                            if msg:find("c") then
                                    return "c"
                            elseif msg:find("f") then
                                    return "f"
                            end
                    end
            end
     
            local function setupLocation()
                    thirdText.setY(57)
                    secondText.setText("")
                    thirdText.setText("")
                    secondText.setColor(gColors.text)
                    thirdText.setColor(gColors.text)
                    centerText("What's your city?", mainText)
                    centerText("(To get time/weather)", secondText)
                    centerText("Ex: $$New York", thirdText)
                    while true do
                            local e, city = os.pullEvent("chat_command")
                            thirdText.setColor(gColors.yellow)
                            centerText("Connecting...", thirdText)
                            local resp, cur = getWT(city)
                            if resp == "success" then
                                    mainText.setText("")
                                    secondText.setText("")
                                    thirdText.setText("")
                                    centerText("You're in", mainText)
                                    centerText(cur["location"] .. "?", secondText)
                                    thirdText.setColor(gColors.blue)
                                    centerText("Options: $$y/n", thirdText)
                                    while true do
                                            local e, msg = os.pullEvent("chat_command")
                                            msg = trimText(msg:lower())
                                            if msg:find("y") then
                                                    return city
                                            elseif msg:find("n") then
                                                    return setupLocation()
                                            end
                                    end
                            else
                                    thirdText.setColor(gColors.red)
                                    centerText("Invalid city!", thirdText)
                            end
                    end
            end
     
            local function mainThread()    
                    local function start()
                            local function welcome()
                                    centerText("Welcome to", mainText)
                                    secondText.setScale(3)
                                    secondText.setX(40)
                                    slowText("walrusglass", secondText)
                                    reliableSleep(2)
                                    secondText.setText("")
                                    mainText.setText("")
                                    centerText("Setup", header)
                                    mainText.setText("")
                                    mainText.setColor(gColors.text)
                                    mainText.setY(37)
                                    thirdText.setY(57)
                                    return setupName()
                            end
     
                            if firstTime then
                                    settings["name"] = welcome()
                                    settings["use12hour"] = setupTime()
                                    settings["city"] = setupLocation()
                                    settings["temperature"] = setupTemperature()
                                    settings["showtime"] = "ingame"
     
                                    local f = io.open("/walrusglassOptions", "w")
                                    f:write(textutils.serialize(settings))
                                    f:close()
                                    closeAnimation()
                                    reliableSleep(1)
                                    shell.run(walrusglassInstallation, "nodaemon", unpack(tArgs))
                                    error()
                            else
                                    return
                            end
                    end
     
                    local function convert(query)
                            secondText.setX(25)
                            slowText("Powered by STANDS4 APIs", secondText)
                            --reliableSleep(1)
                            --secondText.setX(35)
                            --slowText("Converting... | cancel", secondText)
                            local resp, msg = walrusglassGet("http://www.stands4.com/services/v2/conv.php?uid=2464&tokenid=lQAygI15b9x34e2L&expression=" .. textutils.urlEncode(query))
                            if resp == "success" then
                                    if tonumber(msg:match("<errorCode>(%d+)")) > 0 then
                                            centerText(trimText(msg:match("<errorMessage>([^<]+)</errorMessage>")), secondText)
                                            return
                                    else
                                            local response = msg:match("<result>([^<]+)</result>")
                                            local replaceable = {["kilogram"] = "kg", ["nautical mile"] = "nmile" , ["megabyte"] = "mb", ["gigabyte"] = "gb", ["kilobyte"] = "kb"
                                                    ,["millimeter"] = "mm", ["centimeter"] = "cm", ["micrometer"] = "Um", ["nanometer"] = "nm", ["terrabyte"] = "tb", ["exabyte"] = "eb",
                                                    ["British"] = "gb", ["kilometer"] = "km", ["hour"] = "h", [" / "] = "/", ["&amp;"] = "", ["deg;"] = ""}
                                            for k,v in pairs(replaceable) do
                                                    response = response:lower():gsub(k,v)
                                                    response = response:lower():gsub(k .. "s",v)
                                            end
                                            if #response >24 then
                                                    local startSearch = response:find("%=")
                                                    local trim = response:find("%.", startSearch)
                                                    local units = response:find("%s", trim)
                                                    local nresponse = response:sub(1, trim+3) .. response:sub(units,-1)
                                                    response = trimText(nresponse)
                                            end
                                            secondText.setX(25)
                                            if #response > 22 then
                                                    slowText(response, secondText)
                                            else
                                                    centerText(response, secondText)
                                            end
                                            return
                                    end
                            elseif resp == "failure" then
                                    centerText("Service not available", secondText)
                                    return
                            elseif resp == "cancel" then
                                    centerText("Request Cancelled", secondText)
                                    return
                            end
                    end
     
                    local function renderWeather(city)
                            local resp, cur, day = nil
                            centerText("Src: World Weather Online",secondText)
                            if not city then
                                    resp, cur, day = getWT(settings["city"], true)
                            else
                                    resp, cur, day = getWT(city, true)
                            end
                            if resp == "success" then
                                            squeezeScreen()
                                            header.setColor(gColors.blue)
                                            centerText(cur["location"], header)
                                            mainText.setColor(gColors.textGray)
                                            centerText(cur["weather"], mainText)
                                            tempText.setX(97)
                                            tempText.setScale(3)
                                            tempText.setY(43)
                                            tempText.setColor(gColors.blue)
                                            slowText(cur["temp"]..settings["temperature"]:upper(), tempText)
                                            secondText.setX(23)
                                            slowText("Humidity: " .. cur["humidity"] .. "%", secondText)
                                            thirdText.setX(23)
                                            slowText("Current", thirdText)
                                            forthText.setX(23)
                                            slowText("$$back/day", forthText)
                                    local function loadCurrent()
                                            centerText(cur["weather"], mainText)
                                            slowText(cur["temp"]..settings["temperature"]:upper(), tempText)
                                            slowText("Current", thirdText)
                                            slowText("$$back/day", forthText)
                                            while true do
                                                    local e, msg = os.pullEvent("chat_command")
                                                    msg = trimText(msg:lower())
                                                    if (msg == "back") or msg == "home" then
                                                            return resetScreen()
                                                    elseif (msg == "day") then
                                                            return loadDay()
                                                    end
                                            end
                                    end
                                    local function loadDay()
                                            centerText(day["weather"], mainText)
                                            slowText(day["high"]..settings["temperature"]:upper(), tempText)
                                            slowText("Low: " .. day["low"] .. (settings["temperature"]:upper()), thirdText)
                                            slowText("$$back/cur", forthText)
                                            while true do
                                                    local e, msg = os.pullEvent("chat_command")
                                                    msg = trimText(msg:lower())
                                                    if (msg == "back") or msg == "home" then
                                                            return resetScreen()
                                                    elseif (msg:find("cur")) then
                                                            return loadCurrent()
                                                    end
                                            end
                                    end
                                    while true do
                                            local e, msg = os.pullEvent("chat_command")
                                            msg = trimText(msg:lower())
                                            if (msg == "back") or msg == "home" then
                                                    return resetScreen()
                                            elseif (msg == "day") then
                                                    return loadDay()
                                            end
                                    end
                            elseif resp == "cancel" then
                                    centerText("Request Cancelled", secondText)
                                    return
                            elseif resp == "invalid" then
                                    centerText("Invalid location!", secondText)
                                    return
                            else
                                    centerText("Service not available", secondText)
                                    return
                            end
                    end
     
                    local function renderDate(city)
                            centerText("Src: World Weather Online",secondText)
                            local resp, cur = getWT(city, true)
                            if resp == "success" then
                                    textScreen()
                                    header.setColor(gColors.blue)
                                    centerText("Current Time/Date", header)
                                    centerText(cur["location"], mainText)
                                    centerText(cur["date"] .. " - " .. cur["time"], secondText)
                                    centerText("$$back", thirdText)
                                    while true do
                                            local e, msg = os.pullEvent("chat_command")
                                            msg = trimText(msg:lower())
                                            if (msg == "back") or (msg == "home") then
                                                    resetScreen()
                                                    return
                                            end
                                    end
                            elseif resp == "cancel" then
                                    centerText("Request Cancelled", secondText)
                                    return
                            elseif resp == "invalid" then
                                    centerText("Invalid location!", secondText)
                                    return
                            else
                                    centerText("Service not available", secondText)
                                    return
                            end
                    end
     
                    local function getEnvs()
                            local newEnv = getfenv(0)
                            newEnv.secondText = secondText
                            newEnv.thirdText = thirdText
                            newEnv.forthText = forthText
                            newEnv.tempText = tempText
                            newEnv.mainText = mainText
                            newEnv.resetScreen = resetScreen
                            newEnv.squeezeScreen = squeezeScreen
                            newEnv.textScreen = textScreen
                            newEnv.slowText = slowText
                            newEnv.centerText = centerText
                            newEnv.walrusglassGet = walrusglassGet
                            newEnv.trimText = trimText
                            newEnv.header = header
                            newEnv.walrusglass = walrusglass
                            return newEnv
                    end
     
                    local function home()
                            local function resetSecond()
                                    secondText.setText("")
                                    secondText.setColor(gColors.blue)
                                    secondText.setY(57)
                                    secondText.setScale(1)
                            end
                            thirdText.setText("")
                            header.setText("")
                            mainText.setText("")
                            mainText.setColor(gColors.text)
                            mainText.setScale(3)
                            mainText.setY(32)
                            secondText.setText("")
                            secondText.setColor(gColors.blue)
                            secondText.setY(57)
                            displayTime("00:00 --")
                            os.queueEvent("walrusglass_clock_manager", "show")
                            centerText("Welcome, " .. settings["name"], secondText)
                            while true do
                                    local skipAll = false
                                    local e, msg = os.pullEvent()
                                    if e == "chat_command" then
                                            msg = trimText(msg:lower())
                                            if searchArgs("root") then
                                                    for k,v in pairs(rootApps) do
                                                            local a = loadstring("local cmd = [[" .. msg .. "]]\n" .. v)
                                                            if a then
                                                                    local env = getEnvs()
                                                                    setfenv(a, env)
                                                                    if a() then
                                                                            skipAll = true
                                                                    end
                                                            else
                                                                    print("Failed to run application: ", k)
                                                            end
                                                    end
                                            end
                                            if not(skipAll) then
                                                    if (msg:sub(1,1) == "=") then
                                                            local banned = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
                                                            "p", "q", "r", "s", "t", "u", "v", "w", "x","y", "z"}
                                                            local formula = msg:sub(2, -1):lower()
                                                            for k,v in pairs(banned) do
                                                                    formula = formula:gsub(v, "")
                                                            end
                                                            local func = loadstring("return " .. formula)
                                                            local e, resp = pcall(func)
                                                            if e and ((type(resp) == "number") or (type(resp) == "string")) then
                                                                    centerText("=" .. resp, secondText)
                                                            else
                                                                    centerText("Syntax Error", secondText)
                                                            end
                                                    elseif msg == "help" then
                                                            squeezeScreen()
                                                            header.setColor(gColors.blue)
                                                            centerText("Help, Try: $$", header)
                                                            centerText("=12*3, home, irl, restart,", mainText)
                                                            centerText("igl, quit, update, weather,", secondText)
                                                            centerText("time/weather for city,", thirdText)
                                                            centerText("convert x to y (back)", forthText)
                                                            while true do
                                                                    local _, msg = os.pullEvent("chat_command")
                                                                    msg = trimText(msg:lower())
                                                                    if (msg == "back") or (msg == "home") then
                                                                            resetScreen()
                                                                            break
                                                                    end
                                                            end
                                                    elseif msg == "about" then
                                                            secondText.setX(32)
                                                            slowText("walrusglass B v0.11 by 1lann", secondText)
                                                    elseif (msg:sub(1,8) == "weather ") or msg == "weather" then
                                                            local location = nil
                                                            if msg:sub(1,12) == "weather for " then
                                                                    location = trimText(msg:sub(13, -1))
                                                            elseif msg:sub(1,11) == "weather in " then
                                                                    location = trimText(msg:sub(12, -1))
                                                            elseif msg == "weather" then
                                                                    location = ""
                                                            else
                                                                    location = trimText(msg:sub(9, -1))
                                                            end
                                                            if location == "" then
                                                                    renderWeather()
                                                            else
                                                                    renderWeather(location)
                                                            end
                                                    elseif (msg:sub(1,8) == "time in ") or (msg:sub(1,9) == "time for ") or (msg:sub(1,9) == "date for ") then
                                                            local location = nil
                                                            if (msg:sub(1,8) == "time in ") then
                                                                    location = msg:sub(9,-1)
                                                            else
                                                                    location = msg:sub(10, -1)
                                                            end
                                                            if location == "" then
                                                                    centerText("No city speicifed!", secondText)
                                                            else
                                                                    renderDate(location)
                                                            end
                                                    elseif msg == "settings" then
                                                            local exit = false
                                                            while true do
                                                                    local noSave = false
                                                                    textScreen()
                                                                    header.setColor(gColors.blue)
                                                                    centerText("Change Settings", header)
                                                                    centerText("Options: temperature,", mainText)
                                                                    centerText("time format, name,", secondText)
                                                                    centerText("location, back", thirdText)
                                                                    while true do
                                                                            local _, msg = os.pullEvent("chat_command")
                                                                            msg = trimText(msg:lower())
                                                                            if (msg == "back") or (msg == "home") then
                                                                                    resetScreen()
                                                                                    exit = true
                                                                                    break
                                                                            elseif (msg == "temperature") then
                                                                                    mainText.setText("")
                                                                                    secondText.setText("")
                                                                                    thirdText.setText("")
                                                                                    header.setText("")
                                                                                    header.setColor(gColors.textGray)
                                                                                    centerText("Setup", header)
                                                                                    settings["temperature"] = setupTemperature()
                                                                                    noSave = false
                                                                            elseif (msg == "time format") then
                                                                                    mainText.setText("")
                                                                                    secondText.setText("")
                                                                                    thirdText.setText("")
                                                                                    header.setText("")
                                                                                    header.setColor(gColors.textGray)
                                                                                    centerText("Setup", header)
                                                                                    settings["use12hour"] = setupTime()
                                                                                    noSave = false
                                                                            elseif (msg == "name") then
                                                                                    mainText.setText("")
                                                                                    secondText.setText("")
                                                                                    thirdText.setText("")
                                                                                    header.setText("")
                                                                                    header.setColor(gColors.textGray)
                                                                                    centerText("Setup", header)
                                                                                    settings["name"] = setupName()
                                                                                    noSave = false
                                                                            elseif (msg == "location") then
                                                                                    mainText.setText("")
                                                                                    secondText.setText("")
                                                                                    thirdText.setText("")
                                                                                    header.setText("")
                                                                                    header.setColor(gColors.textGray)
                                                                                    centerText("Setup", header)
                                                                                    settings["city"] = setupLocation()
                                                                                    noSave = false
                                                                            else
                                                                                    noSave = true
                                                                            end
                                                                            if not(noSave) then
                                                                                    local f = io.open("/walrusglassOptions", "w")
                                                                                    f:write(textutils.serialize(settings))
                                                                                    f:close()
                                                                                    mainText.setText("")
                                                                                    secondText.setText("")
                                                                                    thirdText.setText("")
                                                                                    header.setText("")
                                                                                    mainText.setColor(gColors.green)
                                                                                    centerText("Settings saved!", mainText)
                                                                                    sleep(2)
                                                                                    break
                                                                            end
                                                                    end
                                                                    if exit then break end
                                                            end
                                                    elseif (msg:sub(1,8) == "convert ") then
                                                            os.queueEvent("walrusglass_clock_manager", "show")
                                                            resetSecond()
                                                            convert(msg)
                                                    elseif msg == "irl" then
                                                            if not(settings["showtime"] == "irl") then
                                                                    secondText.setX(30)
                                                                    slowText("Changing time... | cancel", secondText)
                                                                    local resp, time = getTime(settings["city"])
                                                                    if resp == "success" then
                                                                            settings["showtime"] = "irl"
                                                                            os.queueEvent("walrusglass_clock_manager", "force", time)
                                                                            os.queueEvent("walrusglass_clock_manager", "show")
                                                                            os.queueEvent("walrusglass_clock_manager", "irl")
                                                                            displayTime(time)
                                                                            local f = io.open("/walrusglassOptions", "w")
                                                                            f:write(textutils.serialize(settings))
                                                                            f:close()
                                                                            centerText("Time is now IRL", secondText)
                                                                    else
                                                                            centerText("Could not get IRL time!", secondText)
                                                                    end
                                                            else
                                                                    centerText("Time is already IRL!", secondText)
                                                            end
                                                    elseif msg == "ingame" or (msg == "igl") then
                                                            if not(settings["showtime"] == "ingame") then
                                                                    settings["showtime"] = "ingame"
                                                                    os.queueEvent("walrusglass_clock_manager", "force", textutils.formatTime(os.time(), not(settings["use12hour"])))
                                                                    os.queueEvent("walrusglass_clock_manager", "show")
                                                                    os.queueEvent("walrusglass_clock_manager", "ingame")
                                                                    local f = io.open("/walrusglassOptions", "w")
                                                                    f:write(textutils.serialize(settings))
                                                                    f:close()
                                                                    centerText("Time is now in-game", secondText)
                                                            else
                                                                    secondText.setX(30)
                                                                    slowText("Time is already in-game!", secondText)
                                                            end
                                                    elseif msg == "update" then
                                                            secondText.setX(35)
                                                            centerText("Updating... | cancel", secondText)
                                                            local resp, data = walrusglassGet("http://pastebin.com/raw.php?i=43nHyKXU")
                                                            if resp == "success" then
                                                                    local f = io.open(walrusglassInstallation, "w")
                                                                    f:write(data)
                                                                    f:close()
                                                                    closeAnimation()
                                                                    reliableSleep(1)
                                                                    shell.run(walrusglassInstallation, "nodaemon", unpack(tArgs))
                                                                    error()
                                                            elseif resp == "failure" then
                                                                    centerText("Failed to update!", secondText)
                                                            elseif resp == "cancel" then
                                                                    centerText("Request Cancelled", secondText)
                                                            end
                                                    elseif (msg == "home") or (msg == "clock") or (msg == "time") then
                                                            resetScreen()
                                                    elseif (msg == "restart") then
                                                            closeAnimation()
                                                            reliableSleep(1)
                                                            shell.run(walrusglassInstallation, "nodaemon", unpack(tArgs))
                                                            error()
                                                    elseif (msg == "exit") or (msg == "quit") or (msg == "stop") then
                                                            closeAnimation()
                                                            error()
                                                    else
                                                            centerText("Unknown Command!", secondText)
                                                    end
                                            end
                                    end
                            end
                    end
     
                    start()
                    home()
            end
     
            local function updateWeather()
                    if sensor then
                            if worldSensor then
                                    header.setY(22)
                                    local data = worldSensor.getTargets()["CURRENT"]
                                    if data["Thundering"] then
                                            header.setColor(gColors.textGray)
                                            header.setX(53)
                                            header.setText("Thunderstorm")
                                    elseif data["Raining"] then
                                            header.setColor(gColors.rain)
                                            header.setX(80)
                                            header.setText("Rain")
                                    elseif data["Daytime"] then
                                            header.setColor(gColors.yellow)
                                            header.setX(75)
                                            header.setText("Sunny")
                                    else
                                            header.setColor(gColors.rain)
                                            header.setX(59)
                                            header.setText("Clear Night")
                                    end
                            else
                                    header.setColor(gColors.textGray)
                                    header.setX(35)
                                    header.setText("Missing world sensor!")
                            end
                    end
            end
     
            local function weatherThread()
                    local timer = os.startTimer(5)
                    while true do
                            local e, id = os.pullEvent()
                            if e == "walrusglass_clock_manager" then
                                    if id == "hide" then
                                            showClock = false
                                    elseif id == "show" then
                                            updateWeather()
                                            timer = os.startTimer(5)
                                            showClock = true
                                    end
                            elseif (e == "timer") and (timer == id) and showClock then
                                    updateWeather()
                                    timer = os.startTimer(5)
                            end
                    end
            end
     
            local function backgroundThread()
                    local webUpdate = 0
                    local resp, time = nil
                    local lastTimeUpdate = os.clock()
                    local function updateTime(prevTime, city)
                            if os.clock() >= lastTimeUpdate+60 then
                                    webUpdate  = webUpdate + 1
                                    if webUpdate < 60 then
                                            if prevTime then
                                                    local hour,minute,ampm = prevTime:match("^(%d+):(%d+)(.-)$")
                                                    if ampm == " AM" then
                                                            if settings["use12hour"] == false then
                                                                    return getTime(city)
                                                            end
                                                            lastTimeUpdate = os.clock()
                                                            if minute == "59" then
                                                                    if hour == "11" then
                                                                            return "success","12:00 PM"
                                                                    elseif hour == "12" then
                                                                            return "success","1:00 AM"
                                                                    else
                                                                            return "success",tostring(tonumber(hour)+1)..":00 AM"
                                                                    end
                                                            else
                                                                    if #tostring(tonumber(minute)+1) > 1 then
                                                                            return "success",hour..":"..tostring(tonumber(minute)+1).." AM"
                                                                    else
                                                                            return "success",hour..":0"..tostring(tonumber(minute)+1).." AM"
                                                                    end
                                                            end
                                                    elseif ampm == " PM" then
                                                            if settings["use12hour"] == false then
                                                                    return getTime(city)
                                                            end
                                                            lastTimeUpdate = os.clock()
                                                            if minute == "59" then
                                                                    if hour == "11" then
                                                                            return "success","12:00 AM"
                                                                    elseif hour == "12" then
                                                                            return "success","1:00 PM"
                                                                    else
                                                                            return "success",tostring(tonumber(hour)+1)..":00 PM"
                                                                    end
                                                            else
                                                                    if #tostring(tonumber(minute)+1) > 1 then
                                                                            return "success",hour..":"..tostring(tonumber(minute)+1).." PM"
                                                                    else
                                                                            return "success",hour..":0"..tostring(tonumber(minute)+1).." PM"
                                                                    end
                                                            end
                                                    else
                                                            if settings["use12hour"] == true then
                                                                    return getTime(city)
                                                            end
                                                            lastTimeUpdate = os.clock()
                                                            if minute == "59" then
                                                                    if hour == "23" then
                                                                            return "success", "0:00"
                                                                    else
                                                                            return "success", tostring(tonumber(hour)+1)..":".."00"
                                                                    end
                                                            else
                                                                    if #tostring(tonumber(minute)+1) > 1 then
                                                                            return "success",hour..":"..tostring(tonumber(minute)+1)
                                                                    else
                                                                            return "success",hour..":0"..tostring(tonumber(minute)+1)
                                                                    end
                                                            end
                                                    end
                                            else
                                                    return "failure"
                                            end
                                    else
                                            return getTime(city)
                                    end
                            else
                                    return "success",prevTime
                            end
                    end
                    local clockType = settings["showtime"]
                    local timerID = nil
                    local updateTimer = nil
                    local previousClock = nil
                    local dynamicSleep = nil
                    local resp = nil
                    if settings["showtime"] == "irl" then
                            resp, time = getTime(settings["city"])
                            if resp == "success" then
                                    settings["showtime"] = "irl"
                                    os.queueEvent("walrusglass_clock_manager", "force", time)
                                    os.queueEvent("walrusglass_clock_manager", "show")
                                    os.queueEvent("walrusglass_clock_manager", "irl")
                                    displayTime(time)
                                    local f = io.open("/walrusglassOptions", "w")
                                    f:write(textutils.serialize(settings))
                                    f:close()
     
                            else
     
                            end
                    end
                    if clockType == "ingame" then
                            dynamicSleep = 0.83
                    else
                            dynamicSleep = 60
                    end
                    timerID = os.clock() + dynamicSleep
                    os.startTimer(0.83)
                    updateTimer = 0.83+os.clock()
                    while true do
                            if os.clock() >= updateTimer then
                                            os.startTimer(0.83)
                                            updateTimer = 0.83+os.clock()
                            end
                            local e, command, param =  os.pullEvent()
                            if e == "walrusglass_clock_manager" then
                                    if command == "show" then
                                            if time then
                                                    displayTime(time)
                                            end
                                            mainText.setColor(gColors.text)
                                            mainText.setScale(3)
                                            mainText.setY(32)
                                            header.setText("")
                                            showClock = true
                                            timerID = os.clock()
                                    elseif command == "hide" then
                                            header.setText("")
                                            mainText.setText("")
                                            timerID = os.clock()+2
                                            showClock = false
                                    elseif command == "irl" then
                                            clockType = "irl"
                                            dynamicSleep = 60
                                            timerID = os.clock() + dynamicSleep
                                    elseif command == "ingame" then
                                            clockType = "ingame"
                                            dynamicSleep = 0.83
                                            timerID = os.clock() + dynamicSleep
                                    elseif command == "force" then
                                            if param then
                                                    time = param
                                            end
                                    elseif command == "kill" then
                                            sleep(100)
                                    end
                            elseif os.clock() >= timerID then
                                    if showClock then
                                            if clockType == "irl" then
                                                    resp, time = updateTime(time,settings["city"])
                                                    if resp ~= "success" then
                                                            displayTime("ERROR")
                                                            webUpdate = 60
                                                    else
                                                            displayTime(time)
                                                    end
                                            elseif clockType == "ingame" then
                                                    time = textutils.formatTime(os.time(), not(settings["use12hour"]))
                                                    displayTime(time)
                                            end
                                    end
                                    timerID = os.clock() + dynamicSleep
                            end
                    end
            end
     
            local eError, eResp = pcall(function() parallel.waitForAny(mainThread,backgroundThread,weatherThread) end)
            if eError then
                    return
            elseif eResp then
                    if not(fs.exists("/walrusglassLog")) then
                            local f = io.open("/walrusglassLog", "w") f:write("-- walrusglass Error Logs --\n") f:close()
                    end
                    local f = io.open("/walrusglassLog", "a")
                    f:write(eResp .. "\n")
                    f:close()
                    mainText.setText("")
                    secondText.setText("")
                    thirdText.setText("")
                    forthText.setText("")
                    tempText.setText("")
                    header.setText("")
                    header.setY(25)
                    header.setColor(gColors.red)
                    centerText("walrusglass has crashed", header)
                    mainText.setY(37)
                    mainText.setColor(gColors.yellow)
                    secondText.setColor(gColors.yellow)
                    thirdText.setColor(gColors.yellow)
                    mainText.setScale(1)
                    secondText.setScale(1)
                    thirdText.setScale(1)
                    centerText("and will now restart.", mainText)
                    secondText.setY(47)
                    centerText("See /walrusglassLog for", secondText)
                    thirdText.setY(57)
                    centerText("more information.", thirdText)
                    reliableSleep(3)
                    closeAnimation()
                    reliableSleep(1)
                    shell.run(walrusglassInstallation, "nodaemon", unpack(tArgs))
                    error()
            end
    end
     
    local function walrusglassWrapper()
            pcall(runwalrusglass)
    end
     
    --[[function os.pullEvent(lookfor)
            local data = {os.pullEventRaw()}
            --if not(data[1] == "timer") and not(data[1] == "ocs_success") then
                    print(os.clock(), data[1], tostring(data[2]))
            --end
            if not lookfor then
                    return unpack(data)
            elseif data[1] == lookfor then
                    return unpack(data)
            end
    end]]
     
    if not(searchArgs("nodaemon")) then
            parallel.waitForAny(walrusglassWrapper, function() shell.run("/rom/programs/shell") end)
            closeAnimation()
            term.clear()
            term.setCursorPos(1,1)
            print("Thank you for using WalrusGlass Release 1")
            runwalrusglass()
            closeAnimation()
            term.clear()
            term.setCursorPos(1,1)
            print("Thank you for using WalrusGlass Release 1")
    end
