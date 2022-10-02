set background=light

if has('gui_macvim')
    set macmeta

    let resolution = system("osascript -e 'tell application \"Finder\" to " .
        \ "get bounds of window of desktop' | cut -d ' ' -f 4")

    if resolution >= 1080
        set guifont=SF\ Mono:h16
    elseif resolution >= 720
        set guifont=SF\ Mono:h14
    else
        set guifont=SF\ Mono:h12
    end
else
    set guifont=inconsolata\ 12
endif

