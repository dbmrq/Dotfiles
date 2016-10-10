
-- Night Shift

-- From 7 pm to 12 am the temperature will shift from 6500K to 4000K
-- From 4 am to 8 am the temperature will shift from 4000K to 2500K
-- From 8 am to 11 am the temperature will shift from 2500K to 6500K
-- The menu mar icon toggles it on and off

function setGamma(temperature)-- {{{1
    for _,screen in pairs(hs.screen.allScreens()) do
        local whitepoint = {red = 1, green = 1, blue = 1}
        local blackpoint = {red = 0, green = 0, blue = 0}
        whitepoint["red"] = ramp[temperature][1]
        whitepoint["green"] = ramp[temperature][2]
        whitepoint["blue"] = ramp[temperature][3]
        screen:setGamma(whitepoint, blackpoint)
    end
end-- }}}1

function toggleNightShift()-- {{{1
    for _,screen in pairs(hs.screen.allScreens()) do
        gamma = screen:getGamma()
        if gamma["whitepoint"]["red"] == 1 and
            gamma["whitepoint"]["green"] == 1 and
            gamma["whitepoint"]["blue"] == 1 then
                nightShift()
        else
            hs.screen.restoreGamma()
        end
    end
end-- }}}1

function nightShift()-- {{{1
    time = hs.timer.localTime()
    if time > hs.timer.hours(19) then
        interval = hs.timer.localTime() - hs.timer.hours(19)
        shifts = math.floor(interval / hs.timer.minutes(12))
        temperature = 6500 - (shifts * 100)
        setGamma(temperature)
    elseif time < hs.timer.hours(4) then
        setGamma(4000)
    elseif time < hs.timer.hours(8) then
        interval = hs.timer.localTime() - hs.timer.hours(4)
        shifts = math.floor(interval / hs.timer.minutes(16))
        temperature = 4000 - (shifts * 100)
        setGamma(temperature)
    end
end-- }}}1

for time = hs.timer.hours(19),        -- from 7 pm {{{1
    hs.timer.seconds('23:59:59') + 1, -- until midnight
    hs.timer.minutes(12) do           -- every 12 minutes
                                      -- increase temperature 100K
        hs.timer.doAt(time, '1d', function()
            interval = hs.timer.localTime() - hs.timer.hours(19)
            shifts = math.floor(interval / hs.timer.minutes(12))
            temperature = 6500 - (shifts * 100)
            setGamma(temperature)
        end)
end
hs.timer.doAt(0, '1d', function() setGamma(4000) end)-- }}}1

for time = hs.timer.hours(4), -- from 4 am {{{1
    hs.timer.hours(8),        -- until 8 am
    hs.timer.minutes(16) do   -- every 16 minutes
                              -- increase temperature 100K
        hs.timer.doAt(time, '1d', function()
            interval = hs.timer.localTime() - hs.timer.hours(4)
            shifts = math.floor(interval / hs.timer.minutes(16))
            temperature = 4000 - (shifts * 100)
            setGamma(temperature)
        end)
end
hs.timer.doAt(hs.timer.hours(8), '1d', function() setGamma(2500) end)-- }}}1

for time = hs.timer.hours(8), -- from 8 am-- {{{
    hs.timer.hours(11),       -- until 11 am
    270 do                    -- every 4,5 minutes (270 seconds)
                              -- increase temperature 100K
        hs.timer.doAt(time, '1d', function()
            interval = hs.timer.localTime() - hs.timer.hours(8)
            shifts = math.floor(interval / 270)
            temperature = 4000 + (shifts * 100)
            setGamma(temperature)
        end)
end
hs.timer.doAt(hs.timer.hours(11), '1d', function() setGamma(6500) end)-- }}}

