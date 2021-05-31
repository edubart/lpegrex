local parse_c11 = require 'parsers.c11'
local asttools = require 'parsers.astutil'

-- Read input file contents
local filename = arg[1]
local file = io.open(filename)
if not file then
  print('failed to open file: '..filename)
  os.exit(false)
end
local source = file:read('*a')
file:close()

-- Parse C11 source
local ast = parse_c11(source, filename)

-- Print AST
print(asttools.ast2string(ast))
