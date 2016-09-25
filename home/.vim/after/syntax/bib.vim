syn region bibEntryData contained
  \ start=/[{(]/ms=e+1
  \ end=/[})]/me=e-1
  \ contains=bibKey,bibField,bibComment3
syn match bibComment3 "%.*"
highlight link bibComment3 Comment

