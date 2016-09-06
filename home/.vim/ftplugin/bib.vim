command! CheckCommas %s/}\n\([^\n]\)/},\r\1/gc
setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
