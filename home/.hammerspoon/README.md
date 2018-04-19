# My Hammerspoon config

To install, just download (option + click) and open the
[install.command](https://github.com/dbmrq/dotfiles/raw/master/home/.hammerspoon/install.command)
file. Then you can use the keyboard shortcuts below or check your init.lua
file to customize them.

## [winman.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/winman.lua)

Awesome window management. My goal is being able to do as much as possible
while memorizing as few keyboard shortcuts as possible. By default, `⌃⌥⌘` +
the arrow keys will allow you to easily organize windows in halves and thirds
of the screen. Windows are automatically cascaded when they overlap. It's also
easy to chose your own keyboard shortcuts, just check the source code (I
recommend `hjkl` over the arrow keys, but they're less intuitive for a lot of
people).

Shortcut | Effect
-------- | --------------------------------------------------------
**⌃⌥⌘↑** | Grow and shrink windows while keeping them at the top
**⌃⌥⌘↓** | Grow and shrink windows while keeping them at the bottom
**⌃⌥⌘←** | Grow and shrink windows while keeping them to the left
**⌃⌥⌘→** | Grow and shrink windows while keeping them to the right
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
there are more than one item to show. By default, it uses Command + Shift + C,
so not everything will be added. Check the source code for customization
options.

## [mocha.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/mocha.lua)

Prevent computer from sleeping. Start it with ⌃⌥⌘M and click the menu icon to
disable.

## [readline.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/readline.lua)

Expands the [readline
keybindings](http://www.gnu.org/software/bash/manual/html_node/Bindable-Readline-Commands.html)
already [available on macOS](https://jblevins.org/log/kbd).

## [vim.lua](https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/vim.lua)

Vim keybindings and modes everywhere. Although it works pretty well, I found
this a little too gimmicky and ended up disabling it for myself, so it's not
something I'll be updating constantly.


