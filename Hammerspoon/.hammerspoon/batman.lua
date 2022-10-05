
-- http://github.com/dbmrq/dotfiles/

-- Batman

local batteryMenu = hs.menubar.new(true)

function disp_time(time)
  local hours = math.floor(time/60)
  local minutes = math.floor(time % 60)
  return string.format("%02d:%02d",hours,minutes)
end

function updateBatteryMenu()

    if hs.battery.isCharging() then
        -- batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local menuTitle = "Time Remaining: " .. disp_time(hs.battery.timeToFullCharge())
        batteryMenu:setMenu({{title = menuTitle}})
        batteryMenu:setTooltip(menuTitle)
    elseif hs.battery.isCharging() or hs.battery.powerSource() == 'Battery Power' then
        -- batteryMenu:returnToMenuBar()
        batteryMenu:setTitle(math.floor(hs.battery.percentage()) .. '%')
        local menuTitle = "Time Remaining: " .. disp_time(hs.battery.timeRemaining())
        batteryMenu:setMenu({{title = menuTitle}})
        batteryMenu:setTooltip(menuTitle)
    else
        batteryMenu:removeFromMenuBar()
    end
end

batteryWatcher = hs.battery.watcher.new(updateBatteryMenu)

batteryWatcher:start()

updateBatteryMenu()

