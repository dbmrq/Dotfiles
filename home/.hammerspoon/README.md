# My Hammerspoon config

To use, copy each file into your `.hammerspoon` directory and require it from your
`init.lua` file:

```lua
require "winman"   -- Window management
require "slowq"    -- Avoid accidental Cmd-Q
require "cherry"   -- Tiny Pomodoro timer
require "collage"  -- Clipboard management
require "readline" -- Readline style bindings
```

## [winman.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/winman.lua)

Awesome window management. My goal is being able to do as much as possible
while memorizing as few keyboard shortcuts as possible. `⌃⌥⌘` + `hjkl` allow
me to easily organize windows in halves and thirds. When they overlap, they're
automatically cascaded. It's also easy to chose your own keyboard shortcuts by
editing the source code. To install just copy the `winman.lua` file to your
`.hammerspoon` directory and add `require "winman"` to your `init.lua` file.

Shortcut | Effect
-------- | --------------------------------------------------------
**⌃⌥⌘K** | Grow and shrink windows while keeping them at the top
**⌃⌥⌘J** | Grow and shrink windows while keeping them at the bottom
**⌃⌥⌘H** | Grow and shrink windows while keeping them to the left
**⌃⌥⌘L** | Grow and shrink windows while keeping them to the right
**⌃⌥⌘,** | Cascade all windows
**⌃⌥⌘O** | Show a stripe of the Desktop

<img width="2560" alt="screenshot" src="https://user-images.githubusercontent.com/15813674/38471427-6e946544-3b47-11e8-896e-c48a0060a472.png">

## [cherry.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/cherry.lua)

A tiny Pomodoro timer. Start it with ⌃⌥⌘C or check the source code for
customization options.

## [slowq.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/slowq.lua)

Never quit an app by accident again. Replaces apps like
[CommandQ](https://clickontyler.com/commandq/) and
[SlowQuitApps](https://github.com/dteoh/SlowQuitApps).

## [collage.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/collage.lua)

Minimalistic clipboard management solution. The menu icon only appears when
there are more than two items to show. By default, it uses Command + Shift + C,
so not everything will be added. Check the source code for customization
options.

## [readline.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/readline.lua)

Expands the [readline
keybindings](http://www.gnu.org/software/bash/manual/html_node/Bindable-Readline-Commands.html)
already [available on macOS](https://jblevins.org/log/kbd).

## [vim.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/vim.lua)

Vim keybindings and modes everywhere. Although it works pretty well, I found
this a little too gimmicky and ended up disabling it for myself, so it's not
something I'll be updating constantly.


