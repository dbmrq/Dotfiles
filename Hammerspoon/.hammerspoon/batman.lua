
-- http://github.com/dbmrq/dotfiles/

-- Batman

-- requires https://github.com/actuallymentor/battery

local batteryMenu = hs.menubar.new(true)

function disp_time(time)
  local hours = math.floor(time/60)
  local minutes = math.floor(time % 60)
  return string.format("%02d:%02d",hours,minutes)
end

local forceCharge = false

function disableCharging() hs.execute('sudo /usr/local/bin/smc -k CH0B -w 02') end
function enableCharging() hs.execute('sudo /usr/local/bin/smc -k CH0B -w 00') end

function chargingDisabled()
    return string.find(hs.execute("smc -k CH0B -r", true), '00') == nil
end
function chargingStatus()
    return chargingDisabled and "Charging Disabled" or "ChargingEnabled"
end


function updateBatteryMenu()
    local menu
    if hs.battery.isCharging() then
        hs.alert.show("Is Charging")
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local timeRemaining = hs.battery.timeToFullCharge()
        local remainingString = timeRemaining == -1 and "Calculating" or disp_time(timeRemaining)
        local remainingTitle = "Time Remaining: " .. remainingString
        local chargeTitle = "Disable Charging"
        menu = {
            {title = remainingTitle, disabled = true},
            {title = chargeTitle, fn = disableCharging}
        }
        if hs.battery.percentage() > 70.0 and not forceCharge then
            disableCharging()
        end
    elseif hs.battery.powerSource() == 'Battery Power' then
        hs.alert.show("Battery Power")
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local timeRemaining = hs.battery.timeRemaining()
        local remainingString = timeRemaining == -1 and "Calculating..."
            or disp_time(timeRemaining)
        local remainingTitle = "Time Remaining: " .. remainingString
        menu = {{title = remainingTitle, disabled = true}}
        if hs.battery.percentage() < 50.0 then
            enableCharging()
        end
    elseif hs.battery.percentage() < 100.0 then
        hs.alert.show("Plugged But Not Charging")
        batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local chargeTitle = "Enable Charging"
        local chargeFn = function()
            forceCharge = true
            enableCharging()
        end
        menu = {{title = chargeTitle, fn = chargeFn}}
    else
        hs.alert.show("Plugged At 100%")
        batteryMenu:removeFromMenuBar()
        forceCharge = false
        disableCharging()
    end
    table.insert(menu, 1, {title = chargingStatus(), disabled = true})
    batteryMenu:setMenu(menu)
end

batteryWatcher = hs.battery.watcher.new(updateBatteryMenu)

batteryWatcher:start()

updateBatteryMenu()