ramp = {-- {{{1
    [1000]={1.00000000,  0.18172716,  0.00000000},
    [1100]={1.00000000,  0.25503671,  0.00000000},
    [1200]={1.00000000,  0.30942099,  0.00000000},
    [1300]={1.00000000,  0.35357379,  0.00000000},
    [1400]={1.00000000,  0.39091524,  0.00000000},
    [1500]={1.00000000,  0.42322816,  0.00000000},
    [1600]={1.00000000,  0.45159884,  0.00000000},
    [1700]={1.00000000,  0.47675916,  0.00000000},
    [1800]={1.00000000,  0.49923747,  0.00000000},
    [1900]={1.00000000,  0.51943421,  0.00000000},
    [2000]={1.00000000,  0.54360078,  0.08679949},
    [2100]={1.00000000,  0.56618736,  0.14065513},
    [2200]={1.00000000,  0.58734976,  0.18362641},
    [2300]={1.00000000,  0.60724493,  0.22137978},
    [2400]={1.00000000,  0.62600248,  0.25591950},
    [2500]={1.00000000,  0.64373109,  0.28819679},
    [2600]={1.00000000,  0.66052319,  0.31873863},
    [2700]={1.00000000,  0.67645822,  0.34786758},
    [2800]={1.00000000,  0.69160518,  0.37579588},
    [2900]={1.00000000,  0.70602449,  0.40267128},
    [3000]={1.00000000,  0.71976951,  0.42860152},
    [3100]={1.00000000,  0.73288760,  0.45366838},
    [3200]={1.00000000,  0.74542112,  0.47793608},
    [3300]={1.00000000,  0.75740814,  0.50145662},
    [3400]={1.00000000,  0.76888303,  0.52427322},
    [3500]={1.00000000,  0.77987699,  0.54642268},
    [3600]={1.00000000,  0.79041843,  0.56793692},
    [3700]={1.00000000,  0.80053332,  0.58884417},
    [3800]={1.00000000,  0.81024551,  0.60916971},
    [3900]={1.00000000,  0.81957693,  0.62893653},
    [4000]={1.00000000,  0.82854786,  0.64816570},
    [4100]={1.00000000,  0.83717703,  0.66687674},
    [4200]={1.00000000,  0.84548188,  0.68508786},
    [4300]={1.00000000,  0.85347859,  0.70281616},
    [4400]={1.00000000,  0.86118227,  0.72007777},
    [4500]={1.00000000,  0.86860704,  0.73688797},
    [4600]={1.00000000,  0.87576611,  0.75326132},
    [4700]={1.00000000,  0.88267187,  0.76921169},
    [4800]={1.00000000,  0.88933596,  0.78475236},
    [4900]={1.00000000,  0.89576933,  0.79989606},
    [5000]={1.00000000,  0.90198230,  0.81465502},
    [5100]={1.00000000,  0.90963069,  0.82838210},
    [5200]={1.00000000,  0.91710889,  0.84190889},
    [5300]={1.00000000,  0.92441842,  0.85523742},
    [5400]={1.00000000,  0.93156127,  0.86836903},
    [5500]={1.00000000,  0.93853986,  0.88130458},
    [5600]={1.00000000,  0.94535695,  0.89404470},
    [5700]={1.00000000,  0.95201559,  0.90658983},
    [5800]={1.00000000,  0.95851906,  0.91894041},
    [5900]={1.00000000,  0.96487079,  0.93109690},
    [6000]={1.00000000,  0.97107439,  0.94305985},
    [6100]={1.00000000,  0.97713351,  0.95482993},
    [6200]={1.00000000,  0.98305189,  0.96640795},
    [6300]={1.00000000,  0.98883326,  0.97779486},
    [6400]={1.00000000,  0.99448139,  0.98899179},
    [6500]={1.00000000,  1.00000000,  1.00000000},
    [6600]={0.98947904,  0.99348723,  1.00000000},
    [6700]={0.97940448,  0.98722715,  1.00000000},
    [6800]={0.96975025,  0.98120637,  1.00000000},
    [6900]={0.96049223,  0.97541240,  1.00000000},
    [7000]={0.95160805,  0.96983355,  1.00000000},
    [7100]={0.94303638,  0.96443333,  1.00000000},
    [7200]={0.93480451,  0.95923080,  1.00000000},
    [7300]={0.92689056,  0.95421394,  1.00000000},
    [7400]={0.91927697,  0.94937330,  1.00000000},
    [7500]={0.91194747,  0.94470005,  1.00000000},
    [7600]={0.90488690,  0.94018594,  1.00000000},
    [7700]={0.89808115,  0.93582323,  1.00000000},
    [7800]={0.89151710,  0.93160469,  1.00000000},
    [7900]={0.88518247,  0.92752354,  1.00000000},
    [8000]={0.87906581,  0.92357340,  1.00000000},
    [8100]={0.87315640,  0.91974827,  1.00000000},
    [8200]={0.86744421,  0.91604254,  1.00000000},
    [8300]={0.86191983,  0.91245088,  1.00000000},
    [8400]={0.85657444,  0.90896831,  1.00000000},
    [8500]={0.85139976,  0.90559011,  1.00000000},
    [8600]={0.84638799,  0.90231183,  1.00000000},
    [8700]={0.84153180,  0.89912926,  1.00000000},
    [8800]={0.83682430,  0.89603843,  1.00000000},
    [8900]={0.83225897,  0.89303558,  1.00000000},
    [9000]={0.82782969,  0.89011714,  1.00000000},
    [9100]={0.82353066,  0.88727974,  1.00000000},
    [9200]={0.81935641,  0.88452017,  1.00000000},
    [9300]={0.81530175,  0.88183541,  1.00000000},
    [9400]={0.81136180,  0.87922257,  1.00000000},
    [9500]={0.80753191,  0.87667891,  1.00000000},
    [9600]={0.80380769,  0.87420182,  1.00000000},
    [9700]={0.80018497,  0.87178882,  1.00000000},
    [9800]={0.79665980,  0.86943756,  1.00000000},
    [9900]={0.79322843,  0.86714579,  1.00000000},
    [10000]={0.78988728,  0.86491137,  1.00000000},
    -- from https://github.com/jonls/redshift/blob/master/src/colorramp.c
}-- }}}1

local icon = hs.menubar.new()-- {{{1
icon:setTooltip("Night Shift")
icon:setTitle("☾")
icon:setClickCallback(function() toggleNightShift() end)-- }}}1

for _,screen in pairs(hs.screen.allScreens()) do-- {{{1
    gamma = screen:getGamma()
    if gamma["whitepoint"]["red"] == 1 and
        gamma["whitepoint"]["green"] == 1 and
        gamma["whitepoint"]["blue"] == 1 then
            nightShift()
    else
        hs.screen.restoreGamma()
        hs.reload()
        -- It doesn't seem like the best idea to reload HS here, but
        -- if we don't do that and HS is reloaded without calling
        -- hs.screen.restoreGamma() first, hs.screen.setGamma() won't work
        -- reliably. I'm open to other suggestions.
    end
end-- }}}1

