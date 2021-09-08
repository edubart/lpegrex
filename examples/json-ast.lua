local parse_json = require 'parsers.json'
local lpegrex = require 'lpegrex'

-- Read input file contents
local filename = arg[1]
local file = io.open(filename)
if not file then
  print('failed to open file: '..filename)
  os.exit(false)
end
local source = file:read('*a')
file:close()

-- Parse JSON source
local ast = parse_json(source, filename)

-- Print AST
print(lpegrex.prettyast(ast))
