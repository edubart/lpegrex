local lpegrex = require 'lpegrex'

local patt = lpegrex.compile([[
Json          <-- SKIP (Object / Array) (!.)^UnexpectedSyntax
Object        <== `{` (Member (`,` @Member)*)? `}`
Array         <== `[` (Value (`,` @Value)*)? `]`
Member        <== String @`:` @Value
Value         <-- String / Number / Object / Array / Boolean / Null
String        <-- '"' {~ ('\' -> '' @ESCAPE / !'"' .)* ~} '"' SKIP
Number        <-- {[+-]? (%d+ '.'? %d+? / '.' %d+) ([eE] [+-]? %d+)?} -> tonumber SKIP
Boolean       <-- 'false' -> tofalse / 'true' -> totrue
Null          <-- 'null' -> tonil
ESCAPE        <-- [\/"] / ('b' $8 / 't' $9 / 'n' $10 / 'f' $12 / 'r' $13 / 'u' {%x^4} $16) -> tochar
SKIP          <-- %s*
]])

local source = '[{"string":"some\\ntext", "boolean":true, "number":-1.5e+2, "null":null}]'

local ast, errlabel, errpos = patt:match(source)
if not ast then
  local lineno, colno, line = lpegrex.calcline(source, errpos)
  local colhelp = string.rep(' ', colno-1)..'^'
  error('syntax error: '..lineno..':'..colno..': '..errlabel..
        '\n'..line..'\n'..colhelp)
end
-- `ast` should be a table with the JSON
print('JSON parsed with success!')

-- test
local expected_json =
{ tag = "Array", pos = 1, endpos = 73,
  { tag = "Object", pos = 2, endpos = 72,
    { tag = "Member", pos = 3, endpos = 24,
    "string","some\ntext" },
    { tag = "Member", pos = 26, endpos = 40,
    "boolean", true },
    { tag = "Member", pos = 42, endpos = 58,
      "number", -150.0 },
    { tag = "Member", pos = 60, endpos = 71,
      "null", nil }
  }
}
local expect = require 'tests.lester'.expect
expect.equal(ast, expected_json)
