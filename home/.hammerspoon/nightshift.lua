
-- Night Shift

-- From 6 pm to 10 pm the temperature will shift from 6500K to 4000K
-- From 2 am to 6 am the temperature will shift from 4000K to 2700K

local time = hs.timer.localTime()

if time > hs.timer.hours(12) and time < hs.timer.hours(19) then
    hs.redshift.start(4000, '20:00', '11:00', '4h', false, {"VLC"})
else
    hs.redshift.start(2700, '04:00', '11:00', '4h', false, {"VLC"}, 4000)
end

hs.timer.doAt('17:00', '1d', function()
    hs.redshift.start(4000, '20:00', '11:00', '4h', false, {"VLC"})
end)

hs.timer.doAt('01:00', '1d', function()
    hs.redshift.start(2700, '04:00', '11:00', '4h', false, {"VLC"}, 4000)
end)

hs.timer.doAt('11:00', hs.redshift.stop)

-- super is defined at init.lua
hs.hotkey.bind(super, 'n', 'Night Shift', hs.redshift.toggle)

local icon = hs.menubar.new()
icon:setTooltip("Night Shift")
icon:setTitle("☾")
icon:setClickCallback(function() hs.redshift.toggle() end)

