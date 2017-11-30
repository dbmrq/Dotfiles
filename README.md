# dotfiles

These are my personal configuration files. There are many like them, but these
ones are mine. My dotfiles are my best friends. They are my life. I must
master them as I must master my life. Without me, my dotfiles are useless.
Without my dotfiles, I am useless.

They're managed using
[homesick](https://github.com/technicalpickles/homesick).

---

The most interesting stuff here is probably
[my Hammerspoon configuration](https://github.com/dbmrq/dotfiles/tree/master/home/.hammerspoon),
[the .bootstrap scripts](https://github.com/dbmrq/dotfiles/tree/master/home/.bootstrap)
and [my .vimrc](https://github.com/dbmrq/dotfiles/blob/master/home/.vimrc),
which is split into the
[settings.vim](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/settings.vim),
[mappings.vim](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/mappings.vim)
and
[plugins.vim](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/plugins.vim)
files. There's also some cool stuff on
[my ftplugin files](https://github.com/dbmrq/dotfiles/tree/master/home/.vim/ftplugin).

---

Note to self: to bootstrap a new Mac, run something like

    git clone https://github.com/dbmrq/dotfiles.git && cd dotfiles/home/.bootstrap && ./.bootstrap.sh

That'll download and run the `.bootstrap.sh` script, which will take care of
the rest.

If you're not me, you should probably check out the contents of that file before
doing that. There's a lot of stuff that wouldn't make sense for other people.

