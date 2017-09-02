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
[the `.bootstrap.sh` script](https://github.com/dbmrq/dotfiles/blob/master/home/.bootstrap.sh)
and [my `.vimrc`](https://github.com/dbmrq/dotfiles/blob/master/home/.vimrc),
which is split into the
[`settings.vim`](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/settings.vim),
[`mappings.vim`](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/mappings.vim)
and
[`plugins.vim`](https://github.com/dbmrq/dotfiles/blob/master/home/.vim/plugins.vim)
files. There's also some cool stuff on
[my `ftplugin` files](https://github.com/dbmrq/dotfiles/tree/master/home/.vim/ftplugin).

---

Note to self: to bootstrap a new Mac, run

    curl --remote-name https://raw.githubusercontent.com/dbmrq/dotfiles/master/home/.bootstrap.sh && chmod +x .bootstrap.sh && ./.bootstrap.sh

That'll download and run the `.bootstrap.sh` script, which will take care of
the rest.

If you're not me, you should probably check out the contents of that file before
doing that. There's a lot of stuff that wouldn't make sense for other people.


<img src="http://media.creativebloq.futurecdn.net/sites/creativebloq.com/files/images/2014/07/c88056dea9dd2944000badf9e086f745.jpg" width="360">
