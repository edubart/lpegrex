package = "lpegrex"
version = "0.2.0-1"
source = {
  url = "git://github.com/edubart/lpegrex.git",
  tag = "v0.2.0"
}
description = {
  summary = "LPeg Regular Expression eXtended",
  homepage = "https://github.com/edubart/lpegrex",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  'lpeglabel >= 1.6.0',
}
build = {
  type = "builtin",
  modules = {
    ['lpegrex'] = 'lpegrex.lua'
  }
}
