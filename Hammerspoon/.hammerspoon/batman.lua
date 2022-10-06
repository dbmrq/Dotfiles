
-- http://github.com/dbmrq/dotfiles/

-- Batman

-- requires https://github.com/actuallymentor/battery

local batteryMenu = hs.menubar.new(true)

function disp_time(time)
  local hours = math.floor(time/60)
  local minutes = math.floor(time % 60)
  return string.format("%02d:%02d",hours,minutes)
end

function updateBatteryMenu()

    if hs.battery.isCharging() then
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local timeRemaining = hs.battery.timeToFullCharge()
        local remainingString = timeRemaining == -1 and "Calculating" or disp_time(timeRemaining)
        local remainingTitle = "Time Remaining: " .. remainingString
        local chargeTitle = "Stop Charging"
        local chargeFn = hs.execute('sudo /usr/local/bin/smc -k CH0B -w 02')
        batteryMenu:setMenu({
            {title = remainingTitle},
            {title = chargeTitle, fn = chargeFn}
        })
    elseif hs.battery.powerSource() == 'Battery Power' then
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local timeRemaining = hs.battery.timeRemaining()
        local remainingString = timeRemaining == -1 and "Calculating..."
            or disp_time(timeRemaining)
        local remainingTitle = "Time Remaining: " .. remainingString
        batteryMenu:setMenu({{title = remainingTitle}})
        if hs.battery.percentage() < 50.0 then
            hs.execute('sudo /usr/local/bin/smc -k CH0B -w 00')
        end
    elseif hs.battery.percentage() < 100.0 then
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local chargeTitle = "Charge"
        local chargeFn = hs.execute('sudo /usr/local/bin/smc -k CH0B -w 00')
        batteryMenu:setMenu({{title = chargeTitle, fn = chargeFn}})
    else
        batteryMenu:removeFromMenuBar()
    end
end

batteryWatcher = hs.battery.watcher.new(updateBatteryMenu)

batteryWatcher:start()

updateBatteryMenu()

