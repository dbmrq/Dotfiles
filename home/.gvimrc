set background=light

if has('gui_macvim')
    set macmeta

    let resolution = system("osascript -e 'tell application \"Finder\" to " .
        \ "get bounds of window of desktop' | cut -d ' ' -f 4")

    if resolution >= 1440
        set guifont=SF\ Mono:h18
    elseif resolution >= 1080
        set guifont=SF\ Mono:h16
    else
        set guifont=SF\ Mono:h14
    end
else
    set guifont=inconsolata\ 14
endif

