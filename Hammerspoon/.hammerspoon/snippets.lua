
-- http://github.com/dbmrq/dotfiles/

local snippetMenu = hs.menubar.new(true)

function disp_time(time)--  ............................................. {{{1
  local hours = math.floor(time/60)
  local minutes = math.floor(time % 60)
  return string.format("%02d:%02d",hours,minutes)
end--  .................................................................. }}}1

function redditTopMonth()--  ............................................ {{{1
    hs.eventtap.keyStroke({"cmd"}, "c")
    local selection = hs.pasteboard.getContents()
    local subReddit = string.match(selection, '/r/(.-)/')
    hs.alert.show(subReddit)
    hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=month')
end--  .................................................................. }}}1

function redditTopYear()--  ............................................. {{{1
    hs.eventtap.keyStroke({"cmd"}, "c")
    local selection = hs.pasteboard.getContents()
    local subReddit = string.match(selection, '/r/(.-)/')
    hs.alert.show(subReddit)
    hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=year')
end--  .................................................................. }}}1

function inserirNotasDez()--  ........................................... {{{1
    local _, numero = hs.dialog.textPrompt('Quantas notas?', 'Quantas notas 10 devem ser inseridas?')
    hs.timer.usleep(5000000)
    for _ = tonumber(numero),0,-1 do
            hs.eventtap.keyStrokes("10")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
    end
    hs.alert.show("Notas inseridas! 🥳")
end--  .................................................................. }}}1

function inserirNotasCopiadas()--  ...................................... {{{1
    local copiado = hs.pasteboard.getContents()
    local notas = {}
    for s in copiado:gmatch("([^\n]*)\n?") do
        -- hs.alert.show(s)
        table.insert(notas, s)
    end
    for _, nota in ipairs(notas) do
        if string.match(nota, "%d") == nil or nota == '' or tonumber(nota) == 0 then
            -- hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "space")
            hs.eventtap.keyStroke({}, "tab")
        -- elseif nota == 0 then
        --     hs.eventtap.keyStrokes(nota)
        --     hs.eventtap.keyStroke({}, "tab")
        --     hs.eventtap.keyStroke({}, "tab")
        --     hs.eventtap.keyStroke({}, "tab")
        else
            hs.eventtap.keyStrokes(nota)
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
        end
    end
    hs.alert.show("Notas inseridas! 🥳")
end--  .................................................................. }}}1

function abrirChamado()--  .............................................. {{{1
    hs.eventtap.keyStrokes("111137")
    hs.eventtap.keyStroke({}, "tab")
    hs.eventtap.keyStrokes("Daniel Ballester Marques")
    hs.eventtap.keyStroke({}, "tab")
    hs.eventtap.keyStrokes("11976680011")
    hs.eventtap.keyStroke({}, "tab")
    hs.eventtap.keyStrokes("Múltiplos Vínculos")
    hs.eventtap.keyStroke({}, "tab")
    hs.eventtap.keyStrokes("Tenho outro vínculo cujo recolhimento " ..
        "do INSS já atinge o teto, e portanto não deve ser descontado " ..
        "pela FMU. Aqui vai o demonstrativo do último mês. (Estou " ..
        "fazendo o envio mensalmente conforme " ..
        "instruído em um chamado anterior.)")
end--  .................................................................. }}}1


require "keylock"

local items = {
    { title = "RedditP - top of the month", fn = redditTopMonth },
    { title = "RedditP - top of the year", fn = redditTopYear },
    { title = "Lock Keyboard for Cleaning", fn = lockKeyboard },
    -- { title = "Abrir chamado", fn = abrirChamado },
    -- { title = "Inserir notas 10", fn = inserirNotasDez },
    -- { title = "Inserir notas copiadas", fn = inserirNotasCopiadas },
}

snippetMenu:setMenu(items)

snippetMenu:setTitle("★")

